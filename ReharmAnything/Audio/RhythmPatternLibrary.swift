import Foundation

// MARK: - Rhythm Hit Types

/// Types of chord voicing hits in a rhythm pattern
enum RhythmHitType {
    case fullChord   // Play all notes
    case bassOnly    // Play only bass note
    case leftHand    // Play left hand voicing
    case rightHand   // Play right hand voicing
    case topNote     // Play only melody/top note
    case rest        // No sound
}

/// A single hit in a rhythm pattern
struct RhythmHit {
    var position: Double    // Position in beats (0.0 = start of pattern)
    var velocity: Double    // Relative velocity (0.0-1.0)
    var type: RhythmHitType
    var duration: Double?   // Optional explicit duration (otherwise auto-calculated)
    
    init(_ position: Double, velocity: Double = 1.0, type: RhythmHitType = .fullChord, duration: Double? = nil) {
        self.position = position
        self.velocity = velocity
        self.type = type
        self.duration = duration
    }
}

// MARK: - Rhythm Pattern

/// A complete rhythm pattern definition
struct RhythmPattern: Identifiable {
    let id: UUID
    let name: String
    let style: MusicStyle
    let lengthInBeats: Double    // Pattern length (usually 4, 8, or 16 beats)
    let hits: [RhythmHit]
    let swingFactor: Double      // 0.0 = straight, 0.33 = full swing
    let description: String
    
    init(name: String, style: MusicStyle, lengthInBeats: Double = 4, hits: [RhythmHit], swingFactor: Double = 0.0, description: String = "") {
        self.id = UUID()
        self.name = name
        self.style = style
        self.lengthInBeats = lengthInBeats
        self.hits = hits
        self.swingFactor = swingFactor
        self.description = description
    }
    
    /// Apply swing to hit positions
    func withSwing() -> RhythmPattern {
        guard swingFactor > 0 else { return self }
        
        let swungHits = hits.map { hit -> RhythmHit in
            var newHit = hit
            let beatFraction = hit.position.truncatingRemainder(dividingBy: 1.0)
            
            // Swing the off-beats (0.5 position within each beat)
            if abs(beatFraction - 0.5) < 0.1 {
                let beatBase = floor(hit.position)
                let swungPosition = 0.5 + swingFactor  // e.g., 0.5 -> 0.67 for triplet swing
                newHit.position = beatBase + swungPosition
            }
            return newHit
        }
        
        return RhythmPattern(
            name: name,
            style: style,
            lengthInBeats: lengthInBeats,
            hits: swungHits,
            swingFactor: 0,  // Already applied
            description: description
        )
    }
}

// MARK: - Music Styles

enum MusicStyle: String, CaseIterable, Identifiable {
    case swing = "Swing"
    case bossa = "Bossa Nova"
    case ballad = "Ballad"
    case latin = "Latin"
    case funk = "Funk"
    case gospel = "Gospel"
    case stride = "Stride"
    
    var id: String { rawValue }
    
    var defaultTempo: Double {
        switch self {
        case .swing: return 140
        case .bossa: return 130
        case .ballad: return 72
        case .latin: return 120
        case .funk: return 100
        case .gospel: return 80
        case .stride: return 160
        }
    }
    
    var humanizer: HumanizerConfig {
        switch self {
        case .swing:
            // Jazz swing: backbeat emphasis (2 & 4), slight laid-back feel
            return HumanizerConfig(
                timingJitter: 0.025,
                timingBias: 0.008,     // Slightly behind the beat (laid-back)
                velocityJitter: 12,
                durationJitter: 0.04,
                legato: 0.88,
                accentPattern: [0.8, 0.95, 0.75, 1.0]  // Backbeat: 2 & 4 louder
            )
        case .bossa:
            return HumanizerConfig(
                timingJitter: 0.015,
                velocityJitter: 6,
                durationJitter: 0.03,
                legato: 0.95,
                accentPattern: [0.9, 0.7, 0.8, 0.7]
            )
        case .ballad:
            return HumanizerConfig(
                timingJitter: 0.03,
                velocityJitter: 12,
                durationJitter: 0.06,
                legato: 0.98,
                accentPattern: [1.0, 0.5, 0.7, 0.5],
                rollChords: true,
                rollSpeed: 0.03
            )
        case .latin:
            return HumanizerConfig(
                timingJitter: 0.012,
                velocityJitter: 8,
                durationJitter: 0.02,
                legato: 0.88,
                accentPattern: [1.0, 0.7, 0.9, 0.7]
            )
        case .funk:
            return HumanizerConfig(
                timingJitter: 0.01,
                timingBias: -0.01,  // Slightly ahead of beat
                velocityJitter: 10,
                durationJitter: 0.02,
                legato: 0.85,
                accentPattern: [1.0, 0.6, 0.75, 0.8]
            )
        case .gospel:
            return HumanizerConfig(
                timingJitter: 0.035,
                velocityJitter: 15,
                durationJitter: 0.05,
                legato: 0.93,
                accentPattern: [1.0, 0.6, 0.9, 0.65],
                rollChords: true,
                rollSpeed: 0.04
            )
        case .stride:
            return HumanizerConfig(
                timingJitter: 0.018,
                velocityJitter: 8,
                durationJitter: 0.03,
                legato: 0.8,
                accentPattern: [1.0, 0.5, 0.85, 0.5],
                handSeparation: 0.02
            )
        }
    }
}

// MARK: - Rhythm Pattern Library

/// Library of rhythm patterns organized by style
class RhythmPatternLibrary {
    
    static let shared = RhythmPatternLibrary()
    
    private(set) var patterns: [MusicStyle: [RhythmPattern]] = [:]
    
    private init() {
        loadAllPatterns()
    }
    
    private func loadAllPatterns() {
        // Load patterns for each style
        for style in MusicStyle.allCases {
            patterns[style] = [
                wholeNotePattern(for: style),
                syncopatedPattern(for: style),
                quarterNotePattern(for: style),
                halfNotePattern(for: style)
            ]
        }
    }
    
    func getPatterns(for style: MusicStyle) -> [RhythmPattern] {
        return patterns[style] ?? []
    }
    
    func getPattern(named name: String) -> RhythmPattern? {
        for stylePatterns in patterns.values {
            if let pattern = stylePatterns.first(where: { $0.name == name }) {
                return pattern
            }
        }
        return nil
    }
    
    // MARK: - Basic Patterns
    
    /// Basic whole-note pattern: one chord per bar
    private func wholeNotePattern(for style: MusicStyle) -> RhythmPattern {
        RhythmPattern(
            name: "Whole Note",
            style: style,
            lengthInBeats: 4,
            hits: [
                RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 4.0)
            ],
            swingFactor: 0,
            description: "One chord per bar"
        )
    }
    
    // MARK: - Syncopated Pattern (Beat 1 upbeat + Beat 3)
    
    /// Syncopated pattern: 8th note #2 + beat 3
    /// In 4/4: eighth notes at positions 1, 2, 3, 4, 5, 6, 7, 8 (0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5 beats)
    /// Hit #2 (position 0.5): duration = 0.5 beats (one eighth note)
    /// Hit #5 (position 2.0, beat 3): duration = 1.0 beat (one quarter note)
    private func syncopatedPattern(for style: MusicStyle) -> RhythmPattern {
        let swingFactor: Double = (style == .swing || style == .gospel) ? 0.17 : 0.0
        
        return RhythmPattern(
            name: "Syncopated",
            style: style,
            lengthInBeats: 4,
            hits: [
                // 8th note #2 (position 0.5), duration = 0.5 (one eighth note)
                RhythmHit(0.5, velocity: 0.75, type: .fullChord, duration: 0.5),
                // 8th note #5 / beat 3 (position 2.0), duration = 1.0 (one quarter note)
                RhythmHit(2.0, velocity: 0.85, type: .fullChord, duration: 1.0)
            ],
            swingFactor: swingFactor,
            description: "Syncopated: 8th #2 + beat 3"
        )
    }
    
    // MARK: - Quarter Note Pattern (On-beat)
    
    /// Quarter note pattern: play on every beat (for dense chord changes)
    private func quarterNotePattern(for style: MusicStyle) -> RhythmPattern {
        RhythmPattern(
            name: "Quarter Note",
            style: style,
            lengthInBeats: 4,
            hits: [
                RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 1.0),
                RhythmHit(1.0, velocity: 0.70, type: .fullChord, duration: 1.0),
                RhythmHit(2.0, velocity: 0.80, type: .fullChord, duration: 1.0),
                RhythmHit(3.0, velocity: 0.70, type: .fullChord, duration: 1.0)
            ],
            swingFactor: 0,
            description: "On-beat: every quarter note"
        )
    }
    
    // MARK: - Half Note Pattern (2 chords per bar)
    
    /// Half note pattern: play on beats 1 and 3
    private func halfNotePattern(for style: MusicStyle) -> RhythmPattern {
        RhythmPattern(
            name: "Half Note",
            style: style,
            lengthInBeats: 4,
            hits: [
                RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 2.0),
                RhythmHit(2.0, velocity: 0.80, type: .fullChord, duration: 2.0)
            ],
            swingFactor: 0,
            description: "Half notes: beats 1 and 3"
        )
    }
    
}

// MARK: - Pattern Selector Helper

extension RhythmPatternLibrary {
    
    /// Get a random pattern for a given style (returns the basic pattern)
    func randomPattern(for style: MusicStyle) -> RhythmPattern? {
        return patterns[style]?.first
    }
    
    /// Get patterns suitable for a given tempo (simplified - returns all patterns)
    func patterns(for style: MusicStyle, tempo: Double) -> [RhythmPattern] {
        return patterns[style] ?? []
    }
}
