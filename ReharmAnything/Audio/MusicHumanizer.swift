import Foundation

// MARK: - Note Event Structure

/// Represents a single MIDI note event with timing, velocity, and duration
struct NoteEvent {
    var midiNote: MIDINote
    var velocity: UInt8
    var position: Double     // Position in beats (can be negative for early hits)
    var duration: Double     // Duration in beats
    var channel: UInt8
    
    init(midiNote: MIDINote, velocity: UInt8 = 80, position: Double = 0, duration: Double = 1.0, channel: UInt8 = 0) {
        self.midiNote = midiNote
        self.velocity = velocity
        self.position = position
        self.duration = duration
        self.channel = channel
    }
}

/// Represents a complete chord voicing with timing information
struct VoicingEvent {
    var voicing: Voicing
    var startBeat: Double
    var duration: Double
    var noteEvents: [NoteEvent]
    
    init(voicing: Voicing, startBeat: Double, duration: Double) {
        self.voicing = voicing
        self.startBeat = startBeat
        self.duration = duration
        self.noteEvents = voicing.notes.map { note in
            NoteEvent(midiNote: note, velocity: 80, position: startBeat, duration: duration)
        }
    }
}

// MARK: - Humanizer Configuration

/// Configuration for humanization parameters
struct HumanizerConfig {
    // Timing randomization (in beats)
    var timingJitter: Double = 0.02           // Max random timing offset
    var timingBias: Double = 0.0              // Systematic timing shift (-: early, +: late)
    
    // Velocity randomization
    var velocityJitter: Int = 8               // Max random velocity offset
    var velocityBias: Int = 0                 // Systematic velocity shift
    
    // Duration randomization
    var durationJitter: Double = 0.05         // Max random duration offset
    var legato: Double = 0.95                 // Note overlap factor (0.5-1.0)
    
    // Accent patterns (per beat in a bar)
    var accentPattern: [Double] = [1.0, 0.7, 0.85, 0.65]  // 4/4 default
    
    // Hand separation (for more realistic piano)
    var handSeparation: Double = 0.015        // Slight delay between hands
    var rollChords: Bool = false              // Arpeggiate chords slightly
    var rollSpeed: Double = 0.02              // Time between rolled notes
    
    static let natural = HumanizerConfig()
    
    static let tight = HumanizerConfig(
        timingJitter: 0.008,
        velocityJitter: 4,
        durationJitter: 0.02,
        legato: 0.98
    )
    
    static let loose = HumanizerConfig(
        timingJitter: 0.035,
        velocityJitter: 12,
        durationJitter: 0.08,
        legato: 0.9
    )
    
    static let expressive = HumanizerConfig(
        timingJitter: 0.025,
        velocityJitter: 15,
        durationJitter: 0.06,
        legato: 0.92,
        rollChords: true,
        rollSpeed: 0.025
    )
}

// MARK: - Music Humanizer

/// Main humanizer class for adding realistic feel to MIDI notes
class MusicHumanizer {
    
    var config: HumanizerConfig
    
    init(config: HumanizerConfig = .natural) {
        self.config = config
    }
    
    // MARK: - Core Humanization
    
    /// Humanize a single note event
    func humanize(note: NoteEvent, beatInBar: Int = 0) -> NoteEvent {
        var newNote = note
        
        // Apply accent pattern based on beat position
        let accentIndex = beatInBar % config.accentPattern.count
        let accentFactor = config.accentPattern[accentIndex]
        
        // Velocity: base + accent + jitter
        let baseVelocity = Double(note.velocity) * accentFactor
        let velocityOffset = Double(Int.random(in: -config.velocityJitter...config.velocityJitter))
        let adjustedVelocity = baseVelocity + velocityOffset + Double(config.velocityBias)
        newNote.velocity = UInt8(clamped: Int(adjustedVelocity), min: 1, max: 127)
        
        // Timing: jitter + bias
        let timingOffset = Double.random(in: -config.timingJitter...config.timingJitter)
        newNote.position = note.position + timingOffset + config.timingBias
        
        // Duration: jitter + legato
        let durationOffset = Double.random(in: -config.durationJitter...config.durationJitter)
        newNote.duration = max(0.1, note.duration * config.legato + durationOffset)
        
        return newNote
    }
    
    /// Humanize an array of note events
    func humanize(notes: [NoteEvent], startBeat: Double = 0) -> [NoteEvent] {
        return notes.map { note in
            let beatInBar = Int((note.position - startBeat).truncatingRemainder(dividingBy: 4))
            return humanize(note: note, beatInBar: max(0, beatInBar))
        }
    }
    
    /// Humanize a voicing event with optional chord rolling
    func humanize(voicingEvent: VoicingEvent) -> [NoteEvent] {
        var notes = voicingEvent.noteEvents
        
        // Apply chord rolling if enabled
        if config.rollChords {
            notes = rollChord(notes: notes)
        }
        
        // Apply hand separation (left hand slightly before right hand)
        notes = applyHandSeparation(notes: notes, voicing: voicingEvent.voicing)
        
        // Apply core humanization
        let beatInBar = Int(voicingEvent.startBeat.truncatingRemainder(dividingBy: 4))
        return notes.map { humanize(note: $0, beatInBar: beatInBar) }
    }
    
    // MARK: - Chord Rolling (Arpeggiation)
    
    /// Roll chord notes from bottom to top
    private func rollChord(notes: [NoteEvent]) -> [NoteEvent] {
        let sorted = notes.sorted { $0.midiNote < $1.midiNote }
        return sorted.enumerated().map { index, note in
            var newNote = note
            newNote.position += Double(index) * config.rollSpeed
            return newNote
        }
    }
    
    // MARK: - Hand Separation
    
    /// Apply slight timing separation between hands
    private func applyHandSeparation(notes: [NoteEvent], voicing: Voicing) -> [NoteEvent] {
        let leftHandNotes = Set(voicing.leftHandNotes)
        
        return notes.map { note in
            var newNote = note
            if leftHandNotes.contains(note.midiNote) {
                // Left hand slightly earlier
                newNote.position -= config.handSeparation / 2
            } else {
                // Right hand slightly later
                newNote.position += config.handSeparation / 2
            }
            return newNote
        }
    }
    
    // MARK: - Apply to Chord Progression
    
    /// Generate humanized note events from a chord progression and voicings
    /// Uses adaptive pattern selection based on chord density per measure
    func generateNoteEvents(
        from progression: ChordProgression,
        voicings: [Voicing],
        pattern: RhythmPattern? = nil
    ) -> [NoteEvent] {
        var allNotes: [NoteEvent] = []
        let beatsPerMeasure = progression.timeSignature.beatsPerMeasure
        
        // Group events by measure for density analysis
        let measureChordCounts = analyzeMeasureDensity(events: progression.events, beatsPerMeasure: beatsPerMeasure)
        
        for (index, event) in progression.events.enumerated() {
            guard index < voicings.count else { continue }
            
            let voicing = voicings[index]
            let measureNumber = Int(floor(event.startBeat / beatsPerMeasure)) + 1
            let chordsInMeasure = measureChordCounts[measureNumber] ?? 1
            
            // Select pattern based on chord density
            let selectedPattern = selectPatternForDensity(
                chordsInMeasure: chordsInMeasure,
                chordDuration: event.duration,
                beatsPerMeasure: beatsPerMeasure,
                fallbackPattern: pattern
            )
            
            if let pat = selectedPattern {
                let patternNotes = applyRhythmPattern(
                    pattern: pat,
                    to: voicing,
                    startBeat: event.startBeat,
                    duration: event.duration
                )
                allNotes.append(contentsOf: humanize(notes: patternNotes, startBeat: event.startBeat))
            } else {
                // No pattern: play chord at start beat with full duration
                let voicingEvent = VoicingEvent(voicing: voicing, startBeat: event.startBeat, duration: event.duration)
                allNotes.append(contentsOf: humanize(voicingEvent: voicingEvent))
            }
        }
        
        return allNotes
    }
    
    /// Analyze how many chords are in each measure
    private func analyzeMeasureDensity(events: [ChordEvent], beatsPerMeasure: Double) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for event in events {
            let measureNumber = Int(floor(event.startBeat / beatsPerMeasure)) + 1
            counts[measureNumber, default: 0] += 1
        }
        return counts
    }
    
    /// Select appropriate pattern based on chord density
    private func selectPatternForDensity(
        chordsInMeasure: Int,
        chordDuration: Double,
        beatsPerMeasure: Double,
        fallbackPattern: RhythmPattern?
    ) -> RhythmPattern? {
        let library = RhythmPatternLibrary.shared
        
        // 4 chords per measure (one per beat): play on-beat, no pattern needed
        if chordsInMeasure >= 4 || chordDuration <= 1.0 {
            return nil  // Play exactly at chord's startBeat
        }
        
        // 2 chords per measure: use syncopated pattern
        if chordsInMeasure == 2 || abs(chordDuration - 2.0) < 0.1 {
            return library.getPattern(named: "Syncopated")
        }
        
        // 1 chord per measure (whole bar): weighted random selection
        // Whole note (sustained) should be much more common than syncopated
        // Probability: 90% whole note, 10% syncopated
        if chordsInMeasure == 1 || chordDuration >= beatsPerMeasure - 0.1 {
            let random = Double.random(in: 0..<1)
            if random < 0.9 {
                // 90% chance: whole note (sustained through the measure)
                return library.getPattern(named: "Whole Note")
            } else {
                // 10% chance: syncopated pattern for occasional variation
                return library.getPattern(named: "Syncopated") ?? library.getPattern(named: "Whole Note")
            }
        }
        
        return fallbackPattern
    }
    
    // MARK: - Rhythm Pattern Application
    
    /// Apply a rhythm pattern to a voicing with grid-aligned timing
    func applyRhythmPattern(
        pattern: RhythmPattern,
        to voicing: Voicing,
        startBeat: Double,
        duration: Double
    ) -> [NoteEvent] {
        var notes: [NoteEvent] = []
        let endBeat = startBeat + duration
        
        // Align pattern to the grid (absolute timing)
        // This ensures the pattern stays consistent across chord changes
        var currentPatternBase = floor(startBeat / pattern.lengthInBeats) * pattern.lengthInBeats
        
        while currentPatternBase < endBeat {
            for (index, hit) in pattern.hits.enumerated() {
                let hitPosition = currentPatternBase + hit.position
                
                // Only process hits that fall within the chord's duration
                if hitPosition >= startBeat && hitPosition < endBeat {
                    // Calculate duration: use explicit duration if provided,
                    // otherwise calculate distance to next hit
                    let noteDuration: Double
                    if let explicitDuration = hit.duration {
                        noteDuration = min(explicitDuration, endBeat - hitPosition)
                    } else {
                        let nextHitIndex = (index + 1) % pattern.hits.count
                        let nextPos: Double
                        if nextHitIndex == 0 {
                            nextPos = pattern.lengthInBeats + pattern.hits[0].position
                        } else {
                            nextPos = pattern.hits[nextHitIndex].position
                        }
                        noteDuration = min(nextPos - hit.position, endBeat - hitPosition)
                    }
                    
                    if noteDuration > 0 {
                        let hitNotes = generateHitNotes(
                            voicing: voicing,
                            hit: hit,
                            position: hitPosition,
                            duration: noteDuration
                        )
                        notes.append(contentsOf: hitNotes)
                    }
                }
            }
            currentPatternBase += pattern.lengthInBeats
        }
        
        return notes
    }
    
    /// Generate note events for a single rhythm hit
    private func generateHitNotes(
        voicing: Voicing,
        hit: RhythmHit,
        position: Double,
        duration: Double
    ) -> [NoteEvent] {
        let baseVelocity = UInt8(80.0 * hit.velocity)
        
        switch hit.type {
        case .fullChord:
            return voicing.notes.map { note in
                NoteEvent(midiNote: note, velocity: baseVelocity, position: position, duration: duration)
            }
            
        case .bassOnly:
            guard let bassNote = voicing.bassNote else { return [] }
            return [NoteEvent(midiNote: bassNote, velocity: baseVelocity, position: position, duration: duration)]
            
        case .leftHand:
            return voicing.leftHandNotes.map { note in
                NoteEvent(midiNote: note, velocity: baseVelocity, position: position, duration: duration)
            }
            
        case .rightHand:
            return voicing.rightHandNotes.map { note in
                NoteEvent(midiNote: note, velocity: baseVelocity, position: position, duration: duration)
            }
            
        case .topNote:
            guard let topNote = voicing.topNote else { return [] }
            return [NoteEvent(midiNote: topNote, velocity: baseVelocity, position: position, duration: duration)]
            
        case .rest:
            return []
        }
    }
}

// MARK: - Utility Extensions

extension UInt8 {
    init(clamped value: Int, min: Int, max: Int) {
        self = UInt8(Swift.min(Swift.max(value, min), max))
    }
}
