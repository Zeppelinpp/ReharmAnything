import Foundation
import AVFoundation
import Combine

// Audio playback engine for chord progressions
class ChordPlaybackEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentBeat: Double = 0
    @Published var loopEnabled = true
    
    private var soundManager: SoundFontManager
    private var timer: Timer?
    private var progression: ChordProgression?
    private var voicings: [Voicing] = []
    private var currentEventIndex = 0
    private var lastPlayedEventIndex = -1
    
    private let tickInterval: TimeInterval = 0.05 // 50ms tick
    
    init(soundManager: SoundFontManager = .shared) {
        self.soundManager = soundManager
    }
    
    func setProgression(_ progression: ChordProgression, voicings: [Voicing]) {
        stop()
        self.progression = progression
        self.voicings = voicings
        self.currentBeat = 0
        self.currentEventIndex = 0
        self.lastPlayedEventIndex = -1
    }
    
    func play() {
        guard let progression = progression, !progression.events.isEmpty else { return }
        
        isPlaying = true
        let beatsPerSecond = progression.tempo / 60.0
        
        // Use .common mode so timer continues during scrolling
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
        currentEventIndex = 0
        lastPlayedEventIndex = -1
    }
    
    private func tick(beatsPerSecond: Double) {
        guard let progression = progression else { return }
        
        currentBeat += tickInterval * beatsPerSecond
        
        // Check if we need to loop
        if currentBeat >= progression.totalBeats {
            if loopEnabled {
                currentBeat = 0
                currentEventIndex = 0
                lastPlayedEventIndex = -1
                soundManager.stopAll()
            } else {
                stop()
                return
            }
        }
        
        // Find and play current chord
        for (index, event) in progression.events.enumerated() {
            let eventEnd = event.startBeat + event.duration
            
            if currentBeat >= event.startBeat && currentBeat < eventEnd {
                if index != lastPlayedEventIndex && index < voicings.count {
                    // Stop previous chord with fade, then play new chord after brief delay
                    if lastPlayedEventIndex >= 0 && lastPlayedEventIndex < voicings.count {
                        soundManager.stopChord(voicings[lastPlayedEventIndex])
                    }
                    
                    // Play new chord immediately (fade handles the transition smoothly)
                    soundManager.playChord(voicings[index])
                    lastPlayedEventIndex = index
                }
                break
            }
        }
    }
    
    func seekTo(beat: Double) {
        guard let progression = progression else { return }
        currentBeat = min(max(0, beat), progression.totalBeats)
        lastPlayedEventIndex = -1
        soundManager.stopAll()
    }
    
    deinit {
        stop()
    }
}

// Audio export functionality
class AudioExporter {
    
    static func exportToWAV(
        progression: ChordProgression,
        voicings: [Voicing],
        soundSource: SoundFontSource,
        outputURL: URL
    ) async throws {
        // Create offline audio context for rendering
        let sampleRate: Double = 44100
        let beatsPerSecond = progression.tempo / 60.0
        let totalDuration = progression.totalBeats / beatsPerSecond
        let totalSamples = Int(totalDuration * sampleRate)
        
        // Create audio buffer
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)) else {
            throw AudioExportError.bufferCreationFailed
        }
        
        buffer.frameLength = AVAudioFrameCount(totalSamples)
        
        // For now, create a simple placeholder - real implementation would render MIDI to audio
        // This requires more complex offline rendering setup
        
        // Write to file
        let audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        try audioFile.write(from: buffer)
    }
}

enum AudioExportError: Error {
    case bufferCreationFailed
    case renderingFailed
}

