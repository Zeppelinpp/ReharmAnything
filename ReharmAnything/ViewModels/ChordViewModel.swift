import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

// Recent import record
struct RecentImport: Codable, Identifiable, Equatable {
    let id: UUID
    let fileName: String
    let title: String
    let importDate: Date
    let bookmarkData: Data?
    
    init(fileName: String, title: String, bookmarkData: Data? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.title = title
        self.importDate = Date()
        self.bookmarkData = bookmarkData
    }
}

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
    @Published var clickEnabled = false
    
    // Count-in state
    @Published var isCountingIn = false
    @Published var countInBeat: Int = 0
    
    // Import state
    @Published var inputText = ""
    @Published var importError: String?
    @Published var isImporting = false
    @Published var showingFilePicker = false
    @Published var recentImports: [RecentImport] = []
    
    private let recentImportsKey = "recentMusicXMLImports"
    private let maxRecentImports = 10
    
    // Analysis
    @Published var voiceLeadingAnalysis: VoiceLeadingAnalysis?
    
    // Services
    private let parser = IrealParser()
    private let musicXMLParser = MusicXMLParser()
    private let reharmManager = ReharmManager.shared
    private let voicingGenerator = VoicingGenerator()
    private let voiceLeadingOptimizer = VoiceLeadingOptimizer()
    private let soundManager = SoundFontManager.shared
    private var playbackEngine: HumanizedPlaybackEngine?
    
    private var cancellables = Set<AnyCancellable>()
    private var previewStopTask: DispatchWorkItem?
    
    init() {
        playbackEngine = HumanizedPlaybackEngine(soundManager: soundManager)
        setupBindings()
        loadRecentImports()
        
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
        
        playbackEngine?.$isCountingIn
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCountingIn)
        
        playbackEngine?.$countInBeat
            .receive(on: DispatchQueue.main)
            .assign(to: &$countInBeat)
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
    
    func toggleClick() {
        clickEnabled.toggle()
        playbackEngine?.clickEnabled = clickEnabled
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
    
    // Import from MusicXML file
    func importMusicXML(from url: URL) {
        importError = nil
        isImporting = true
        
        // Ensure we can access the file
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Cannot access the selected file."
            isImporting = false
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let parsed = try musicXMLParser.parse(url: url)
            let progression = parsed.toChordProgression()
            setProgression(progression)
            
            // Save bookmark for recent imports
            let bookmarkData = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            addRecentImport(fileName: url.lastPathComponent, title: progression.title, bookmarkData: bookmarkData)
            
            isImporting = false
        } catch {
            importError = "Failed to parse MusicXML: \(error.localizedDescription)"
            isImporting = false
        }
    }
    
    // Import from recent import record
    func importFromRecent(_ recent: RecentImport) {
        guard let bookmarkData = recent.bookmarkData else {
            importError = "Cannot access this file anymore."
            return
        }
        
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            importError = "Cannot resolve file location."
            removeRecentImport(recent)
            return
        }
        
        if isStale {
            removeRecentImport(recent)
            importError = "File location has changed. Please import again."
            return
        }
        
        importMusicXML(from: url)
    }
    
    // MARK: - Recent Imports Management
    
    private func loadRecentImports() {
        guard let data = UserDefaults.standard.data(forKey: recentImportsKey),
              let imports = try? JSONDecoder().decode([RecentImport].self, from: data) else {
            return
        }
        recentImports = imports
    }
    
    private func saveRecentImports() {
        guard let data = try? JSONEncoder().encode(recentImports) else { return }
        UserDefaults.standard.set(data, forKey: recentImportsKey)
    }
    
    private func addRecentImport(fileName: String, title: String, bookmarkData: Data?) {
        let newImport = RecentImport(fileName: fileName, title: title, bookmarkData: bookmarkData)
        
        // Remove duplicate if exists
        recentImports.removeAll { $0.fileName == fileName }
        
        // Add to beginning
        recentImports.insert(newImport, at: 0)
        
        // Keep only maxRecentImports
        if recentImports.count > maxRecentImports {
            recentImports = Array(recentImports.prefix(maxRecentImports))
        }
        
        saveRecentImports()
    }
    
    func removeRecentImport(_ recent: RecentImport) {
        recentImports.removeAll { $0.id == recent.id }
        saveRecentImports()
    }
    
    func clearRecentImports() {
        recentImports.removeAll()
        saveRecentImports()
    }
    
    // Show file picker
    func showMusicXMLPicker() {
        showingFilePicker = true
    }
    
    // Set progression and analyze
    private func setProgression(_ progression: ChordProgression) {
        var prog = progression
        prog = ChordProgression(
            title: prog.title,
            events: prog.events,
            tempo: tempo,
            timeSignature: prog.timeSignature,
            keySignature: prog.keySignature,
            composer: prog.composer,
            style: prog.style,
            sectionMarkers: prog.sectionMarkers,
            repeats: prog.repeats
        )
        
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
        
        let wasPlaying = isPlaying
        if wasPlaying {
            stop()
        }
        
        let strategy = reharmManager.availableStrategies[selectedStrategy]
        let reharmed = reharmManager.applyToAllDominants(progression: original, strategy: strategy)
        
        // Force UI update
        objectWillChange.send()
        
        reharmedProgression = reharmed
        
        // Update reharm targets for the new progression
        reharmTargets = parser.identifyReharmTargets(in: reharmed)
        
        // Regenerate voicings for reharmed progression
        generateVoicings(for: reharmed)
        
        // Resume playback if was playing
        if wasPlaying {
            play()
        }
    }
    
    // Reset to original
    func resetToOriginal() {
        guard let original = originalProgression else { return }
        
        let wasPlaying = isPlaying
        if wasPlaying {
            stop()
        }
        
        reharmedProgression = nil
        
        // Restore reharm targets for original progression
        reharmTargets = parser.identifyReharmTargets(in: original)
        
        generateVoicings(for: original)
        
        // Resume playback if was playing
        if wasPlaying {
            play()
        }
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
            progression = ChordProgression(
                title: progression.title,
                events: progression.events,
                tempo: newTempo,
                timeSignature: progression.timeSignature,
                keySignature: progression.keySignature,
                composer: progression.composer,
                style: progression.style,
                sectionMarkers: progression.sectionMarkers,
                repeats: progression.repeats
            )
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
        
        // Cancel previous preview stop task
        previewStopTask?.cancel()
        
        soundManager.stopAll()
        soundManager.playChord(currentVoicings[index])
        
        // Stop after 2 seconds
        let task = DispatchWorkItem { [weak self] in
            self?.soundManager.stopAll()
        }
        previewStopTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
    }
    
    // Stop preview immediately
    func stopPreview() {
        previewStopTask?.cancel()
        previewStopTask = nil
        soundManager.stopAll()
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
