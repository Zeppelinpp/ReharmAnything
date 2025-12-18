import Foundation
import SwiftUI
import Combine

@MainActor
class ChordViewModel: ObservableObject {
    // Progression state
    @Published var originalProgression: ChordProgression?
    @Published var reharmedProgression: ChordProgression?
    @Published var currentVoicings: [Voicing] = []
    @Published var reharmTargets: [Int] = []
    
    // UI state
    @Published var isPlaying = false
    @Published var currentBeat: Double = 0
    @Published var selectedStrategy: Int = 0
    @Published var selectedVoicingType: VoicingType = .rootlessA
    @Published var selectedSoundFont: SoundFontType = .grandPiano
    @Published var tempo: Double = 120
    @Published var isLooping = true
    
    // Humanization state
    @Published var selectedStyle: MusicStyle = .swing
    @Published var selectedPattern: RhythmPattern?
    @Published var humanizationEnabled = true
    @Published var selectedPreset: HumanizationPreset = .natural
    
    // Import state
    @Published var inputText = ""
    @Published var importError: String?
    @Published var isImporting = false
    
    // Analysis
    @Published var voiceLeadingAnalysis: VoiceLeadingAnalysis?
    
    // Services
    private let parser = IrealParser()
    private let reharmManager = ReharmManager.shared
    private let voicingGenerator = VoicingGenerator()
    private let voiceLeadingOptimizer = VoiceLeadingOptimizer()
    private let soundManager = SoundFontManager.shared
    private var playbackEngine: HumanizedPlaybackEngine?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        playbackEngine = HumanizedPlaybackEngine(soundManager: soundManager)
        setupBindings()
        
        // Set default style
        selectedPattern = RhythmPatternLibrary.shared.getPatterns(for: .swing).first
    }
    
    private func setupBindings() {
        playbackEngine?.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
        
        playbackEngine?.$currentBeat
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentBeat)
    }
    
    // MARK: - Humanization Controls
    
    func setMusicStyle(_ style: MusicStyle) {
        selectedStyle = style
        playbackEngine?.setStyle(style)
        selectedPattern = playbackEngine?.availablePatterns.first
    }
    
    func setRhythmPattern(_ pattern: RhythmPattern?) {
        selectedPattern = pattern
        playbackEngine?.setPattern(pattern)
    }
    
    func setHumanizationPreset(_ preset: HumanizationPreset) {
        selectedPreset = preset
        playbackEngine?.applyPreset(preset)
        humanizationEnabled = preset != .robotic
    }
    
    func toggleHumanization() {
        humanizationEnabled.toggle()
        if humanizationEnabled {
            playbackEngine?.applyPreset(selectedPreset)
        } else {
            playbackEngine?.applyPreset(.robotic)
        }
    }
    
    var availablePatterns: [RhythmPattern] {
        RhythmPatternLibrary.shared.getPatterns(for: selectedStyle)
    }
    
    var availableStyles: [MusicStyle] {
        MusicStyle.allCases
    }
    
    var availablePresets: [HumanizationPreset] {
        HumanizationPreset.allCases
    }
    
    // Initialize audio
    func initializeAudio() async {
        await soundManager.initialize()
    }
    
    // Import chord chart
    func importChart() {
        importError = nil
        
        // Try iReal URL first
        if let progression = parser.parseIrealURL(inputText) {
            setProgression(progression)
            return
        }
        
        // Try simple text format
        if let progression = parser.parseSimpleChart(inputText) {
            setProgression(progression)
            return
        }
        
        importError = "Could not parse chord chart. Please check the format."
    }
    
    // Import from iReal HTML
    func importFromHTML(_ html: String) {
        let progressions = parser.parseIrealHTML(html)
        if let first = progressions.first {
            setProgression(first)
        } else {
            importError = "No chord progressions found in HTML."
        }
    }
    
    // Set progression and analyze
    private func setProgression(_ progression: ChordProgression) {
        var prog = progression
        prog = ChordProgression(title: prog.title, events: prog.events, tempo: tempo)
        
        originalProgression = prog
        reharmTargets = parser.identifyReharmTargets(in: prog)
        
        // Generate optimized voicings
        generateVoicings(for: prog)
        
        reharmedProgression = nil
    }
    
    // Generate voicings with voice leading optimization
    private func generateVoicings(for progression: ChordProgression) {
        currentVoicings = voiceLeadingOptimizer.optimizeProgression(
            progression,
            voicingType: selectedVoicingType,
            forLoop: isLooping
        )
        voiceLeadingAnalysis = voiceLeadingOptimizer.analyzeVoiceLeading(currentVoicings, isLoop: isLooping)
        
        // Update playback engine
        playbackEngine?.setProgression(progression, voicings: currentVoicings)
    }
    
    // Apply reharm strategy
    func applyReharm() {
        guard let original = originalProgression else { return }
        guard selectedStrategy < reharmManager.availableStrategies.count else { return }
        
        let strategy = reharmManager.availableStrategies[selectedStrategy]
        let reharmed = reharmManager.applyToAllDominants(progression: original, strategy: strategy)
        
        reharmedProgression = reharmed
        
        // Regenerate voicings for reharmed progression
        generateVoicings(for: reharmed)
    }
    
    // Reset to original
    func resetToOriginal() {
        guard let original = originalProgression else { return }
        reharmedProgression = nil
        generateVoicings(for: original)
    }
    
    // Playback controls
    func play() {
        playbackEngine?.loopEnabled = isLooping
        playbackEngine?.play()
    }
    
    func pause() {
        playbackEngine?.pause()
    }
    
    func stop() {
        playbackEngine?.stop()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // Sound font selection
    func selectSoundFont(_ type: SoundFontType) {
        selectedSoundFont = type
        soundManager.selectSource(type)
    }
    
    // Voicing type change
    func changeVoicingType(_ type: VoicingType) {
        selectedVoicingType = type
        
        if let progression = reharmedProgression ?? originalProgression {
            generateVoicings(for: progression)
        }
    }
    
    // Tempo change
    func updateTempo(_ newTempo: Double) {
        tempo = newTempo
        
        if var progression = reharmedProgression ?? originalProgression {
            progression = ChordProgression(title: progression.title, events: progression.events, tempo: newTempo)
            if reharmedProgression != nil {
                reharmedProgression = progression
            } else {
                originalProgression = progression
            }
            playbackEngine?.setProgression(progression, voicings: currentVoicings)
        }
    }
    
    // Get current progression
    var activeProgression: ChordProgression? {
        reharmedProgression ?? originalProgression
    }
    
    // Get available strategies
    var strategies: [String] {
        reharmManager.availableStrategies.map { $0.name }
    }
    
    // Get available voicing types
    var voicingTypes: [VoicingType] {
        VoicingType.allCases
    }
    
    // Preview single chord
    func previewChord(at index: Int) {
        guard index < currentVoicings.count else { return }
        soundManager.stopAll()
        soundManager.playChord(currentVoicings[index])
        
        // Stop after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.soundManager.stopAll()
        }
    }
    
    // Get voicing details for display
    func voicingDescription(at index: Int) -> String {
        guard index < currentVoicings.count else { return "" }
        let voicing = currentVoicings[index]
        let noteNames = voicing.notes.sorted().map { midiToNoteName($0) }
        return noteNames.joined(separator: " ")
    }
    
    private func midiToNoteName(_ midi: MIDINote) -> String {
        let noteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        let octave = midi / 12 - 1
        let note = noteNames[midi % 12]
        return "\(note)\(octave)"
    }
    
    // Sample progressions for testing
    func loadSampleProgression() {
        // ii-V-I in C major
        let events = [
            ChordEvent(chord: Chord(root: .D, quality: .minor7), startBeat: 0, duration: 4),
            ChordEvent(chord: Chord(root: .G, quality: .dominant7), startBeat: 4, duration: 4),
            ChordEvent(chord: Chord(root: .C, quality: .major7), startBeat: 8, duration: 4),
            ChordEvent(chord: Chord(root: .C, quality: .major7), startBeat: 12, duration: 4)
        ]
        
        let progression = ChordProgression(title: "ii-V-I in C", events: events, tempo: tempo)
        setProgression(progression)
    }
    
    // Load Autumn Leaves changes
    func loadAutumnLeaves() {
        let events = [
            // A section (in G major / E minor)
            ChordEvent(chord: Chord(root: .A, quality: .minor7), startBeat: 0, duration: 4),
            ChordEvent(chord: Chord(root: .D, quality: .dominant7), startBeat: 4, duration: 4),
            ChordEvent(chord: Chord(root: .G, quality: .major7), startBeat: 8, duration: 4),
            ChordEvent(chord: Chord(root: .C, quality: .major7), startBeat: 12, duration: 4),
            ChordEvent(chord: Chord(root: .Gb, quality: .halfDiminished), startBeat: 16, duration: 4),
            ChordEvent(chord: Chord(root: .B, quality: .dominant7), startBeat: 20, duration: 4),
            ChordEvent(chord: Chord(root: .E, quality: .minor7), startBeat: 24, duration: 4),
            ChordEvent(chord: Chord(root: .E, quality: .minor7), startBeat: 28, duration: 4),
        ]
        
        let progression = ChordProgression(title: "Autumn Leaves (A section)", events: events, tempo: tempo)
        setProgression(progression)
    }
    
    // Load All The Things You Are (first 8 bars)
    func loadAllTheThings() {
        let events = [
            ChordEvent(chord: Chord(root: .F, quality: .minor7), startBeat: 0, duration: 4),
            ChordEvent(chord: Chord(root: .Bb, quality: .minor7), startBeat: 4, duration: 4),
            ChordEvent(chord: Chord(root: .Eb, quality: .dominant7), startBeat: 8, duration: 4),
            ChordEvent(chord: Chord(root: .Ab, quality: .major7), startBeat: 12, duration: 4),
            ChordEvent(chord: Chord(root: .Db, quality: .major7), startBeat: 16, duration: 4),
            ChordEvent(chord: Chord(root: .G, quality: .dominant7), startBeat: 20, duration: 4),
            ChordEvent(chord: Chord(root: .C, quality: .major7), startBeat: 24, duration: 4),
            ChordEvent(chord: Chord(root: .C, quality: .major7), startBeat: 28, duration: 4),
        ]
        
        let progression = ChordProgression(title: "All The Things You Are (A)", events: events, tempo: tempo)
        setProgression(progression)
    }
}
