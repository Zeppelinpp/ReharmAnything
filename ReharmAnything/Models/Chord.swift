import Foundation

// MIDI note representation
typealias MIDINote = Int

// MARK: - Time Signature

/// Represents a musical time signature
struct TimeSignature: Codable, Equatable {
    let beats: Int      // Numerator (e.g., 4 in 4/4)
    let beatType: Int   // Denominator (e.g., 4 in 4/4)
    
    static let common = TimeSignature(beats: 4, beatType: 4)  // 4/4
    static let waltz = TimeSignature(beats: 3, beatType: 4)   // 3/4
    static let cut = TimeSignature(beats: 2, beatType: 2)     // 2/2
    
    /// Number of eighth notes in one measure
    var eighthNotesPerMeasure: Int {
        let eighthsPerBeat = 8 / beatType
        return beats * eighthsPerBeat
    }
    
    /// Duration of one measure in beats (quarter notes)
    var beatsPerMeasure: Double {
        return Double(beats) * (4.0 / Double(beatType))
    }
    
    /// Position of each eighth note in a measure (in beats)
    func eighthNotePositions() -> [Double] {
        let eighthNoteDuration = 0.5  // Half a beat
        return (0..<eighthNotesPerMeasure).map { Double($0) * eighthNoteDuration }
    }
}

// MARK: - Voicing Types

enum VoicingType: String, CaseIterable, Identifiable, Codable {
    case rootlessA = "Rootless A"   // 3-5-7-9 (Bill Evans)
    case rootlessB = "Rootless B"   // 7-9-3-5 (Bill Evans)
    case quartal = "Quartal"        // 4th stacks (McCoy Tyner)
    case drop2 = "Drop 2"
    case drop3 = "Drop 3"
    case shell = "Shell"            // Root-3-7
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .rootlessA: return "Bill Evans A型: 3-5-7-9"
        case .rootlessB: return "Bill Evans B型: 7-9-3-5"
        case .quartal: return "McCoy Tyner: 四度叠置"
        case .drop2: return "Drop 2: 第二声部下移八度"
        case .drop3: return "Drop 3: 第三声部下移八度"
        case .shell: return "Shell: 根音-三音-七音"
        }
    }
}

enum NoteName: String, CaseIterable, Codable {
    case C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B
    
    // Chromatic pitch class (0-11)
    var pitchClass: Int {
        switch self {
        case .C: return 0
        case .Db: return 1
        case .D: return 2
        case .Eb: return 3
        case .E: return 4
        case .F: return 5
        case .Gb: return 6
        case .G: return 7
        case .Ab: return 8
        case .A: return 9
        case .Bb: return 10
        case .B: return 11
        }
    }
    
    static func from(pitchClass: Int) -> NoteName {
        let normalized = ((pitchClass % 12) + 12) % 12
        return NoteName.allCases[normalized]
    }
    
    // Parse from string (handles sharps and flats)
    static func parse(_ str: String) -> NoteName? {
        let normalized = str
            .replacingOccurrences(of: "#", with: "b")
            .replacingOccurrences(of: "Cb", with: "B")
            .replacingOccurrences(of: "Fb", with: "E")
            .replacingOccurrences(of: "E#", with: "F")
            .replacingOccurrences(of: "B#", with: "C")
        
        // Handle enharmonic equivalents
        let mapping: [String: NoteName] = [
            "C": .C, "C#": .Db, "Db": .Db,
            "D": .D, "D#": .Eb, "Eb": .Eb,
            "E": .E,
            "F": .F, "F#": .Gb, "Gb": .Gb,
            "G": .G, "G#": .Ab, "Ab": .Ab,
            "A": .A, "A#": .Bb, "Bb": .Bb,
            "B": .B
        ]
        return mapping[normalized]
    }
}

enum ChordQuality: String, Codable, CaseIterable {
    case major = ""
    case minor = "-"
    case dominant7 = "7"
    case major7 = "maj7"
    case minor7 = "-7"
    case diminished = "dim"
    case diminished7 = "dim7"
    case halfDiminished = "-7b5"
    case augmented = "aug"
    case sus4 = "sus4"
    case sus2 = "sus2"
    case dominant9 = "9"
    case dominant13 = "13"
    case minor9 = "-9"
    case major9 = "maj9"
    case altered = "7alt"
    
    // Intervals from root (in semitones)
    var intervals: [Int] {
        switch self {
        case .major: return [0, 4, 7]
        case .minor: return [0, 3, 7]
        case .dominant7: return [0, 4, 7, 10]
        case .major7: return [0, 4, 7, 11]
        case .minor7: return [0, 3, 7, 10]
        case .diminished: return [0, 3, 6]
        case .diminished7: return [0, 3, 6, 9]
        case .halfDiminished: return [0, 3, 6, 10]
        case .augmented: return [0, 4, 8]
        case .sus4: return [0, 5, 7]
        case .sus2: return [0, 2, 7]
        case .dominant9: return [0, 4, 7, 10, 14]
        case .dominant13: return [0, 4, 7, 10, 14, 21]
        case .minor9: return [0, 3, 7, 10, 14]
        case .major9: return [0, 4, 7, 11, 14]
        case .altered: return [0, 4, 6, 10, 13, 15] // 7#9b13 voicing
        }
    }
    
    var isDominant: Bool {
        switch self {
        case .dominant7, .dominant9, .dominant13, .altered:
            return true
        default:
            return false
        }
    }
}

struct Chord: Identifiable, Codable, Equatable {
    let id: UUID
    let root: NoteName
    let quality: ChordQuality
    let bass: NoteName? // For slash chords
    let extensions: [String] // Additional alterations like b9, #11
    
    init(root: NoteName, quality: ChordQuality, bass: NoteName? = nil, extensions: [String] = []) {
        self.id = UUID()
        self.root = root
        self.quality = quality
        self.bass = bass
        self.extensions = extensions
    }
    
    var displayName: String {
        // Check if this is a diminished stack polychord
        if extensions.contains("dimStack") && quality.isDominant {
            return polychordDisplayName
        }
        
        var name = root.rawValue + quality.rawValue
        let visibleExtensions = extensions.filter { $0 != "dimStack" }
        if !visibleExtensions.isEmpty {
            name += "(" + visibleExtensions.joined(separator: ",") + ")"
        }
        if let bass = bass {
            name += "/" + bass.rawValue
        }
        return name
    }
    
    // Polychord display for diminished stack voicing
    // C7 with dimStack -> C triad + A triad (root + minor 3rd below root)
    // Display as "C/A" (root triad on top, lower triad on bottom)
    private var polychordDisplayName: String {
        // Lower triad is minor 3rd below root (root - 3 semitones)
        let lowerRootPitchClass = (root.pitchClass - 3 + 12) % 12
        let lowerRoot = NoteName.from(pitchClass: lowerRootPitchClass)
        
        // Display as "RootTriad\nLowerTriad" for vertical polychord notation
        return "\(root.rawValue)\n\(lowerRoot.rawValue)"
    }
    
    var isDominant: Bool {
        quality.isDominant
    }
    
    // Get pitch classes for this chord
    func pitchClasses() -> [Int] {
        quality.intervals.map { (root.pitchClass + $0) % 12 }
    }
}

// Voicing: specific MIDI notes for a chord with two-hand separation
struct Voicing: Equatable {
    let chord: Chord
    let notes: [MIDINote]           // All MIDI notes combined
    var voicingType: VoicingType?
    var leftHandNotes: [MIDINote]   // Left hand notes (bass register)
    var rightHandNotes: [MIDINote]  // Right hand notes (treble register)
    
    init(chord: Chord, notes: [MIDINote], voicingType: VoicingType? = nil, leftHandNotes: [MIDINote]? = nil, rightHandNotes: [MIDINote]? = nil) {
        self.chord = chord
        self.notes = notes
        self.voicingType = voicingType
        
        // If hands not specified, split by register (middle C = 60)
        if let lh = leftHandNotes, let rh = rightHandNotes {
            self.leftHandNotes = lh
            self.rightHandNotes = rh
        } else {
            let sorted = notes.sorted()
            let splitPoint = 60 // Middle C
            self.leftHandNotes = sorted.filter { $0 < splitPoint }
            self.rightHandNotes = sorted.filter { $0 >= splitPoint }
            
            // Ensure at least some notes in each hand
            if self.leftHandNotes.isEmpty && !sorted.isEmpty {
                self.leftHandNotes = [sorted[0]]
                self.rightHandNotes = Array(sorted.dropFirst())
            }
            if self.rightHandNotes.isEmpty && sorted.count > 1 {
                self.rightHandNotes = [sorted.last!]
                self.leftHandNotes = Array(sorted.dropLast())
            }
        }
    }
    
    var bassNote: MIDINote? {
        notes.min()
    }
    
    var topNote: MIDINote? {
        notes.max()
    }
    
    // Center of voicing (average pitch)
    var center: Double {
        guard !notes.isEmpty else { return 60 }
        return Double(notes.reduce(0, +)) / Double(notes.count)
    }
    
    // Spread (range from lowest to highest)
    var spread: Int {
        guard let low = notes.min(), let high = notes.max() else { return 0 }
        return high - low
    }
    
    // Get the 3rd of the chord in this voicing
    func thirdNote() -> MIDINote? {
        let thirdInterval = chord.quality.intervals.contains(3) ? 3 : 4
        let thirdPitchClass = (chord.root.pitchClass + thirdInterval) % 12
        return notes.first { $0 % 12 == thirdPitchClass }
    }
    
    // Get the 7th of the chord in this voicing
    func seventhNote() -> MIDINote? {
        let seventhIntervals = [10, 11, 9] // b7, maj7, dim7
        for interval in seventhIntervals {
            let pitchClass = (chord.root.pitchClass + interval) % 12
            if let note = notes.first(where: { $0 % 12 == pitchClass }) {
                return note
            }
        }
        return nil
    }
    
    // Calculate voice leading distance to another voicing
    func voiceLeadingDistance(to other: Voicing) -> Int {
        guard notes.count == other.notes.count else {
            return Int.max
        }
        return zip(notes.sorted(), other.notes.sorted())
            .map { abs($0 - $1) }
            .reduce(0, +)
    }
    
    // Format notes as readable string
    func notesDescription() -> String {
        let noteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        return notes.sorted().map { midi in
            let octave = midi / 12 - 1
            let note = noteNames[midi % 12]
            return "\(note)\(octave)"
        }.joined(separator: " ")
    }
    
    // Format with hand separation
    func handsDescription() -> (left: String, right: String) {
        let noteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        
        let leftStr = leftHandNotes.sorted().map { midi in
            let octave = midi / 12 - 1
            let note = noteNames[midi % 12]
            return "\(note)\(octave)"
        }.joined(separator: " ")
        
        let rightStr = rightHandNotes.sorted().map { midi in
            let octave = midi / 12 - 1
            let note = noteNames[midi % 12]
            return "\(note)\(octave)"
        }.joined(separator: " ")
        
        return (leftStr, rightStr)
    }
    
    static func == (lhs: Voicing, rhs: Voicing) -> Bool {
        lhs.chord == rhs.chord && lhs.notes == rhs.notes
    }
}

// MARK: - Section Marker

/// Section marker (A, B, C, etc.) for chart navigation
struct SectionMarker: Codable, Equatable {
    let label: String       // "A", "B", "C", etc.
    let measureNumber: Int  // Measure where this section starts
}

// MARK: - Repeat Structure

/// Repeat information for a section
struct RepeatInfo: Codable, Equatable {
    let startMeasure: Int
    let endMeasure: Int
    let times: Int  // Number of times to repeat (usually 2)
    var endings: [Ending]  // First/second endings
    
    struct Ending: Codable, Equatable {
        let number: Int         // 1 = first ending, 2 = second ending
        let startMeasure: Int
        let endMeasure: Int
    }
}

// Chord progression (sequence of chords with timing)
struct ChordEvent: Identifiable, Codable {
    let id: UUID
    let chord: Chord
    let startBeat: Double
    let duration: Double // In beats
    var measureNumber: Int  // Which measure this chord is in
    var sectionLabel: String?  // Section marker if at start of section
    
    init(chord: Chord, startBeat: Double, duration: Double, measureNumber: Int = 1, sectionLabel: String? = nil) {
        self.id = UUID()
        self.chord = chord
        self.startBeat = startBeat
        self.duration = duration
        self.measureNumber = measureNumber
        self.sectionLabel = sectionLabel
    }
}

struct ChordProgression: Identifiable, Codable {
    let id: UUID
    let title: String
    var composer: String?
    var style: String?
    var events: [ChordEvent]
    var tempo: Double // BPM
    var timeSignature: TimeSignature
    var sectionMarkers: [SectionMarker]  // A, B, C section labels
    var repeats: [RepeatInfo]  // Repeat structures
    
    init(title: String, events: [ChordEvent], tempo: Double = 120, timeSignature: TimeSignature = .common, composer: String? = nil, style: String? = nil, sectionMarkers: [SectionMarker] = [], repeats: [RepeatInfo] = []) {
        self.id = UUID()
        self.title = title
        self.composer = composer
        self.style = style
        self.events = events
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.sectionMarkers = sectionMarkers
        self.repeats = repeats
    }
    
    var totalBeats: Double {
        events.map { $0.startBeat + $0.duration }.max() ?? 0
    }
    
    /// Total number of measures in the progression
    var totalMeasures: Int {
        Int(ceil(totalBeats / timeSignature.beatsPerMeasure))
    }
    
    /// Get section label for a specific measure
    func sectionLabel(forMeasure measure: Int) -> String? {
        sectionMarkers.first { $0.measureNumber == measure }?.label
    }
}

