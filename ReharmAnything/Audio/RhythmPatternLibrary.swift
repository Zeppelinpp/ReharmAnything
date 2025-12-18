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
                rollChords: true,
                rollSpeed: 0.03,
                accentPattern: [1.0, 0.5, 0.7, 0.5]
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
                rollChords: true,
                rollSpeed: 0.04,
                accentPattern: [1.0, 0.6, 0.9, 0.65]
            )
        case .stride:
            return HumanizerConfig(
                timingJitter: 0.018,
                velocityJitter: 8,
                durationJitter: 0.03,
                legato: 0.8,
                handSeparation: 0.02,
                accentPattern: [1.0, 0.5, 0.85, 0.5]
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
        patterns[.swing] = swingPatterns
        patterns[.bossa] = bossaPatterns
        patterns[.ballad] = balladPatterns
        patterns[.latin] = latinPatterns
        patterns[.funk] = funkPatterns
        patterns[.gospel] = gospelPatterns
        patterns[.stride] = stridePatterns
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
    
    // MARK: - Swing Patterns
    // Classic jazz syncopation patterns featuring:
    // - Charleston rhythm (beat 1 + "and" of 2)
    // - Anticipation (beat 4 "and" tied to next bar's beat 1)
    // - Backbeat emphasis (beats 2 & 4)
    // - Off-beat accents ("and" of 2 & 4 - Red Garland style)
    
    private var swingPatterns: [RhythmPattern] {
        [
            // MARK: Charleston Family
            
            // Classic Charleston: beat 1 + "and" of 2
            RhythmPattern(
                name: "Charleston",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 1.0, type: .fullChord, duration: 1.5),   // Beat 1 (accent)
                    RhythmHit(1.5, velocity: 0.75, type: .fullChord, duration: 2.5)   // "and" of 2 (syncopated)
                ],
                swingFactor: 0.33,
                description: "Beat 1 + and-of-2"
            ),
            
            // Reverse Charleston: "and" of 1 + beat 3
            RhythmPattern(
                name: "Reverse Charleston",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.5, velocity: 0.85, type: .fullChord, duration: 2.0),  // "and" of 1
                    RhythmHit(2.5, velocity: 0.9, type: .fullChord, duration: 1.5)    // "and" of 3
                ],
                swingFactor: 0.33,
                description: "and-of-1 + and-of-3"
            ),
            
            // MARK: Anticipation Patterns (Key Syncopation!)
            
            // Beat 4 anticipation: "and" of 4 ties to next beat 1
            // This is THE classic jazz anticipation
            RhythmPattern(
                name: "Anticipation",
                style: .swing,
                lengthInBeats: 8,  // 2-bar pattern
                hits: [
                    RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 1.5),  // Bar 1: Beat 1
                    RhythmHit(1.5, velocity: 0.7, type: .fullChord, duration: 2.0),   // Bar 1: "and" of 2
                    RhythmHit(3.5, velocity: 0.95, type: .fullChord, duration: 1.5),  // Bar 1: "and" of 4 -> anticipates Bar 2
                    RhythmHit(5.5, velocity: 0.75, type: .fullChord, duration: 2.0),  // Bar 2: "and" of 2
                    RhythmHit(7.5, velocity: 0.9, type: .fullChord, duration: 0.5)    // Bar 2: "and" of 4 -> anticipates next
                ],
                swingFactor: 0.33,
                description: "and-of-4 anticipates beat 1"
            ),
            
            // Double anticipation: both "and" of 2 and "and" of 4
            RhythmPattern(
                name: "Double Anticipation",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(1.5, velocity: 0.85, type: .fullChord, duration: 1.5),  // "and" of 2
                    RhythmHit(3.5, velocity: 0.95, type: .fullChord, duration: 0.5)   // "and" of 4 (strong anticipation)
                ],
                swingFactor: 0.33,
                description: "All off-beats, maximum syncopation"
            ),
            
            // MARK: Red Garland Style (and-of-2, and-of-4)
            
            RhythmPattern(
                name: "Red Garland",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.8, type: .fullChord, duration: 1.0),   // Beat 1 (setup)
                    RhythmHit(1.5, velocity: 0.9, type: .fullChord, duration: 1.5),   // "and" of 2 (accent!)
                    RhythmHit(3.5, velocity: 0.85, type: .fullChord, duration: 0.5)   // "and" of 4 (accent!)
                ],
                swingFactor: 0.33,
                description: "Accent and-of-2 and and-of-4"
            ),
            
            // Extended Red Garland with more variations
            RhythmPattern(
                name: "Red Garland Extended",
                style: .swing,
                lengthInBeats: 8,
                hits: [
                    RhythmHit(0.0, velocity: 0.75, type: .fullChord, duration: 1.0),  // Bar 1: Beat 1
                    RhythmHit(1.5, velocity: 0.9, type: .fullChord, duration: 1.5),   // Bar 1: "and" of 2
                    RhythmHit(3.5, velocity: 0.85, type: .fullChord, duration: 1.0),  // Bar 1: "and" of 4
                    RhythmHit(5.5, velocity: 0.9, type: .fullChord, duration: 1.5),   // Bar 2: "and" of 2
                    RhythmHit(7.0, velocity: 0.7, type: .fullChord, duration: 0.5),   // Bar 2: Beat 4
                    RhythmHit(7.5, velocity: 0.8, type: .fullChord, duration: 0.5)    // Bar 2: "and" of 4
                ],
                swingFactor: 0.33,
                description: "2-bar Red Garland groove"
            ),
            
            // MARK: Continuous Off-beats (Maximum Syncopation)
            
            // All upbeats - very syncopated
            RhythmPattern(
                name: "All Upbeats",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.5, velocity: 0.85, type: .fullChord, duration: 0.8),  // "and" of 1
                    RhythmHit(1.5, velocity: 0.9, type: .fullChord, duration: 0.8),   // "and" of 2
                    RhythmHit(2.5, velocity: 0.8, type: .fullChord, duration: 0.8),   // "and" of 3
                    RhythmHit(3.5, velocity: 0.95, type: .fullChord, duration: 0.5)   // "and" of 4
                ],
                swingFactor: 0.33,
                description: "Consecutive upbeats, no downbeats"
            ),
            
            // MARK: Bebop Comping
            
            RhythmPattern(
                name: "Bebop Sparse",
                style: .swing,
                lengthInBeats: 8,
                hits: [
                    RhythmHit(0.5, velocity: 0.8, type: .fullChord, duration: 1.5),   // Bar 1: "and" of 1
                    RhythmHit(2.5, velocity: 0.75, type: .rightHand, duration: 0.8),  // Bar 1: "and" of 3 (light)
                    RhythmHit(3.5, velocity: 0.9, type: .fullChord, duration: 1.0),   // Bar 1: "and" of 4 (anticipation)
                    RhythmHit(5.0, velocity: 0.7, type: .rightHand, duration: 0.8),   // Bar 2: Beat 2 (light)
                    RhythmHit(6.5, velocity: 0.85, type: .fullChord, duration: 1.0),  // Bar 2: "and" of 3
                    RhythmHit(7.5, velocity: 0.8, type: .fullChord, duration: 0.5)    // Bar 2: "and" of 4
                ],
                swingFactor: 0.33,
                description: "Bebop sparse, space for soloist"
            ),
            
            // Wynton Kelly style: beats 1,3 followed by off-beats
            RhythmPattern(
                name: "Wynton Kelly",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 0.8),  // Beat 1
                    RhythmHit(1.5, velocity: 0.75, type: .rightHand, duration: 0.8),  // "and" of 2
                    RhythmHit(2.0, velocity: 0.9, type: .fullChord, duration: 0.8),   // Beat 3
                    RhythmHit(3.5, velocity: 0.8, type: .fullChord, duration: 0.5)    // "and" of 4
                ],
                swingFactor: 0.33,
                description: "Downbeats + upbeat answers"
            ),
            
            // MARK: Big Band / Freddie Green
            
            RhythmPattern(
                name: "Four-to-the-Bar",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 0.9),
                    RhythmHit(1.0, velocity: 0.6, type: .fullChord, duration: 0.9),   // Light
                    RhythmHit(2.0, velocity: 0.8, type: .fullChord, duration: 0.9),
                    RhythmHit(3.0, velocity: 0.65, type: .fullChord, duration: 0.9)   // Light
                ],
                swingFactor: 0.2,
                description: "Freddie Green style, 2&4 lighter"
            ),
            
            // MARK: Rhythmic Displacement Patterns
            
            // Displaced Charleston (starts on "and" of 1)
            RhythmPattern(
                name: "Displaced Charleston",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.5, velocity: 0.9, type: .fullChord, duration: 1.5),   // "and" of 1 (displaced)
                    RhythmHit(2.0, velocity: 0.8, type: .fullChord, duration: 1.5)    // Beat 3
                ],
                swingFactor: 0.33,
                description: "Charleston shifted by half-beat"
            ),
            
            // Push pattern: everything pushed early
            RhythmPattern(
                name: "Push Pattern",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.7, type: .leftHand, duration: 0.3),    // Ghost on 1
                    RhythmHit(0.5, velocity: 0.9, type: .fullChord, duration: 1.3),   // "and" of 1 (main)
                    RhythmHit(2.5, velocity: 0.85, type: .fullChord, duration: 1.0),  // "and" of 3 (main)
                    RhythmHit(3.5, velocity: 0.8, type: .rightHand, duration: 0.5)    // "and" of 4 (lead-in)
                ],
                swingFactor: 0.33,
                description: "Pushed accents, forward momentum"
            ),
            
            // MARK: Two-feel / Half-time
            
            RhythmPattern(
                name: "Two Feel",
                style: .swing,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord, duration: 1.8),   // Beat 1
                    RhythmHit(2.0, velocity: 0.85, type: .fullChord, duration: 1.8)   // Beat 3
                ],
                swingFactor: 0.25,
                description: "Half-time feel, beats 1 & 3"
            ),
            
            // Two-feel with anticipation
            RhythmPattern(
                name: "Two Feel Anticipated",
                style: .swing,
                lengthInBeats: 8,
                hits: [
                    RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 1.8),  // Bar 1: Beat 1
                    RhythmHit(2.0, velocity: 0.8, type: .fullChord, duration: 1.3),   // Bar 1: Beat 3
                    RhythmHit(3.5, velocity: 0.9, type: .fullChord, duration: 0.8),   // Bar 1: "and" of 4 (anticipate!)
                    RhythmHit(6.0, velocity: 0.8, type: .fullChord, duration: 1.5),   // Bar 2: Beat 3
                    RhythmHit(7.5, velocity: 0.85, type: .fullChord, duration: 0.5)   // Bar 2: "and" of 4
                ],
                swingFactor: 0.33,
                description: "Two-feel with anticipations"
            )
        ]
    }
    
    // MARK: - Bossa Nova Patterns
    
    private var bossaPatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Bossa Basic",
                style: .bossa,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .bassOnly),
                    RhythmHit(0.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(1.5, velocity: 0.75, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.85, type: .bassOnly),
                    RhythmHit(2.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.8, type: .rightHand)
                ],
                description: "Classic bossa nova rhythm"
            ),
            
            RhythmPattern(
                name: "Bossa Jobim",
                style: .bossa,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(1.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.8, type: .fullChord),
                    RhythmHit(3.5, velocity: 0.65, type: .rightHand)
                ],
                description: "Jobim-style sustained chords"
            ),
            
            RhythmPattern(
                name: "Bossa Syncopated",
                style: .bossa,
                lengthInBeats: 8,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .bassOnly),
                    RhythmHit(0.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(1.5, velocity: 0.75, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.8, type: .fullChord),
                    RhythmHit(4.0, velocity: 0.85, type: .bassOnly),
                    RhythmHit(4.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(5.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(6.5, velocity: 0.75, type: .rightHand),
                    RhythmHit(7.0, velocity: 0.8, type: .fullChord)
                ],
                description: "Extended bossa pattern with variation"
            )
        ]
    }
    
    // MARK: - Ballad Patterns
    
    private var balladPatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Ballad Whole Note",
                style: .ballad,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.85, type: .fullChord, duration: 4.0)
                ],
                description: "Simple whole note sustained chord"
            ),
            
            RhythmPattern(
                name: "Ballad Half Notes",
                style: .ballad,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord, duration: 2.0),
                    RhythmHit(2.0, velocity: 0.8, type: .fullChord, duration: 2.0)
                ],
                description: "Two half note chords per bar"
            ),
            
            RhythmPattern(
                name: "Ballad Arpeggiated",
                style: .ballad,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.8, type: .bassOnly),
                    RhythmHit(0.5, velocity: 0.6, type: .rightHand),
                    RhythmHit(1.0, velocity: 0.65, type: .topNote),
                    RhythmHit(1.5, velocity: 0.6, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.75, type: .bassOnly),
                    RhythmHit(2.5, velocity: 0.6, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.65, type: .topNote),
                    RhythmHit(3.5, velocity: 0.6, type: .rightHand)
                ],
                description: "Gentle arpeggiated ballad pattern"
            ),
            
            RhythmPattern(
                name: "Ballad Rubato Feel",
                style: .ballad,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .bassOnly),
                    RhythmHit(0.15, velocity: 0.85, type: .rightHand),
                    RhythmHit(2.5, velocity: 0.75, type: .fullChord)
                ],
                description: "Rubato-style with rolled chord feel"
            )
        ]
    }
    
    // MARK: - Latin Patterns
    
    private var latinPatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Latin Montuno",
                style: .latin,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(0.5, velocity: 0.6, type: .rightHand),
                    RhythmHit(1.0, velocity: 0.75, type: .rightHand),
                    RhythmHit(1.5, velocity: 0.7, type: .fullChord),
                    RhythmHit(2.5, velocity: 0.8, type: .fullChord),
                    RhythmHit(3.0, velocity: 0.65, type: .rightHand),
                    RhythmHit(3.5, velocity: 0.7, type: .rightHand)
                ],
                description: "Classic montuno pattern"
            ),
            
            RhythmPattern(
                name: "Latin Tumbao",
                style: .latin,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.5, velocity: 0.85, type: .bassOnly),
                    RhythmHit(1.0, velocity: 0.7, type: .rightHand),
                    RhythmHit(2.5, velocity: 0.9, type: .bassOnly),
                    RhythmHit(3.0, velocity: 0.75, type: .rightHand),
                    RhythmHit(3.5, velocity: 0.65, type: .rightHand)
                ],
                description: "Bass-driven tumbao rhythm"
            ),
            
            RhythmPattern(
                name: "Latin Cha-Cha",
                style: .latin,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(1.0, velocity: 0.7, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.85, type: .fullChord),
                    RhythmHit(2.5, velocity: 0.65, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.7, type: .rightHand),
                    RhythmHit(3.5, velocity: 0.65, type: .rightHand)
                ],
                description: "Cha-cha-cha rhythm"
            )
        ]
    }
    
    // MARK: - Funk Patterns
    
    private var funkPatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Funk Basic",
                style: .funk,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 1.0, type: .fullChord),
                    RhythmHit(0.75, velocity: 0.6, type: .rightHand),
                    RhythmHit(1.5, velocity: 0.7, type: .fullChord),
                    RhythmHit(2.5, velocity: 0.85, type: .fullChord),
                    RhythmHit(3.25, velocity: 0.65, type: .rightHand),
                    RhythmHit(3.75, velocity: 0.7, type: .rightHand)
                ],
                description: "Basic funk comping"
            ),
            
            RhythmPattern(
                name: "Funk 16th Feel",
                style: .funk,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.95, type: .fullChord),
                    RhythmHit(0.25, velocity: 0.5, type: .rightHand),
                    RhythmHit(0.75, velocity: 0.6, type: .rightHand),
                    RhythmHit(1.25, velocity: 0.65, type: .fullChord),
                    RhythmHit(2.0, velocity: 0.85, type: .fullChord),
                    RhythmHit(2.5, velocity: 0.55, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.7, type: .fullChord),
                    RhythmHit(3.5, velocity: 0.6, type: .rightHand),
                    RhythmHit(3.75, velocity: 0.55, type: .rightHand)
                ],
                description: "Busy 16th note funk"
            ),
            
            RhythmPattern(
                name: "Funk Clavinet",
                style: .funk,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(0.5, velocity: 0.4, type: .rightHand),
                    RhythmHit(1.0, velocity: 0.5, type: .rest),  // Ghost/muted
                    RhythmHit(1.5, velocity: 0.7, type: .fullChord),
                    RhythmHit(2.0, velocity: 0.45, type: .rightHand),
                    RhythmHit(2.75, velocity: 0.85, type: .fullChord),
                    RhythmHit(3.5, velocity: 0.6, type: .rightHand)
                ],
                description: "Clavinet-style staccato funk"
            )
        ]
    }
    
    // MARK: - Gospel Patterns
    
    private var gospelPatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Gospel Basic",
                style: .gospel,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 1.0, type: .fullChord),
                    RhythmHit(1.0, velocity: 0.6, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(3.0, velocity: 0.65, type: .rightHand)
                ],
                description: "Simple gospel quarter note feel"
            ),
            
            RhythmPattern(
                name: "Gospel Triplet Feel",
                style: .gospel,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.95, type: .fullChord),
                    RhythmHit(0.67, velocity: 0.6, type: .rightHand),
                    RhythmHit(1.33, velocity: 0.7, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.9, type: .fullChord),
                    RhythmHit(2.67, velocity: 0.65, type: .rightHand),
                    RhythmHit(3.33, velocity: 0.7, type: .rightHand)
                ],
                description: "Triplet-based gospel groove"
            ),
            
            RhythmPattern(
                name: "Gospel Shout",
                style: .gospel,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 1.0, type: .fullChord),
                    RhythmHit(0.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(1.0, velocity: 0.8, type: .fullChord),
                    RhythmHit(1.5, velocity: 0.65, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.95, type: .fullChord),
                    RhythmHit(2.5, velocity: 0.7, type: .rightHand),
                    RhythmHit(3.0, velocity: 0.85, type: .fullChord),
                    RhythmHit(3.5, velocity: 0.75, type: .rightHand)
                ],
                description: "Energetic shout-style gospel"
            )
        ]
    }
    
    // MARK: - Stride Patterns
    
    private var stridePatterns: [RhythmPattern] {
        [
            RhythmPattern(
                name: "Stride Basic",
                style: .stride,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .bassOnly),
                    RhythmHit(1.0, velocity: 0.7, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.85, type: .bassOnly),
                    RhythmHit(3.0, velocity: 0.7, type: .rightHand)
                ],
                description: "Classic stride bass-chord alternation"
            ),
            
            RhythmPattern(
                name: "Stride Walking",
                style: .stride,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.9, type: .bassOnly),
                    RhythmHit(0.5, velocity: 0.5, type: .bassOnly),
                    RhythmHit(1.0, velocity: 0.75, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.85, type: .bassOnly),
                    RhythmHit(2.5, velocity: 0.5, type: .bassOnly),
                    RhythmHit(3.0, velocity: 0.75, type: .rightHand)
                ],
                description: "Stride with walking bass"
            ),
            
            RhythmPattern(
                name: "Stride Ragtime",
                style: .stride,
                lengthInBeats: 4,
                hits: [
                    RhythmHit(0.0, velocity: 0.95, type: .bassOnly),
                    RhythmHit(1.0, velocity: 0.7, type: .leftHand),
                    RhythmHit(1.5, velocity: 0.55, type: .rightHand),
                    RhythmHit(2.0, velocity: 0.85, type: .bassOnly),
                    RhythmHit(3.0, velocity: 0.7, type: .leftHand),
                    RhythmHit(3.5, velocity: 0.6, type: .rightHand)
                ],
                description: "Ragtime-influenced stride"
            )
        ]
    }
}

// MARK: - Pattern Selector Helper

extension RhythmPatternLibrary {
    
    /// Get a random pattern for a given style
    func randomPattern(for style: MusicStyle) -> RhythmPattern? {
        return patterns[style]?.randomElement()
    }
    
    /// Get patterns suitable for a given tempo
    func patterns(for style: MusicStyle, tempo: Double) -> [RhythmPattern] {
        guard let stylePatterns = patterns[style] else { return [] }
        
        // Filter out overly busy patterns for slow tempos
        if tempo < 80 {
            return stylePatterns.filter { $0.hits.count <= 6 }
        }
        // Filter out sparse patterns for fast tempos
        else if tempo > 160 {
            return stylePatterns.filter { $0.hits.count <= 8 }
        }
        
        return stylePatterns
    }
}
