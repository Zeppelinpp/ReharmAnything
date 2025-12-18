import Foundation
import AVFoundation
import AudioToolbox

// Sound types with dedicated SF2 files
enum SoundFontType: String, CaseIterable, Identifiable {
    case grandPiano = "Grand Piano"
    case rhodes = "Rhodes"
    
    var id: String { rawValue }
    
    // General MIDI program numbers
    var program: UInt8 {
        switch self {
        case .grandPiano: return 0  // Acoustic Grand Piano
        case .rhodes: return 4      // Electric Piano 1 (Rhodes)
        }
    }
    
    // SF2 file name for each sound type
    var sf2FileName: String {
        switch self {
        case .grandPiano: return "UprightPianoKW-20220221"
        case .rhodes: return "jRhodes3"
        }
    }
}

// Protocol for extensible sound sources
protocol SoundSource {
    var name: String { get }
    func loadSound() async throws
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8)
    func stopNote(_ note: MIDINote, channel: UInt8)
    func stopAllNotes()
    func setProgram(_ program: UInt8)
}

// Audio engine with dedicated SF2 files for each instrument
class SharedAudioEngine: ObservableObject {
    static let shared = SharedAudioEngine()
    
    private var audioEngine: AVAudioEngine?
    private var sampler: AVAudioUnitSampler?
    private var currentSoundType: SoundFontType = .grandPiano
    private var activeNotes: Set<MIDINote> = []
    private var fadeOutTimers: [MIDINote: Timer] = [:]
    private var loadedSF2: String?
    
    @Published var isLoaded = false
    @Published var loadError: String?
    
    private init() {}
    
    func initialize() {
        guard audioEngine == nil else { return }
        
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        
        guard let engine = audioEngine, let sampler = sampler else { return }
        
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
            loadSoundFont(for: .grandPiano)
            isLoaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }
    
    // Load specific SF2 file for the selected sound type
    private func loadSoundFont(for type: SoundFontType) {
        guard let sampler = sampler else { return }
        
        let sf2Name = type.sf2FileName
        
        // Skip if already loaded
        if loadedSF2 == sf2Name { return }
        
        // Try to find the SF2 file
        if let url = findSoundFontURL(named: sf2Name) {
            do {
                // Load with program 0 (first preset in the SF2)
                try sampler.loadSoundBankInstrument(
                    at: url,
                    program: 0,
                    bankMSB: 0x79,  // Use 0x79 for melodic instruments
                    bankLSB: 0
                )
                loadedSF2 = sf2Name
                print("Loaded SF2: \(sf2Name)")
                return
            } catch {
                print("Failed to load SF2 \(sf2Name): \(error)")
                // Try with different bank settings
                do {
                    try sampler.loadSoundBankInstrument(
                        at: url,
                        program: 0,
                        bankMSB: 0,
                        bankLSB: 0
                    )
                    loadedSF2 = sf2Name
                    print("Loaded SF2 with alt bank: \(sf2Name)")
                    return
                } catch {
                    print("Alt bank also failed: \(error)")
                }
            }
        }
        
        // Fallback: try any available SF2
        if let url = findAnySoundFontURL() {
            do {
                try sampler.loadSoundBankInstrument(
                    at: url,
                    program: type.program,
                    bankMSB: 0,
                    bankLSB: 0
                )
                loadedSF2 = url.lastPathComponent
                print("Loaded fallback SF2: \(url.lastPathComponent)")
            } catch {
                print("Fallback SF2 load failed: \(error)")
            }
        }
    }
    
    // Find SF2 by specific name
    private func findSoundFontURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "sf2") {
            return url
        }
        return nil
    }
    
    // Find any available SF2 file
    private func findAnySoundFontURL() -> URL? {
        // Search in bundle
        let possibleNames = ["UprightPianoKW-20220221", "jRhodes3", "GeneralUser", "FluidR3", "piano", "soundfont"]
        for name in possibleNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "sf2") {
                return url
            }
        }
        
        // Search in documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docsURL = documentsPath {
            let sf2Files = try? FileManager.default.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "sf2" }
            if let firstSF2 = sf2Files?.first {
                return firstSF2
            }
        }
        
        return nil
    }
    
    func setSoundType(_ type: SoundFontType) {
        guard type != currentSoundType else { return }
        currentSoundType = type
        loadSoundFont(for: type)
    }
    
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8) {
        fadeOutTimers[note]?.invalidate()
        fadeOutTimers.removeValue(forKey: note)
        
        sampler?.startNote(UInt8(note), withVelocity: velocity, onChannel: channel)
        activeNotes.insert(note)
    }
    
    // Fade out note to prevent clicks
    func stopNoteWithFade(_ note: MIDINote, channel: UInt8, fadeDuration: TimeInterval = 0.08) {
        guard activeNotes.contains(note) else { return }
        
        // Immediate stop with fade simulation via quick note-off
        sampler?.stopNote(UInt8(note), onChannel: channel)
        activeNotes.remove(note)
    }
    
    func stopNote(_ note: MIDINote, channel: UInt8) {
        stopNoteWithFade(note, channel: channel)
    }
    
    func stopAllNotes() {
        for timer in fadeOutTimers.values {
            timer.invalidate()
        }
        fadeOutTimers.removeAll()
        
        for note in activeNotes {
            sampler?.stopNote(UInt8(note), onChannel: 0)
        }
        activeNotes.removeAll()
    }
    
    func stopAllNotesImmediate() {
        for timer in fadeOutTimers.values {
            timer.invalidate()
        }
        fadeOutTimers.removeAll()
        
        for note in 0...127 {
            sampler?.stopNote(UInt8(note), onChannel: 0)
        }
        activeNotes.removeAll()
    }
    
    deinit {
        audioEngine?.stop()
    }
}

// Sound source using shared audio engine
class SoundFontSource: SoundSource, ObservableObject {
    let name: String
    let soundFontType: SoundFontType
    
    private let sharedEngine = SharedAudioEngine.shared
    
    @Published var isLoaded = false
    @Published var loadError: String?
    
    init(type: SoundFontType) {
        self.name = type.rawValue
        self.soundFontType = type
    }
    
    func loadSound() async throws {
        await MainActor.run {
            sharedEngine.initialize()
            isLoaded = sharedEngine.isLoaded
            loadError = sharedEngine.loadError
        }
    }
    
    func setProgram(_ program: UInt8) {
        // Map program to sound type
        let type: SoundFontType = program == 4 ? .rhodes : .grandPiano
        sharedEngine.setSoundType(type)
    }
    
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8) {
        sharedEngine.playNote(note, velocity: velocity, channel: channel)
    }
    
    func stopNote(_ note: MIDINote, channel: UInt8) {
        sharedEngine.stopNote(note, channel: channel)
    }
    
    func stopAllNotes() {
        sharedEngine.stopAllNotes()
    }
    
    func stopAllNotesImmediate() {
        sharedEngine.stopAllNotesImmediate()
    }
}

// Manager for sound sources with shared engine
class SoundFontManager: ObservableObject {
    static let shared = SoundFontManager()
    
    @Published var currentType: SoundFontType = .grandPiano
    @Published var isInitialized = false
    
    private let sharedEngine = SharedAudioEngine.shared
    private var source: SoundFontSource?
    
    private init() {}
    
    func initialize() async {
        let initialSource = SoundFontSource(type: .grandPiano)
        try? await initialSource.loadSound()
        
        await MainActor.run {
            source = initialSource
            sharedEngine.setSoundType(.grandPiano)
            isInitialized = true
        }
    }
    
    func selectSource(_ type: SoundFontType) {
        currentType = type
        sharedEngine.setSoundType(type)
    }
    
    func playChord(_ voicing: Voicing, velocity: UInt8 = 80) {
        for note in voicing.notes {
            sharedEngine.playNote(note, velocity: velocity, channel: 0)
        }
    }
    
    func stopChord(_ voicing: Voicing) {
        for note in voicing.notes {
            sharedEngine.stopNote(note, channel: 0)
        }
    }
    
    func stopAll() {
        sharedEngine.stopAllNotes()
    }
    
    func stopAllImmediate() {
        sharedEngine.stopAllNotesImmediate()
    }
}

