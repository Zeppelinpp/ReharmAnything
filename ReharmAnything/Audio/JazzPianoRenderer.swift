import Foundation

// MARK: - Gaussian Random Helper

struct GaussianRandom {
    /// Box-Muller transform for normal distribution
    static func next(mean: Double = 0, standardDeviation: Double = 1) -> Double {
        let u1 = Double.random(in: Double.leastNonzeroMagnitude...1)
        let u2 = Double.random(in: 0...1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return z0 * standardDeviation + mean
    }
    
    /// Clamped gaussian - useful for bounded randomization
    static func nextClamped(mean: Double, standardDeviation: Double, min: Double, max: Double) -> Double {
        let value = next(mean: mean, standardDeviation: standardDeviation)
        return Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Renderer Configuration

/// Configuration for jazz piano performance rendering
struct JazzRendererConfig {
    
    // MARK: Timing (Micro-timing)
    
    /// Global timing jitter - gaussian deviation in beats (typ. 0.015-0.03)
    var timingJitter: Double = 0.022
    
    /// Lay-back amount - positive = behind the beat (jazz feel)
    /// Swing typically: 0.01-0.02, Ballad: 0.02-0.03
    var layBackAmount: Double = 0.012
    
    /// Push amount for anticipation notes (negative = ahead)
    var anticipationPush: Double = -0.008
    
    // MARK: Strumming / Rolling
    
    /// Time between notes in a chord (low to high), in beats
    /// Piano: 0.015-0.035, slower for ballads
    var strumSpeed: Double = 0.018
    
    /// Randomness in strum timing
    var strumRandomness: Double = 0.006
    
    /// Whether to always strum or only sometimes
    var strumProbability: Double = 0.85
    
    /// Direction variation: chance of high-to-low strum
    var reverseStrumProbability: Double = 0.15
    
    // MARK: Velocity (Dynamics)
    
    /// Base velocity center (0-127)
    var velocityCenter: Double = 78
    
    /// Gaussian deviation for velocity randomization
    var velocityJitter: Double = 10
    
    /// High notes slightly brighter (per semitone above middle C)
    var pitchVelocityBias: Double = 0.12
    
    /// Ghost note probability (very soft random notes)
    var ghostNoteProbability: Double = 0.03
    
    /// Ghost note velocity multiplier
    var ghostNoteVelocity: Double = 0.28
    
    // MARK: Duration
    
    /// Base legato factor (0.7 = staccato, 1.0 = legato)
    var legatoFactor: Double = 0.88
    
    /// Duration jitter (gaussian deviation)
    var durationJitter: Double = 0.04
    
    // MARK: Articulation
    
    /// Probability of slightly accenting top note (melody)
    var melodyAccentProbability: Double = 0.6
    
    /// Melody accent velocity boost
    var melodyAccentBoost: Double = 8
    
    /// Left hand slightly softer than right
    var leftHandVelocityReduction: Double = 0.92
    
    // MARK: Presets
    
    static let swing = JazzRendererConfig(
        timingJitter: 0.022,
        layBackAmount: 0.012,
        strumSpeed: 0.018,
        strumRandomness: 0.006,
        velocityCenter: 80,
        velocityJitter: 10,
        ghostNoteProbability: 0.04,
        legatoFactor: 0.85
    )
    
    static let bebop = JazzRendererConfig(
        timingJitter: 0.018,
        layBackAmount: 0.008,
        anticipationPush: -0.012,
        strumSpeed: 0.012,
        strumProbability: 0.7,
        velocityCenter: 75,
        velocityJitter: 12,
        ghostNoteProbability: 0.05,
        legatoFactor: 0.78
    )
    
    static let ballad = JazzRendererConfig(
        timingJitter: 0.028,
        layBackAmount: 0.025,
        strumSpeed: 0.038,
        strumRandomness: 0.01,
        strumProbability: 0.95,
        velocityCenter: 65,
        velocityJitter: 15,
        ghostNoteProbability: 0.02,
        legatoFactor: 0.95,
        melodyAccentProbability: 0.8,
        melodyAccentBoost: 12
    )
    
    static let latin = JazzRendererConfig(
        timingJitter: 0.012,
        layBackAmount: 0.005,
        strumSpeed: 0.008,
        strumProbability: 0.5,
        velocityCenter: 82,
        velocityJitter: 8,
        ghostNoteProbability: 0.02,
        legatoFactor: 0.82
    )
    
    static let funk = JazzRendererConfig(
        timingJitter: 0.01,
        layBackAmount: -0.008,  // Slightly ahead (pushing)
        strumSpeed: 0.006,
        strumProbability: 0.4,
        velocityCenter: 88,
        velocityJitter: 10,
        ghostNoteProbability: 0.08,
        legatoFactor: 0.7  // More staccato
    )
    
    static let gospel = JazzRendererConfig(
        timingJitter: 0.03,
        layBackAmount: 0.018,
        strumSpeed: 0.045,
        strumRandomness: 0.015,
        strumProbability: 0.92,
        velocityCenter: 72,
        velocityJitter: 18,
        legatoFactor: 0.92,
        melodyAccentProbability: 0.75,
        melodyAccentBoost: 15
    )
    
    static let robotic = JazzRendererConfig(
        timingJitter: 0,
        layBackAmount: 0,
        anticipationPush: 0,
        strumSpeed: 0,
        strumRandomness: 0,
        strumProbability: 0,
        velocityCenter: 80,
        velocityJitter: 0,
        pitchVelocityBias: 0,
        ghostNoteProbability: 0,
        ghostNoteVelocity: 0.28,
        legatoFactor: 1.0,
        durationJitter: 0,
        melodyAccentProbability: 0,
        leftHandVelocityReduction: 1.0
    )
}

// MARK: - Jazz Piano Renderer

/// Renders rhythm patterns into humanized MIDI events with realistic jazz feel
class JazzPianoRenderer {
    
    var config: JazzRendererConfig
    
    init(config: JazzRendererConfig = .swing) {
        self.config = config
    }
    
    // MARK: - Main Rendering
    
    /// Render a complete chord progression with patterns
    /// Key features:
    /// 1. Anticipation hits (and-of-4) use the NEXT chord's notes
    /// 2. If previous chord has anticipation, skip beat 1 of current chord (tie over)
    func render(
        progression: ChordProgression,
        voicings: [Voicing],
        pattern: RhythmPattern?
    ) -> [NoteEvent] {
        var allEvents: [NoteEvent] = []
        let swungPattern = pattern?.withSwing()
        
        // First pass: determine which chords have anticipation
        let hasAnticipation = detectAnticipationHits(pattern: swungPattern)
        
        for (index, chordEvent) in progression.events.enumerated() {
            guard index < voicings.count else { continue }
            
            let currentVoicing = voicings[index]
            
            // Get next voicing for anticipation (wrap around for loop)
            let nextIndex = (index + 1) % voicings.count
            let nextVoicing = voicings[nextIndex]
            
            // Check if PREVIOUS chord had anticipation -> skip our beat 1
            let prevIndex = index > 0 ? index - 1 : voicings.count - 1
            let previousHadAnticipation = hasAnticipation && index > 0  // First chord doesn't skip (unless looping)
            
            if let pattern = swungPattern {
                let events = renderPatternWithAnticipation(
                    pattern: pattern,
                    currentVoicing: currentVoicing,
                    nextVoicing: nextVoicing,
                    startBeat: chordEvent.startBeat,
                    duration: chordEvent.duration,
                    skipBeatOne: previousHadAnticipation,
                    isLastChord: index == progression.events.count - 1
                )
                allEvents.append(contentsOf: events)
            } else {
                // Sustained chord (no pattern) - also respect anticipation
                if !previousHadAnticipation {
                    let events = renderSustainedChord(
                        voicing: currentVoicing,
                        chordNotes: currentVoicing.notes.sorted(),
                        startBeat: chordEvent.startBeat,
                        duration: chordEvent.duration
                    )
                    allEvents.append(contentsOf: events)
                }
                // If previous had anticipation, the sustained chord is already ringing
            }
        }
        
        return allEvents.sorted { $0.position < $1.position }
    }
    
    /// Check if a pattern contains anticipation hits
    private func detectAnticipationHits(pattern: RhythmPattern?) -> Bool {
        guard let pattern = pattern else { return false }
        return pattern.hits.contains { isAnticipationHit($0) }
    }
    
    /// Render pattern with proper anticipation handling
    /// - Anticipation hits (and-of-4) use NEXT chord's voicing
    /// - If skipBeatOne is true, don't play hits on beat 1 (previous chord's anticipation is still ringing)
    func renderPatternWithAnticipation(
        pattern: RhythmPattern,
        currentVoicing: Voicing,
        nextVoicing: Voicing,
        startBeat: Double,
        duration: Double,
        skipBeatOne: Bool,
        isLastChord: Bool
    ) -> [NoteEvent] {
        var events: [NoteEvent] = []
        let endBeat = startBeat + duration
        
        let currentNotes = currentVoicing.notes.sorted()
        let nextNotes = nextVoicing.notes.sorted()
        
        for hit in pattern.hits {
            let hitPosition = startBeat + hit.position
            
            // Skip if hit is beyond chord duration
            if hitPosition >= endBeat { continue }
            if hit.type == .rest { continue }
            
            // Check if this is an anticipation hit (and-of-4 leading to next bar)
            let isAnticipation = isAnticipationHit(hit)
            
            // Check if this is beat 1 (position 0.0 in pattern)
            let isBeatOne = isBeatOneHit(hit)
            
            // SKIP beat 1 if previous chord had anticipation (the note is already ringing!)
            if skipBeatOne && isBeatOne {
                continue
            }
            
            // KEY LOGIC: Anticipation uses NEXT chord's notes!
            let voicingToUse = isAnticipation ? nextVoicing : currentVoicing
            let notesToUse = isAnticipation ? nextNotes : currentNotes
            
            // Calculate hit duration
            var hitDuration = hit.duration ?? calculateDefaultDuration(hit: hit, pattern: pattern, endBeat: duration)
            
            // For anticipation, duration extends into next chord
            if isAnticipation {
                // Anticipation note rings through next bar's beat 1
                // Duration should be: remaining time in current bar + time until next hit in next bar
                let remainingInBar = duration - hit.position
                let sustainIntoNextBar = findNextNonBeatOneHitPosition(pattern: pattern) ?? 1.5
                hitDuration = remainingInBar + sustainIntoNextBar
            }
            
            let actualDuration = isAnticipation ? hitDuration : min(hitDuration, endBeat - hitPosition)
            
            // Select notes for this hit type
            let notesToPlay = selectNotes(for: hit.type, voicing: voicingToUse, allNotes: notesToUse)
            if notesToPlay.isEmpty { continue }
            
            // Render the hit with humanization
            let hitEvents = renderHit(
                notes: notesToPlay,
                voicing: voicingToUse,
                basePosition: hitPosition,
                baseDuration: actualDuration,
                baseVelocity: hit.velocity,
                isAnticipation: isAnticipation
            )
            events.append(contentsOf: hitEvents)
        }
        
        return events
    }
    
    /// Check if hit is on beat 1 (position 0.0)
    private func isBeatOneHit(_ hit: RhythmHit) -> Bool {
        return hit.position < 0.1  // Beat 1 is at position 0.0
    }
    
    /// Find the position of the next non-beat-one hit (for anticipation duration)
    private func findNextNonBeatOneHitPosition(pattern: RhythmPattern) -> Double? {
        for hit in pattern.hits {
            if hit.position > 0.1 && hit.type != .rest {
                return hit.position
            }
        }
        return nil
    }
    
    /// Render a single pattern application (legacy, without anticipation lookahead)
    func renderPattern(
        pattern: RhythmPattern,
        voicing: Voicing,
        chordNotes: [MIDINote],
        startBeat: Double,
        duration: Double
    ) -> [NoteEvent] {
        return renderPatternWithAnticipation(
            pattern: pattern,
            currentVoicing: voicing,
            nextVoicing: voicing,
            startBeat: startBeat,
            duration: duration,
            skipBeatOne: false,
            isLastChord: true
        )
    }
    
    /// Render a sustained chord (no pattern)
    func renderSustainedChord(
        voicing: Voicing,
        chordNotes: [MIDINote],
        startBeat: Double,
        duration: Double
    ) -> [NoteEvent] {
        return renderHit(
            notes: chordNotes,
            voicing: voicing,
            basePosition: startBeat,
            baseDuration: duration,
            baseVelocity: 1.0,
            isAnticipation: false
        )
    }
    
    // MARK: - Hit Rendering (Core Humanization)
    
    /// Render a single rhythmic hit with full humanization
    private func renderHit(
        notes: [MIDINote],
        voicing: Voicing,
        basePosition: Double,
        baseDuration: Double,
        baseVelocity: Double,
        isAnticipation: Bool
    ) -> [NoteEvent] {
        var events: [NoteEvent] = []
        let sortedNotes = notes.sorted()
        
        // Global timing offset for the entire chord (moves together)
        let chordTimingOffset = GaussianRandom.next(mean: 0, standardDeviation: config.timingJitter)
        
        // Apply lay-back or anticipation push
        let feelOffset = isAnticipation ? config.anticipationPush : config.layBackAmount
        
        // Decide strum direction
        let shouldStrum = Double.random(in: 0...1) < config.strumProbability
        let reverseStrum = Double.random(in: 0...1) < config.reverseStrumProbability
        
        // Base velocity for this hit
        let hitBaseVelocity = config.velocityCenter * baseVelocity
        
        // Identify melody note (highest)
        let melodyNote = sortedNotes.last
        let leftHandNotes = Set(voicing.leftHandNotes)
        
        for (index, note) in sortedNotes.enumerated() {
            // Strum delay calculation
            var strumDelay: Double = 0
            if shouldStrum && sortedNotes.count > 1 {
                let strumIndex = reverseStrum ? (sortedNotes.count - 1 - index) : index
                let baseStrumDelay = Double(strumIndex) * config.strumSpeed
                let strumJitter = GaussianRandom.next(mean: 0, standardDeviation: config.strumRandomness)
                strumDelay = baseStrumDelay + strumJitter
            }
            
            // Final timing
            var notePosition = basePosition + chordTimingOffset + feelOffset + strumDelay
            notePosition = max(0, notePosition)  // Safety
            
            // Velocity calculation
            var noteVelocity = hitBaseVelocity
            
            // Pitch bias (higher notes slightly brighter)
            let pitchOffset = Double(note - 60) * config.pitchVelocityBias
            noteVelocity += pitchOffset
            
            // Left hand reduction
            if leftHandNotes.contains(note) {
                noteVelocity *= config.leftHandVelocityReduction
            }
            
            // Melody accent
            if note == melodyNote && Double.random(in: 0...1) < config.melodyAccentProbability {
                noteVelocity += config.melodyAccentBoost
            }
            
            // Velocity jitter (gaussian)
            noteVelocity += GaussianRandom.next(mean: 0, standardDeviation: config.velocityJitter)
            
            // Ghost note check
            if Double.random(in: 0...1) < config.ghostNoteProbability {
                noteVelocity *= config.ghostNoteVelocity
            }
            
            // Clamp velocity
            noteVelocity = max(15, min(127, noteVelocity))
            
            // Duration with humanization
            let durationJitter = GaussianRandom.next(mean: 0, standardDeviation: config.durationJitter)
            let noteDuration = max(0.1, baseDuration * config.legatoFactor + durationJitter)
            
            events.append(NoteEvent(
                midiNote: note,
                velocity: UInt8(noteVelocity),
                position: notePosition,
                duration: noteDuration,
                channel: 0
            ))
        }
        
        return events
    }
    
    // MARK: - Helper Methods
    
    /// Select notes based on hit type
    private func selectNotes(for type: RhythmHitType, voicing: Voicing, allNotes: [MIDINote]) -> [MIDINote] {
        guard !allNotes.isEmpty else { return [] }
        
        switch type {
        case .fullChord:
            return allNotes
            
        case .bassOnly:
            return [allNotes.first!]
            
        case .topNote:
            return [allNotes.last!]
            
        case .leftHand:
            return voicing.leftHandNotes.isEmpty ? Array(allNotes.prefix(max(1, allNotes.count / 2))) : voicing.leftHandNotes
            
        case .rightHand:
            return voicing.rightHandNotes.isEmpty ? Array(allNotes.suffix(max(1, allNotes.count / 2))) : voicing.rightHandNotes
            
        case .rest:
            return []
        }
    }
    
    /// Calculate default duration for a hit
    private func calculateDefaultDuration(hit: RhythmHit, pattern: RhythmPattern, endBeat: Double) -> Double {
        // Find next hit position
        if let hitIndex = pattern.hits.firstIndex(where: { $0.position == hit.position }) {
            let nextIndex = hitIndex + 1
            if nextIndex < pattern.hits.count {
                return pattern.hits[nextIndex].position - hit.position
            } else {
                // Last hit - extend to end
                return endBeat - hit.position
            }
        }
        return 1.0  // Default
    }
    
    /// Check if this hit is an anticipation (off-beat leading to next bar)
    private func isAnticipationHit(_ hit: RhythmHit) -> Bool {
        let positionInBar = hit.position.truncatingRemainder(dividingBy: 4.0)
        // "and" of 4 (position 3.5 or 3.67 with swing) is anticipation
        return positionInBar >= 3.4 && positionInBar < 4.0
    }
}

// MARK: - Style to Config Mapping

extension MusicStyle {
    var rendererConfig: JazzRendererConfig {
        switch self {
        case .swing:
            return .swing
        case .bossa:
            return .latin
        case .ballad:
            return .ballad
        case .latin:
            return .latin
        case .funk:
            return .funk
        case .gospel:
            return .gospel
        case .stride:
            return JazzRendererConfig(
                timingJitter: 0.015,
                layBackAmount: 0.008,
                strumSpeed: 0.025,
                strumProbability: 0.3,
                velocityCenter: 85,
                velocityJitter: 10,
                legatoFactor: 0.75
            )
        }
    }
}

// MARK: - Dynamic Comping Selector

/// Intelligent pattern selection based on musical context
class DynamicCompingSelector {
    
    private let library = RhythmPatternLibrary.shared
    
    /// Select a pattern based on intensity and style
    func selectPattern(
        for style: MusicStyle,
        intensity: Double,  // 0.0 (quiet) to 1.0 (climax)
        previousPattern: RhythmPattern? = nil
    ) -> RhythmPattern? {
        let patterns = library.getPatterns(for: style)
        guard !patterns.isEmpty else { return nil }
        
        // Filter patterns based on intensity
        let suitable: [RhythmPattern]
        
        if intensity < 0.3 {
            // Low intensity: prefer sparse patterns or sustained
            suitable = patterns.filter { $0.hits.count <= 3 }
        } else if intensity < 0.6 {
            // Medium: balanced patterns
            suitable = patterns.filter { $0.hits.count >= 2 && $0.hits.count <= 5 }
        } else {
            // High intensity: more active patterns
            suitable = patterns.filter { $0.hits.count >= 3 }
        }
        
        // Avoid repeating same pattern
        let candidates = suitable.isEmpty ? patterns : suitable
        let filtered = candidates.filter { $0.id != previousPattern?.id }
        
        return filtered.randomElement() ?? candidates.randomElement()
    }
    
    /// Weighted random selection favoring certain patterns
    func selectWeightedPattern(
        for style: MusicStyle,
        weights: [String: Double]  // Pattern name -> weight
    ) -> RhythmPattern? {
        let patterns = library.getPatterns(for: style)
        
        var weightedPatterns: [(RhythmPattern, Double)] = patterns.map { pattern in
            let weight = weights[pattern.name] ?? 1.0
            return (pattern, weight)
        }
        
        let totalWeight = weightedPatterns.reduce(0) { $0 + $1.1 }
        var random = Double.random(in: 0..<totalWeight)
        
        for (pattern, weight) in weightedPatterns {
            random -= weight
            if random <= 0 {
                return pattern
            }
        }
        
        return patterns.randomElement()
    }
}
