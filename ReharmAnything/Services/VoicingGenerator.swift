import Foundation

// MARK: - Two-Hand Voicing Template

/// Professional piano voicing with separate left and right hand parts
struct TwoHandVoicing {
    let leftHand: [Int]   // Intervals from root for left hand (bass register)
    let rightHand: [Int]  // Intervals from root for right hand (treble register)
    let description: String
    
    var allIntervals: [Int] {
        leftHand + rightHand
    }
}

// MARK: - Professional Voicing Generator

class VoicingGenerator {
    
    // Two-hand voicing dictionary
    private var voicingDictionary: [ChordQuality: [VoicingType: [TwoHandVoicing]]] = [:]
    
    // Register ranges (MIDI notes)
    let leftHandCenter: MIDINote = 48   // C3 - typical left hand position
    let rightHandCenter: MIDINote = 64  // E4 - typical right hand position
    
    init() {
        buildVoicingDictionary()
    }
    
    // MARK: - Build Professional Voicing Dictionary
    
    private func buildVoicingDictionary() {
        buildMajor7Voicings()
        buildMinor7Voicings()
        buildDominant7Voicings()
        buildHalfDiminishedVoicings()
        buildDiminished7Voicings()
        buildOtherVoicings()
    }
    
    private func buildMajor7Voicings() {
        voicingDictionary[.major7] = [
            // Bill Evans Rootless A: LH plays 3-5, RH plays 7-9
            .rootlessA: [
                TwoHandVoicing(
                    leftHand: [0, 11],           // Root + maj7 (shell)
                    rightHand: [4, 7, 14],       // 3-5-9
                    description: "Shell + 3-5-9"
                ),
                TwoHandVoicing(
                    leftHand: [0, 4],            // Root + 3
                    rightHand: [7, 11, 14],      // 5-7-9
                    description: "1-3 + 5-7-9"
                ),
                TwoHandVoicing(
                    leftHand: [-12, 11],         // Root (octave down) + 7
                    rightHand: [4, 7, 14, 21],   // 3-5-9-13
                    description: "Full maj7 voicing"
                ),
            ],
            // Bill Evans Rootless B: 7-9-3-5
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5
                    rightHand: [11, 14, 16],     // 7-9-3
                    description: "1-5 + 7-9-3"
                ),
                TwoHandVoicing(
                    leftHand: [-1, 4],           // maj7 below + 3
                    rightHand: [7, 14, 19],      // 5-9-5
                    description: "7-3 + extensions"
                ),
            ],
            // Quartal (McCoy Tyner style)
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5
                    rightHand: [11, 16, 21],     // 7-3-6 (4ths stack)
                    description: "Quartal maj7"
                ),
                TwoHandVoicing(
                    leftHand: [0, 5],            // Root + 4
                    rightHand: [9, 14, 19],      // 6-9-5 (4ths)
                    description: "Sus4 quartal"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 11],           // Root + 7
                    rightHand: [4, 7],           // 3 + 5
                    description: "Basic shell"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5 (dropped)
                    rightHand: [4, 11, 14],      // 3-7-9
                    description: "Drop 2 with 9"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 4],            // Root + 3 (dropped)
                    rightHand: [7, 11, 14],      // 5-7-9
                    description: "Drop 3 with 9"
                ),
            ],
        ]
        
        // Copy for major9
        voicingDictionary[.major9] = voicingDictionary[.major7]
    }
    
    private func buildMinor7Voicings() {
        voicingDictionary[.minor7] = [
            .rootlessA: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [3, 7, 14],       // b3-5-9
                    description: "Shell + b3-5-9"
                ),
                TwoHandVoicing(
                    leftHand: [0, 3],            // Root + b3
                    rightHand: [7, 10, 14],      // 5-b7-9
                    description: "1-b3 + 5-b7-9"
                ),
                TwoHandVoicing(
                    leftHand: [-12, 10],         // Root down + b7
                    rightHand: [3, 7, 14, 17],   // b3-5-9-11
                    description: "Full min7 voicing"
                ),
            ],
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5
                    rightHand: [10, 14, 15],     // b7-9-b3
                    description: "1-5 + b7-9-b3"
                ),
                TwoHandVoicing(
                    leftHand: [-2, 3],           // b7 below + b3
                    rightHand: [7, 14, 17],      // 5-9-11
                    description: "b7-b3 + extensions"
                ),
            ],
            // So What voicing (McCoy Tyner / Bill Evans)
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 5],            // Root + 4
                    rightHand: [10, 15, 19],     // b7-b3-5 (So What)
                    description: "So What voicing"
                ),
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5
                    rightHand: [10, 15, 20],     // b7-11-b7 quartal
                    description: "Quartal min7"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [3, 7],           // b3 + 5
                    description: "Basic shell"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 7],
                    rightHand: [3, 10, 14],
                    description: "Drop 2 min7"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 3],
                    rightHand: [7, 10, 14],
                    description: "Drop 3 min7"
                ),
            ],
        ]
        
        voicingDictionary[.minor9] = voicingDictionary[.minor7]
    }
    
    private func buildDominant7Voicings() {
        voicingDictionary[.dominant7] = [
            .rootlessA: [
                // Classic: Root-7 in LH, 3-13-9 in RH
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [4, 9, 14],       // 3-13-9
                    description: "Shell + 3-13-9"
                ),
                TwoHandVoicing(
                    leftHand: [0, 4],            // Root + 3
                    rightHand: [10, 14, 21],     // b7-9-13
                    description: "1-3 + b7-9-13"
                ),
                // Altered dominant
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [4, 6, 13],       // 3-#11-b9
                    description: "Altered dom7"
                ),
                // Full rich voicing
                TwoHandVoicing(
                    leftHand: [-12, 10],         // Root down + b7
                    rightHand: [4, 7, 14, 21],   // 3-5-9-13
                    description: "Full dom7"
                ),
            ],
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [0, 7],            // Root + 5
                    rightHand: [10, 14, 16, 21], // b7-9-3-13
                    description: "1-5 + b7-9-3-13"
                ),
                TwoHandVoicing(
                    leftHand: [-2, 4],           // b7 below + 3
                    rightHand: [9, 14, 19],      // 13-9-5
                    description: "b7-3 + 13-9-5"
                ),
            ],
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 5],            // Root + 4 (sus feel)
                    rightHand: [10, 15, 20],     // b7-11-b7 quartal
                    description: "Sus quartal dom"
                ),
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [4, 9, 14],       // 3-13-9
                    description: "Quartal extensions"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [4, 7],           // 3 + 5
                    description: "Basic shell"
                ),
                TwoHandVoicing(
                    leftHand: [0, 4],            // Root + 3
                    rightHand: [7, 10],          // 5 + b7
                    description: "Alternate shell"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 7],
                    rightHand: [4, 10, 14],
                    description: "Drop 2 dom7"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 4],
                    rightHand: [7, 10, 14],
                    description: "Drop 3 dom7"
                ),
            ],
        ]
        
        // Dominant 9, 13
        voicingDictionary[.dominant9] = voicingDictionary[.dominant7]
        voicingDictionary[.dominant13] = voicingDictionary[.dominant7]
        
        // Altered dominant
        voicingDictionary[.altered] = [
            .rootlessA: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [4, 6, 13, 15],   // 3-#11-b9-#9
                    description: "Full altered"
                ),
                TwoHandVoicing(
                    leftHand: [0, 4],            // Root + 3
                    rightHand: [8, 10, 13],      // #5-b7-b9
                    description: "Altered b9#5"
                ),
            ],
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [-2, 4],           // b7 below + 3
                    rightHand: [6, 8, 13],       // #11-#5-b9
                    description: "Altered stack"
                ),
            ],
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 6],            // Root + #11
                    rightHand: [10, 13, 16],     // b7-b9-3
                    description: "Quartal altered"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 10],
                    rightHand: [4, 8],           // 3 + #5
                    description: "Altered shell"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 8],
                    rightHand: [4, 10, 13],
                    description: "Drop 2 altered"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 4],
                    rightHand: [8, 10, 13],
                    description: "Drop 3 altered"
                ),
            ],
        ]
    }
    
    private func buildHalfDiminishedVoicings() {
        voicingDictionary[.halfDiminished] = [
            .rootlessA: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [3, 6, 14],       // b3-b5-9
                    description: "Shell + b3-b5-9"
                ),
                TwoHandVoicing(
                    leftHand: [0, 3],            // Root + b3
                    rightHand: [6, 10, 14],      // b5-b7-9
                    description: "1-b3 + b5-b7-9"
                ),
            ],
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [-2, 3],           // b7 below + b3
                    rightHand: [6, 10, 14],      // b5-b7-9
                    description: "b7-b3 + b5-b7-9"
                ),
            ],
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 6],            // Root + b5
                    rightHand: [10, 15, 18],     // b7-11-b3
                    description: "Quartal half-dim"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 10],           // Root + b7
                    rightHand: [3, 6],           // b3 + b5
                    description: "Basic shell"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 6],
                    rightHand: [3, 10, 14],
                    description: "Drop 2 half-dim"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 3],
                    rightHand: [6, 10, 14],
                    description: "Drop 3 half-dim"
                ),
            ],
        ]
    }
    
    private func buildDiminished7Voicings() {
        voicingDictionary[.diminished7] = [
            .rootlessA: [
                TwoHandVoicing(
                    leftHand: [0, 9],            // Root + bb7
                    rightHand: [3, 6, 12],       // b3-b5-root
                    description: "Symmetric dim"
                ),
            ],
            .rootlessB: [
                TwoHandVoicing(
                    leftHand: [0, 6],            // Root + b5
                    rightHand: [9, 12, 15],      // bb7-root-b3
                    description: "Dim7 stack"
                ),
            ],
            .quartal: [
                TwoHandVoicing(
                    leftHand: [0, 6],            // Tritone
                    rightHand: [9, 15, 21],      // Symmetric
                    description: "Quartal dim"
                ),
            ],
            .shell: [
                TwoHandVoicing(
                    leftHand: [0, 9],            // Root + bb7
                    rightHand: [3, 6],           // b3 + b5
                    description: "Basic dim7"
                ),
            ],
            .drop2: [
                TwoHandVoicing(
                    leftHand: [0, 6],
                    rightHand: [3, 9, 12],
                    description: "Drop 2 dim7"
                ),
            ],
            .drop3: [
                TwoHandVoicing(
                    leftHand: [0, 3],
                    rightHand: [6, 9, 12],
                    description: "Drop 3 dim7"
                ),
            ],
        ]
        
        voicingDictionary[.diminished] = voicingDictionary[.diminished7]
    }
    
    private func buildOtherVoicings() {
        // Major triad
        voicingDictionary[.major] = [
            .rootlessA: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [4, 12], description: "1-5 + 3-1"),
            ],
            .rootlessB: [
                TwoHandVoicing(leftHand: [0, 4], rightHand: [7, 12], description: "1-3 + 5-1"),
            ],
            .quartal: [
                TwoHandVoicing(leftHand: [0, 5], rightHand: [9, 14], description: "Quartal major"),
            ],
            .shell: [
                TwoHandVoicing(leftHand: [0], rightHand: [4, 7], description: "Basic major"),
            ],
            .drop2: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [4, 12], description: "Drop 2 major"),
            ],
            .drop3: [
                TwoHandVoicing(leftHand: [0, 4], rightHand: [7, 12], description: "Drop 3 major"),
            ],
        ]
        
        // Minor triad
        voicingDictionary[.minor] = [
            .rootlessA: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [3, 12], description: "1-5 + b3-1"),
            ],
            .rootlessB: [
                TwoHandVoicing(leftHand: [0, 3], rightHand: [7, 12], description: "1-b3 + 5-1"),
            ],
            .quartal: [
                TwoHandVoicing(leftHand: [0, 5], rightHand: [10, 15], description: "Quartal minor"),
            ],
            .shell: [
                TwoHandVoicing(leftHand: [0], rightHand: [3, 7], description: "Basic minor"),
            ],
            .drop2: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [3, 12], description: "Drop 2 minor"),
            ],
            .drop3: [
                TwoHandVoicing(leftHand: [0, 3], rightHand: [7, 12], description: "Drop 3 minor"),
            ],
        ]
        
        // Sus4
        voicingDictionary[.sus4] = [
            .rootlessA: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [5, 12], description: "Sus4"),
            ],
            .rootlessB: [
                TwoHandVoicing(leftHand: [0, 5], rightHand: [7, 12], description: "Sus4 inv"),
            ],
            .quartal: [
                TwoHandVoicing(leftHand: [0, 5], rightHand: [10, 15], description: "Quartal sus"),
            ],
            .shell: [
                TwoHandVoicing(leftHand: [0], rightHand: [5, 7], description: "Basic sus4"),
            ],
            .drop2: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [5, 12], description: "Drop 2 sus4"),
            ],
            .drop3: [
                TwoHandVoicing(leftHand: [0, 5], rightHand: [7, 12], description: "Drop 3 sus4"),
            ],
        ]
        
        // Sus2
        voicingDictionary[.sus2] = [
            .rootlessA: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [2, 12], description: "Sus2"),
            ],
            .rootlessB: [
                TwoHandVoicing(leftHand: [0, 2], rightHand: [7, 12], description: "Sus2 inv"),
            ],
            .quartal: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [2, 9], description: "Quartal sus2"),
            ],
            .shell: [
                TwoHandVoicing(leftHand: [0], rightHand: [2, 7], description: "Basic sus2"),
            ],
            .drop2: [
                TwoHandVoicing(leftHand: [0, 7], rightHand: [2, 12], description: "Drop 2 sus2"),
            ],
            .drop3: [
                TwoHandVoicing(leftHand: [0, 2], rightHand: [7, 12], description: "Drop 3 sus2"),
            ],
        ]
        
        // Augmented
        voicingDictionary[.augmented] = [
            .rootlessA: [
                TwoHandVoicing(leftHand: [0, 8], rightHand: [4, 12], description: "Aug"),
            ],
            .rootlessB: [
                TwoHandVoicing(leftHand: [0, 4], rightHand: [8, 12], description: "Aug inv"),
            ],
            .quartal: [
                TwoHandVoicing(leftHand: [0, 4], rightHand: [8, 12], description: "Aug"),
            ],
            .shell: [
                TwoHandVoicing(leftHand: [0], rightHand: [4, 8], description: "Basic aug"),
            ],
            .drop2: [
                TwoHandVoicing(leftHand: [0, 8], rightHand: [4, 12], description: "Drop 2 aug"),
            ],
            .drop3: [
                TwoHandVoicing(leftHand: [0, 4], rightHand: [8, 12], description: "Drop 3 aug"),
            ],
        ]
    }
    
    // MARK: - Generate Two-Hand Voicing
    
    func generateVoicing(
        for chord: Chord,
        type: VoicingType,
        targetRegister: MIDINote = 54
    ) -> Voicing {
        let rootPitchClass = chord.root.pitchClass
        
        guard let qualityVoicings = voicingDictionary[chord.quality],
              let templates = qualityVoicings[type],
              let template = templates.first else {
            return createFallbackVoicing(for: chord, targetRegister: targetRegister)
        }
        
        // Calculate left hand base (around C3)
        let leftHandBase = findBestOctave(
            rootPitchClass: rootPitchClass,
            intervals: template.leftHand,
            target: leftHandCenter
        )
        
        // Calculate right hand base (around E4)
        let rightHandBase = findBestOctave(
            rootPitchClass: rootPitchClass,
            intervals: template.rightHand,
            target: rightHandCenter
        )
        
        // Combine both hands
        let leftNotes = template.leftHand.map { leftHandBase + $0 }
        let rightNotes = template.rightHand.map { rightHandBase + $0 }
        let allNotes = leftNotes + rightNotes
        
        return Voicing(
            chord: chord,
            notes: allNotes.sorted(),
            voicingType: type,
            leftHandNotes: leftNotes.sorted(),
            rightHandNotes: rightNotes.sorted()
        )
    }
    
    // MARK: - Generate Diminished Stack Voicing (Polychord)
    
    /// Diminished Stack: Root triad + triad a minor 3rd below root
    /// C7 -> C triad + A triad (C-E-G + A-C#-E)
    /// G7 -> G triad + E triad (G-B-D + E-G#-B)
    func generateDiminishedStackVoicing(
        for dominantChord: Chord,
        useMajorTriads: Bool = true
    ) -> Voicing {
        let root = dominantChord.root.pitchClass
        
        // Lower triad root is minor 3rd BELOW root (-3 semitones)
        // C -> A, G -> E, D -> B, etc.
        let lowerTriadRoot = (root - 3 + 12) % 12
        
        // Calculate base octaves
        let lhBase = 48  // C3 area for left hand
        let rhBase = 60  // C4 area for right hand
        
        let leftHandNotes: [MIDINote]
        let rightHandNotes: [MIDINote]
        
        if useMajorTriads {
            // C major (C-E-G) + A major (A-C#-E)
            // LH: Lower triad (A) in bass register
            // RH: Root triad (C) in treble register
            leftHandNotes = [
                lhBase + lowerTriadRoot,         // A (lower triad root)
                lhBase + lowerTriadRoot + 4,     // C# (3rd of A)
                lhBase + lowerTriadRoot + 7,     // E (5th of A)
            ]
            rightHandNotes = [
                rhBase + root,                   // C (root triad root)
                rhBase + root + 4,               // E (3rd of C)
                rhBase + root + 7,               // G (5th of C)
            ]
        } else {
            // C minor (C-Eb-G) + A minor (A-C-E)
            leftHandNotes = [
                lhBase + lowerTriadRoot,         // A
                lhBase + lowerTriadRoot + 3,     // C (b3 of A)
                lhBase + lowerTriadRoot + 7,     // E (5th of A)
            ]
            rightHandNotes = [
                rhBase + root,                   // C
                rhBase + root + 3,               // Eb (b3 of C)
                rhBase + root + 7,               // G (5th of C)
            ]
        }
        
        return Voicing(
            chord: dominantChord,
            notes: (leftHandNotes + rightHandNotes).sorted(),
            voicingType: .rootlessA,
            leftHandNotes: leftHandNotes.sorted(),
            rightHandNotes: rightHandNotes.sorted()
        )
    }
    
    // MARK: - Generate All Variants
    
    func generateAllVariants(
        for chord: Chord,
        type: VoicingType,
        targetRegister: MIDINote = 54
    ) -> [Voicing] {
        var variants: [Voicing] = []
        
        guard let qualityVoicings = voicingDictionary[chord.quality],
              let templates = qualityVoicings[type] else {
            return [generateVoicing(for: chord, type: type, targetRegister: targetRegister)]
        }
        
        let rootPitchClass = chord.root.pitchClass
        
        for template in templates {
            // Try different octave combinations
            for lhOffset in [-12, 0] {
                for rhOffset in [-12, 0, 12] {
                    let leftHandBase = findBestOctave(
                        rootPitchClass: rootPitchClass,
                        intervals: template.leftHand,
                        target: leftHandCenter
                    ) + lhOffset
                    
                    let rightHandBase = findBestOctave(
                        rootPitchClass: rootPitchClass,
                        intervals: template.rightHand,
                        target: rightHandCenter
                    ) + rhOffset
                    
                    let leftNotes = template.leftHand.map { leftHandBase + $0 }
                    let rightNotes = template.rightHand.map { rightHandBase + $0 }
                    let allNotes = leftNotes + rightNotes
                    
                    // Validate range and cluster count
                    if allNotes.allSatisfy({ $0 >= 36 && $0 <= 96 }) {
                        let voicing = Voicing(
                            chord: chord,
                            notes: allNotes.sorted(),
                            voicingType: type,
                            leftHandNotes: leftNotes.sorted(),
                            rightHandNotes: rightNotes.sorted()
                        )
                        
                        // Filter voicings with too many clusters
                        if countClusterIntervals(allNotes) <= 2 {
                            variants.append(voicing)
                        }
                    }
                }
            }
        }
        
        // Also generate spread voicings (open position) to avoid clusters
        variants.append(contentsOf: generateSpreadVoicings(for: chord, type: type, targetRegister: targetRegister))
        
        // Remove duplicates
        var seen = Set<[MIDINote]>()
        variants = variants.filter { seen.insert($0.notes.sorted()).inserted }
        
        return variants.isEmpty ? [generateVoicing(for: chord, type: type, targetRegister: targetRegister)] : variants
    }
    
    /// Generate open/spread voicings to avoid clusters
    private func generateSpreadVoicings(
        for chord: Chord,
        type: VoicingType,
        targetRegister: MIDINote
    ) -> [Voicing] {
        var spreadVoicings: [Voicing] = []
        let rootPitchClass = chord.root.pitchClass
        let intervals = chord.quality.intervals
        
        // Open voicing: spread notes across wider range with minimum 3rds between adjacent notes
        for baseOctave in 3...4 {
            let baseNote = baseOctave * 12 + rootPitchClass
            var notes: [MIDINote] = []
            var currentOctaveOffset = 0
            
            for (index, interval) in intervals.enumerated() {
                var note = baseNote + interval + currentOctaveOffset
                
                // Ensure minimum spacing of minor 3rd (3 semitones) between adjacent notes
                if let lastNote = notes.last {
                    while note - lastNote < 3 && note < 96 {
                        note += 12
                        currentOctaveOffset += 12
                    }
                }
                
                if note <= 96 && note >= 36 {
                    notes.append(note)
                }
                
                // Alternate octave shifts for spread voicing
                if index % 2 == 0 && currentOctaveOffset < 24 {
                    currentOctaveOffset += 12
                }
            }
            
            if notes.count >= 3 && countClusterIntervals(notes) <= 1 {
                let splitPoint = notes.count / 2
                spreadVoicings.append(Voicing(
                    chord: chord,
                    notes: notes.sorted(),
                    voicingType: type,
                    leftHandNotes: Array(notes.sorted().prefix(splitPoint)),
                    rightHandNotes: Array(notes.sorted().suffix(notes.count - splitPoint))
                ))
            }
        }
        
        return spreadVoicings
    }
    
    /// Count cluster intervals (minor 2nd = 1, major 2nd = 2 semitones)
    private func countClusterIntervals(_ notes: [MIDINote]) -> Int {
        let sorted = notes.sorted()
        var count = 0
        for i in 0..<(sorted.count - 1) {
            if sorted[i + 1] - sorted[i] <= 2 {
                count += 1
            }
        }
        return count
    }
    
    // MARK: - Helper Methods
    
    private func findBestOctave(rootPitchClass: Int, intervals: [Int], target: MIDINote) -> MIDINote {
        var bestBase: MIDINote = 48 + rootPitchClass
        var bestDistance = Int.max
        
        for octave in 2...6 {
            let base = MIDINote(octave * 12 + rootPitchClass)
            let notes = intervals.map { base + $0 }
            
            guard !notes.isEmpty else { continue }
            
            let center = notes.reduce(0, +) / notes.count
            let distance = abs(center - target)
            
            let allInRange = notes.allSatisfy { $0 >= 24 && $0 <= 96 }
            
            if allInRange && distance < bestDistance {
                bestDistance = distance
                bestBase = base
            }
        }
        
        return bestBase
    }
    
    private func createFallbackVoicing(for chord: Chord, targetRegister: MIDINote) -> Voicing {
        let intervals = chord.quality.intervals
        let baseNote = findBestOctave(rootPitchClass: chord.root.pitchClass, intervals: intervals, target: targetRegister)
        let notes = intervals.map { baseNote + $0 }
        return Voicing(chord: chord, notes: notes, voicingType: .shell)
    }
    
    // MARK: - Voicing Transformations
    
    func invertVoicing(_ voicing: Voicing, times: Int = 1) -> Voicing? {
        var notes = voicing.notes.sorted()
        
        for _ in 0..<times {
            guard let lowest = notes.first else { return nil }
            notes.removeFirst()
            let newNote = lowest + 12
            if newNote <= 96 {
                notes.append(newNote)
            } else {
                return nil
            }
        }
        
        return Voicing(chord: voicing.chord, notes: notes.sorted(), voicingType: voicing.voicingType)
    }
    
    func transposeVoicing(_ voicing: Voicing, semitones: Int) -> Voicing? {
        let newNotes = voicing.notes.map { $0 + semitones }
        guard newNotes.allSatisfy({ $0 >= 36 && $0 <= 96 }) else { return nil }
        return Voicing(chord: voicing.chord, notes: newNotes, voicingType: voicing.voicingType)
    }
}

// MARK: - Variant Voicing Generation

extension VoicingGenerator {
    
    /// Generate a variant voicing with added extension notes
    /// Used for the second hit when a measure has one chord with two hits
    /// Constraint: Only modify 1-2 notes to maintain voice leading smoothness
    func generateVariantVoicing(
        baseVoicing: Voicing,
        chord: Chord,
        extensions: [String]? = nil
    ) -> Voicing {
        // Determine which extensions to use
        let extensionsToUse: [String]
        if let explicit = extensions, !explicit.isEmpty {
            extensionsToUse = explicit
        } else if !chord.extensions.isEmpty {
            // Use chord's existing extensions
            extensionsToUse = chord.extensions
        } else {
            // Pick random suggested extension for this chord quality
            let suggestions = chord.quality.suggestedExtensions
            extensionsToUse = suggestions.randomElement() ?? []
        }
        
        guard !extensionsToUse.isEmpty else { return baseVoicing }
        
        // Get extension intervals
        let extensionIntervals = extensionsToUse.compactMap { ChordQuality.extensionInterval($0) }
        guard !extensionIntervals.isEmpty else { return baseVoicing }
        
        var newNotes = baseVoicing.notes
        let rootPitchClass = chord.root.pitchClass
        
        // Strategy: Replace one note (preferring root or 5th) with an extension
        // This keeps voicing size constant and maintains voice leading
        for interval in extensionIntervals.prefix(1) { // Only add one extension
            let extensionPitchClass = (rootPitchClass + interval) % 12
            
            // Check if this extension already exists in voicing
            if newNotes.contains(where: { $0 % 12 == extensionPitchClass }) {
                continue
            }
            
            // Find a note to replace (prefer root or 5th, they're less essential)
            let fifthPitchClass = (rootPitchClass + 7) % 12
            
            // Try to replace 5th first
            if let fifthIndex = newNotes.firstIndex(where: { $0 % 12 == fifthPitchClass }) {
                let oldNote = newNotes[fifthIndex]
                let octave = oldNote / 12
                // Place extension in similar register
                var newNote = octave * 12 + extensionPitchClass
                // Adjust octave if needed to stay close to original note
                if newNote - oldNote > 6 { newNote -= 12 }
                if oldNote - newNote > 6 { newNote += 12 }
                // Ensure in valid range
                if newNote >= 36 && newNote <= 96 {
                    newNotes[fifthIndex] = newNote
                }
            }
            // If no 5th, try to replace root (if there's more than one root/octave)
            else {
                let rootNotes = newNotes.enumerated().filter { $0.element % 12 == rootPitchClass }
                if rootNotes.count > 1, let (index, oldNote) = rootNotes.last {
                    let octave = oldNote / 12
                    var newNote = octave * 12 + extensionPitchClass
                    if newNote - oldNote > 6 { newNote -= 12 }
                    if oldNote - newNote > 6 { newNote += 12 }
                    if newNote >= 36 && newNote <= 96 {
                        newNotes[index] = newNote
                    }
                }
                // Last resort: add extension to highest position
                else if let highest = newNotes.max() {
                    let octave = highest / 12
                    var newNote = octave * 12 + extensionPitchClass
                    // Place above existing notes if possible
                    while newNote <= highest && newNote + 12 <= 96 {
                        newNote += 12
                    }
                    // Replace highest note if extension is close
                    if abs(newNote - highest) <= 4, let idx = newNotes.firstIndex(of: highest) {
                        if newNote >= 36 && newNote <= 96 {
                            newNotes[idx] = newNote
                        }
                    }
                }
            }
        }
        
        // Rebuild hand assignments
        let sorted = newNotes.sorted()
        let splitPoint = 60 // Middle C
        let leftHand = sorted.filter { $0 < splitPoint }
        let rightHand = sorted.filter { $0 >= splitPoint }
        
        return Voicing(
            chord: chord,
            notes: sorted,
            voicingType: baseVoicing.voicingType,
            leftHandNotes: leftHand.isEmpty ? [sorted.first!] : leftHand,
            rightHandNotes: rightHand.isEmpty ? [sorted.last!] : rightHand
        )
    }
}

// MARK: - Extended Voicing Model

extension Voicing {
    func voice(at index: Int) -> MIDINote? {
        let sorted = notes.sorted()
        guard index >= 0 && index < sorted.count else { return nil }
        return sorted[index]
    }
}
