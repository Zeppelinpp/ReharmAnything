import Foundation
import AVFoundation
import Combine
import QuartzCore

/// Enhanced playback engine with humanization and rhythm patterns
class HumanizedPlaybackEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat: Double = 0
    @Published var loopEnabled = true
    @Published var selectedStyle: MusicStyle = .swing
    @Published var selectedPattern: RhythmPattern?
    @Published var humanizationEnabled = true
    @Published var clickEnabled = false
    @Published var isCountingIn = false  // True during count-in phase
    @Published var countInBeat: Int = 0  // Current count-in beat (1, 2, 3, 4...)
    
    private var soundManager: SoundFontManager
    private var displayLink: CADisplayLink?
    private var progression: ChordProgression?
    private var voicings: [Voicing] = []
    
    // Humanization
    private var humanizer: MusicHumanizer
    private var scheduledNotes: [NoteEvent] = []
    private var playedNoteIndices: Set<Int> = []
    
    // Click track
    private var lastClickBeat: Int = -1
    private let clickGenerator = ClickSoundGenerator()
    
    // Count-in
    private var countInBeatsTotal: Int = 0  // Number of count-in beats (usually 4 or time signature beats)
    private var lastCountInBeat: Int = -1
    
    // High-precision timing using absolute time
    private var playbackStartTime: CFAbsoluteTime = 0
    private var playbackStartBeat: Double = 0
    private var cachedBeatsPerSecond: Double = 2.0  // Default 120 BPM
    
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
        
        // Start with count-in if starting from beginning
        if currentBeat == 0 {
            startCountIn(progression: progression)
        } else {
            startPlayback(progression: progression)
        }
    }
    
    private func startCountIn(progression: ChordProgression) {
        isPlaying = true
        isCountingIn = true
        countInBeat = 0
        lastCountInBeat = -1
        
        // Count-in for one full measure based on time signature
        countInBeatsTotal = progression.timeSignature.beats
        
        playedNoteIndices.removeAll()
        lastClickBeat = -1
        
        // Record start time for count-in timing
        playbackStartTime = CFAbsoluteTimeGetCurrent()
        playbackStartBeat = Double(-countInBeatsTotal)  // Negative beats for count-in
        cachedBeatsPerSecond = progression.tempo / 60.0
        
        // Use CADisplayLink for smooth timing
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func startPlayback(progression: ChordProgression) {
        isPlaying = true
        isCountingIn = false
        countInBeat = 0
        playedNoteIndices.removeAll()
        lastClickBeat = -1
        
        // Record start time for absolute timing
        playbackStartTime = CFAbsoluteTimeGetCurrent()
        playbackStartBeat = currentBeat
        cachedBeatsPerSecond = progression.tempo / 60.0
        
        // Use CADisplayLink for smooth, drift-free timing on main thread
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func pause() {
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
        
        // Stop all notes using both managers to ensure cleanup
        soundManager.stopAll()
        SharedAudioEngine.shared.stopAllNotes()
    }
    
    func stop() {
        pause()
        currentBeat = 0
        playedNoteIndices.removeAll()
        lastClickBeat = -1
        isCountingIn = false
        countInBeat = 0
        lastCountInBeat = -1
    }
    
    @objc private func displayLinkTick() {
        tick(beatsPerSecond: cachedBeatsPerSecond)
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
        
        // Use absolute time for drift-free playback
        let elapsed = CFAbsoluteTimeGetCurrent() - playbackStartTime
        let newBeat = playbackStartBeat + elapsed * beatsPerSecond
        
        // Handle count-in phase
        if isCountingIn {
            if newBeat >= 0 {
                // Count-in finished, start actual playback
                isCountingIn = false
                countInBeat = 0
                lastCountInBeat = -1
                playbackStartTime = CFAbsoluteTimeGetCurrent()
                playbackStartBeat = 0
                currentBeat = 0
                return
            }
            
            // Play count-in clicks
            let countInProgress = newBeat + Double(countInBeatsTotal)  // 0 to countInBeatsTotal
            let currentCountBeat = Int(floor(countInProgress)) + 1  // 1, 2, 3, 4...
            
            if currentCountBeat != lastCountInBeat && currentCountBeat > 0 && currentCountBeat <= countInBeatsTotal {
                lastCountInBeat = currentCountBeat
                countInBeat = currentCountBeat
                
                // Play count-in click
                clickGenerator.playClick()
            }
            
            // Don't update currentBeat during count-in (keep it at 0)
            return
        }
        
        // Loop handling
        if newBeat >= progression.totalBeats {
            if loopEnabled {
                // Reset timing reference for new loop (no count-in on loop)
                playbackStartTime = CFAbsoluteTimeGetCurrent()
                playbackStartBeat = 0
                playedNoteIndices.removeAll()
                lastClickBeat = -1
                soundManager.stopAll()
                currentBeat = 0
                return
            } else {
                stop()
                return
            }
        }
        
        // Update current beat
        currentBeat = newBeat
        
        // Play click track
        if clickEnabled {
            playClickIfNeeded(progression: progression, currentBeat: newBeat)
        }
        
        // Play scheduled notes
        playScheduledNotes(currentBeat: newBeat)
    }
    
    // MARK: - Click Track
    
    /// Play click sound based on time signature
    private func playClickIfNeeded(progression: ChordProgression, currentBeat: Double) {
        let currentBeatInt = Int(floor(currentBeat))
        guard currentBeatInt != lastClickBeat else { return }
        
        lastClickBeat = currentBeatInt
        
        let timeSignature = progression.timeSignature
        let beatsPerMeasure = Int(timeSignature.beatsPerMeasure)
        let beatInMeasure = currentBeatInt % beatsPerMeasure
        
        // 4/4: click on beats 2 and 4 (backbeat)
        // 3/4: click on beat 1 only
        let shouldClick: Bool
        if timeSignature.beats == 4 && timeSignature.beatType == 4 {
            shouldClick = (beatInMeasure == 1 || beatInMeasure == 3)  // 0-indexed: beats 2 and 4
        } else if timeSignature.beats == 3 && timeSignature.beatType == 4 {
            shouldClick = (beatInMeasure == 0)  // beat 1
        } else {
            // Default: click on beat 1 for other time signatures
            shouldClick = (beatInMeasure == 0)
        }
        
        if shouldClick {
            clickGenerator.playClick()
        }
    }
    
    private func playScheduledNotes(currentBeat: Double) {
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
        stopExpiredNotes(currentBeat: currentBeat)
    }
    
    private func playNote(_ note: NoteEvent) {
        guard let progression = progression else { return }
        
        // Convert duration from beats to seconds
        let beatsPerSecond = progression.tempo / 60.0
        let durationInSeconds = note.duration / beatsPerSecond
        
        // Play note with explicit duration for proper ADSR release
        SharedAudioEngine.shared.playNote(
            note.midiNote,
            velocity: note.velocity,
            channel: note.channel,
            duration: durationInSeconds
        )
    }
    
    private func stopExpiredNotes(currentBeat: Double) {
        // Notes are now auto-released by the engine based on duration
        // This method kept for compatibility but release is handled by SharedAudioEngine
        for index in playedNoteIndices {
            guard index < scheduledNotes.count else { continue }
            let note = scheduledNotes[index]
            
            // Only force stop if significantly past duration (safety check)
            if currentBeat >= note.position + note.duration + 0.5 {
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

// MARK: - Click Sound Generator

/// Generates click sounds using AVAudioEngine with a short sine wave burst
class ClickSoundGenerator {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var clickBuffer: AVAudioPCMBuffer?
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // Create click buffer (short sine wave burst at ~1000Hz)
        createClickBuffer(format: format)
        
        do {
            try engine.start()
        } catch {
            print("Click generator failed to start: \(error)")
        }
    }
    
    private func createClickBuffer(format: AVAudioFormat) {
        let sampleRate = format.sampleRate
        let duration: Double = 0.015  // 15ms click
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let frequency: Double = 1000  // 1kHz tone
        let amplitude: Float = 0.3
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            // Sine wave with quick attack/decay envelope
            let envelope = Float(sin(Double.pi * t / duration))  // Quick fade in/out
            let sample = amplitude * envelope * Float(sin(2.0 * Double.pi * frequency * t))
            channelData[frame] = sample
        }
        
        clickBuffer = buffer
    }
    
    func playClick() {
        guard let player = playerNode, let buffer = clickBuffer else { return }
        
        // Schedule and play immediately
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
    
    deinit {
        audioEngine?.stop()
    }
}
