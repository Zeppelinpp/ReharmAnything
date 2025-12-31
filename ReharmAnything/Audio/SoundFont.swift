import Foundation
import AVFoundation
import AudioToolbox

// MARK: - ADSR Envelope Configuration

/// ADSR envelope parameters for natural note articulation
struct ADSREnvelope {
    var attack: TimeInterval    // Time to reach peak velocity
    var decay: TimeInterval     // Time from peak to sustain level
    var sustain: Double         // Sustain level (0.0-1.0)
    var release: TimeInterval   // Time to fade out after note off
    
    static let piano = ADSREnvelope(attack: 0.005, decay: 0.1, sustain: 0.7, release: 0.15)
    static let rhodes = ADSREnvelope(attack: 0.01, decay: 0.15, sustain: 0.6, release: 0.2)
    static let staccato = ADSREnvelope(attack: 0.002, decay: 0.05, sustain: 0.3, release: 0.08)
    static let legato = ADSREnvelope(attack: 0.01, decay: 0.2, sustain: 0.85, release: 0.25)
}

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
    
    // Default ADSR for each sound type
    var defaultADSR: ADSREnvelope {
        switch self {
        case .grandPiano: return .piano
        case .rhodes: return .rhodes
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
    private var releaseTimers: [MIDINote: Timer] = [:]
    private var loadedSF2: String?
    
    // Track note "generation" to prevent stale asyncAfter from stopping new notes
    private var noteGeneration: [MIDINote: Int] = [:]
    
    // ADSR envelope settings
    var adsr: ADSREnvelope = .piano
    
    @Published var isLoaded = false
    @Published var loadError: String?
    
    private init() {}
    
    func initialize() {
        guard audioEngine == nil else { return }
        
        // Configure audio session for speaker playback
        configureAudioSession()
        
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
    
    private func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            // Use playback category to enable speaker output
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
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
        adsr = type.defaultADSR
        loadSoundFont(for: type)
    }
    
    /// Play note with ADSR envelope applied
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8) {
        // Cancel any pending release for this note
        releaseTimers[note]?.invalidate()
        releaseTimers.removeValue(forKey: note)
        fadeOutTimers[note]?.invalidate()
        fadeOutTimers.removeValue(forKey: note)
        
        // Increment generation to invalidate any pending asyncAfter releases
        noteGeneration[note, default: 0] += 1
        
        // Apply attack envelope - start slightly softer and ramp up
        let attackVelocity = UInt8(Double(velocity) * 0.85)
        sampler?.startNote(UInt8(note), withVelocity: attackVelocity, onChannel: channel)
        activeNotes.insert(note)
    }
    
    /// Play note with explicit duration (schedules automatic release)
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8, duration: TimeInterval) {
        playNote(note, velocity: velocity, channel: channel)
        
        // Schedule note release after duration
        let releaseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.stopNoteWithRelease(note, channel: channel)
        }
        releaseTimers[note] = releaseTimer
    }
    
    /// Stop note with natural release envelope
    func stopNoteWithRelease(_ note: MIDINote, channel: UInt8) {
        // Cancel any pending scheduled release timer
        releaseTimers[note]?.invalidate()
        releaseTimers.removeValue(forKey: note)
        
        guard activeNotes.contains(note) else {
            // Note was already released or stopAllNotes was called
            return
        }
        
        // Capture current generation to check if note was re-triggered
        let currentGeneration = noteGeneration[note, default: 0]
        
        // The sampler will handle the natural decay of the sound
        let releaseDelay = adsr.release
        
        DispatchQueue.main.asyncAfter(deadline: .now() + releaseDelay) { [weak self] in
            guard let self = self else { return }
            
            // Check if note was re-triggered (generation changed)
            if self.noteGeneration[note, default: 0] == currentGeneration &&
               self.activeNotes.contains(note) {
                self.sampler?.stopNote(UInt8(note), onChannel: channel)
                self.activeNotes.remove(note)
            }
        }
    }
    
    // Fade out note to prevent clicks
    func stopNoteWithFade(_ note: MIDINote, channel: UInt8, fadeDuration: TimeInterval = 0.08) {
        guard activeNotes.contains(note) else { return }
        
        // Use release envelope duration
        let actualFade = max(fadeDuration, adsr.release * 0.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + actualFade) { [weak self] in
            self?.sampler?.stopNote(UInt8(note), onChannel: channel)
            self?.activeNotes.remove(note)
        }
    }
    
    func stopNote(_ note: MIDINote, channel: UInt8) {
        stopNoteWithRelease(note, channel: channel)
    }
    
    func stopAllNotes() {
        // Cancel all timers
        for timer in fadeOutTimers.values { timer.invalidate() }
        fadeOutTimers.removeAll()
        for timer in releaseTimers.values { timer.invalidate() }
        releaseTimers.removeAll()
        
        // Increment ALL generations (not just active notes) to invalidate any pending asyncAfter
        for note in 0...127 {
            noteGeneration[note, default: 0] += 1
        }
        
        // Stop all active notes immediately
        let notesToStop = activeNotes
        activeNotes.removeAll()
        
        for note in notesToStop {
            sampler?.stopNote(UInt8(note), onChannel: 0)
        }
    }
    
    func stopAllNotesImmediate() {
        for timer in fadeOutTimers.values { timer.invalidate() }
        fadeOutTimers.removeAll()
        for timer in releaseTimers.values { timer.invalidate() }
        releaseTimers.removeAll()
        
        // Increment all generations to invalidate pending asyncAfter
        for note in 0...127 {
            noteGeneration[note, default: 0] += 1
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

