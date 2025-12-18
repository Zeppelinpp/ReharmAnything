import Foundation
import AVFoundation
import Combine

/// Enhanced playback engine with humanization and rhythm patterns
class HumanizedPlaybackEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat: Double = 0
    @Published var loopEnabled = true
    @Published var selectedStyle: MusicStyle = .swing
    @Published var selectedPattern: RhythmPattern?
    @Published var humanizationEnabled = true
    
    private var soundManager: SoundFontManager
    private var timer: Timer?
    private var progression: ChordProgression?
    private var voicings: [Voicing] = []
    
    // Humanization
    private var humanizer: MusicHumanizer
    private var scheduledNotes: [NoteEvent] = []
    private var playedNoteIndices: Set<Int> = []
    
    private let tickInterval: TimeInterval = 0.01  // 10ms tick for precision
    
    init(soundManager: SoundFontManager = .shared) {
        self.soundManager = soundManager
        self.humanizer = MusicHumanizer(config: .natural)
    }
    
    // MARK: - Configuration
    
    func setStyle(_ style: MusicStyle) {
        selectedStyle = style
        humanizer.config = style.humanizer
        
        // Auto-select first pattern for style
        selectedPattern = RhythmPatternLibrary.shared.getPatterns(for: style).first
        
        regenerateScheduledNotes()
    }
    
    func setPattern(_ pattern: RhythmPattern?) {
        selectedPattern = pattern
        regenerateScheduledNotes()
    }
    
    func setHumanizationConfig(_ config: HumanizerConfig) {
        humanizer.config = config
        regenerateScheduledNotes()
    }
    
    // MARK: - Playback Control
    
    func setProgression(_ progression: ChordProgression, voicings: [Voicing]) {
        stop()
        self.progression = progression
        self.voicings = voicings
        regenerateScheduledNotes()
    }
    
    func play() {
        guard let progression = progression, !progression.events.isEmpty else { return }
        
        isPlaying = true
        playedNoteIndices.removeAll()
        
        let beatsPerSecond = progression.tempo / 60.0
        
        let newTimer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick(beatsPerSecond: beatsPerSecond)
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        soundManager.stopAll()
    }
    
    func stop() {
        pause()
        currentBeat = 0
        playedNoteIndices.removeAll()
    }
    
    // MARK: - Note Scheduling
    
    private func regenerateScheduledNotes() {
        guard let progression = progression else {
            scheduledNotes = []
            return
        }
        
        if humanizationEnabled {
            scheduledNotes = humanizer.generateNoteEvents(
                from: progression,
                voicings: voicings,
                pattern: selectedPattern?.withSwing()
            )
        } else {
            // Generate un-humanized notes
            scheduledNotes = generatePlainNotes(from: progression, voicings: voicings)
        }
        
        // Sort by position for efficient playback
        scheduledNotes.sort { $0.position < $1.position }
        playedNoteIndices.removeAll()
    }
    
    private func generatePlainNotes(from progression: ChordProgression, voicings: [Voicing]) -> [NoteEvent] {
        var notes: [NoteEvent] = []
        
        for (index, event) in progression.events.enumerated() {
            guard index < voicings.count else { continue }
            let voicing = voicings[index]
            
            for midiNote in voicing.notes {
                notes.append(NoteEvent(
                    midiNote: midiNote,
                    velocity: 80,
                    position: event.startBeat,
                    duration: event.duration
                ))
            }
        }
        
        return notes
    }
    
    // MARK: - Playback Tick
    
    private func tick(beatsPerSecond: Double) {
        guard let progression = progression else { return }
        
        currentBeat += tickInterval * beatsPerSecond
        
        // Loop handling
        if currentBeat >= progression.totalBeats {
            if loopEnabled {
                currentBeat = 0
                playedNoteIndices.removeAll()
                soundManager.stopAll()
            } else {
                stop()
                return
            }
        }
        
        // Play scheduled notes
        playScheduledNotes()
    }
    
    private func playScheduledNotes() {
        for (index, note) in scheduledNotes.enumerated() {
            // Skip already played notes
            guard !playedNoteIndices.contains(index) else { continue }
            
            // Check if note should start
            if note.position <= currentBeat && note.position + note.duration > currentBeat {
                playNote(note)
                playedNoteIndices.insert(index)
            }
            
            // Stop checking future notes (list is sorted)
            if note.position > currentBeat + 0.1 { break }
        }
        
        // Stop notes that have ended
        stopExpiredNotes()
    }
    
    private func playNote(_ note: NoteEvent) {
        SharedAudioEngine.shared.playNote(note.midiNote, velocity: note.velocity, channel: note.channel)
    }
    
    private func stopExpiredNotes() {
        for index in playedNoteIndices {
            guard index < scheduledNotes.count else { continue }
            let note = scheduledNotes[index]
            
            if currentBeat >= note.position + note.duration {
                SharedAudioEngine.shared.stopNote(note.midiNote, channel: note.channel)
            }
        }
    }
    
    func seekTo(beat: Double) {
        guard let progression = progression else { return }
        currentBeat = min(max(0, beat), progression.totalBeats)
        playedNoteIndices.removeAll()
        soundManager.stopAll()
    }
    
    deinit {
        stop()
    }
}

// MARK: - Convenience Extensions

extension HumanizedPlaybackEngine {
    
    /// Get available patterns for current style
    var availablePatterns: [RhythmPattern] {
        RhythmPatternLibrary.shared.getPatterns(for: selectedStyle)
    }
    
    /// Get all available styles
    var availableStyles: [MusicStyle] {
        MusicStyle.allCases
    }
    
    /// Quick preset configurations
    func applyPreset(_ preset: HumanizationPreset) {
        switch preset {
        case .robotic:
            humanizationEnabled = false
            selectedPattern = nil
            
        case .tight:
            humanizationEnabled = true
            humanizer.config = .tight
            
        case .natural:
            humanizationEnabled = true
            humanizer.config = .natural
            
        case .loose:
            humanizationEnabled = true
            humanizer.config = .loose
            
        case .expressive:
            humanizationEnabled = true
            humanizer.config = .expressive
            
        case .styleDefault:
            humanizationEnabled = true
            humanizer.config = selectedStyle.humanizer
        }
        
        regenerateScheduledNotes()
    }
}

enum HumanizationPreset: String, CaseIterable, Identifiable {
    case robotic = "Robotic"
    case tight = "Tight"
    case natural = "Natural"
    case loose = "Loose"
    case expressive = "Expressive"
    case styleDefault = "Style Default"
    
    var id: String { rawValue }
}
