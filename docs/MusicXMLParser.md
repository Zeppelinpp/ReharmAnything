# MusicXMLParser

A service for parsing MusicXML files exported from iReal Pro or other music notation software into chord progressions.

## Key Responsibilities

- **XML Parsing**: Uses `XMLParser` (NSXMLParser) to parse MusicXML data.
- **Chord Extraction**: Extracts harmony elements (root, kind, bass, degrees) and converts them to `Chord` objects.
- **Repeat Expansion**: Expands repeat structures (including first/second endings) into a linear progression.
- **Metadata Extraction**: Captures title, composer, style, time signature, and section markers.

## Parsing Result Structure

```swift
struct ParsedProgression {
    var title: String
    var composer: String?
    var style: String?
    var timeSignature: TimeSignature
    var keySignature: KeySignature?  // Key center from MusicXML
    var divisions: Int  // Divisions per quarter note
    var events: [ChordEvent]
    var tempo: Double
    var sectionMarkers: [SectionMarker]
    var repeats: [RepeatInfo]
    
    func toChordProgression() -> ChordProgression
}
```

## Raw Measure Data

Before repeat expansion, the parser builds intermediate `RawMeasureData` structures:

```swift
struct RawMeasureData {
    var measureNumber: Int
    var chords: [(chord: Chord, positionInMeasure: Double)]
    var sectionLabel: String?
    var isRepeatStart: Bool
    var isRepeatEnd: Bool
    var endingNumber: Int?  // 1 = first ending, 2 = second ending
}
```

## Repeat Expansion Algorithm

The `expandRepeats()` method handles complex repeat structures:

1. **First Pass**: Play from repeat start to repeat end, including first ending, skipping second ending.
2. **Second Pass**: Play from repeat start to just before first ending, then add second ending measures.
3. **Continuation**: Add remaining measures after the repeat structure.

### Example: AABA Form with Repeats

```
Original: ||: A | A | B | A :|| (with 1st/2nd endings)

Expanded: A | A | B | A₁ | A | A | B | A₂ | ...
```

## XML Element Handling

### Harmony Elements
- `<root>`: Contains `<root-step>` (C, D, E...) and `<root-alter>` (-1, 0, 1)
- `<kind>`: Chord quality (major, minor, dominant, major-seventh, etc.)
- `<bass>`: Slash chord bass note
- `<degree>`: Extensions (9, 11, 13, alterations)

### Structural Elements
- `<measure number="N">`: Measure boundaries
- `<repeat direction="forward|backward">`: Repeat signs
- `<ending type="start|stop" number="1|2">`: First/second endings
- `<rehearsal>`: Section markers (A, B, C)

### Key Signature Elements
- `<key>`: Contains key signature information
  - `<fifths>`: Circle of fifths position (0=C, 1=G, -1=F, 2=D, -2=Bb, etc.)
  - `<mode>`: `major` or `minor`

| fifths | Major Key | Minor Key |
|--------|-----------|-----------|
| 0      | C         | Am        |
| +1     | G         | Em        |
| -1     | F         | Dm        |
| +2     | D         | Bm        |
| -2     | Bb        | Gm        |

### Metadata Elements
- `<work-title>`: Song title
- `<creator type="composer">`: Composer name
- `<creator type="lyricist">`: Style (iReal Pro convention)
- `<time>`: Time signature (`<beats>` and `<beat-type>`)
- `<key>`: Key signature (`<fifths>` and `<mode>`)
- `<divisions>`: Divisions per quarter note (for position calculation)

## Chord Quality Mapping

| MusicXML Kind           | ChordQuality       |
|-------------------------|--------------------|
| `major`, ``             | `.major`           |
| `minor`                 | `.minor`           |
| `dominant`              | `.dominant7`       |
| `major-seventh`         | `.major7`          |
| `minor-seventh`         | `.minor7`          |
| `half-diminished`       | `.halfDiminished`  |
| `diminished-seventh`    | `.diminished7`     |
| `augmented`             | `.augmented`       |
| `suspended-fourth`      | `.sus4`            |
| `dominant-ninth`        | `.dominant9`       |

## Position Calculation

Chord positions are calculated using MusicXML's division system:

```swift
let positionInBeats = Double(currentPositionInMeasure) / Double(divisions)
let measureStartBeat = Double(measureNumber - 1) * beatsPerMeasure
let chordStartBeat = measureStartBeat + positionInBeats
```

## Duration Calculation

The `calculateDurations()` method computes each chord's duration:
- Duration = next chord's start beat - current chord's start beat
- Last chord extends to the end of the progression
- Minimum duration: 0.5 beats

## Error Handling

```swift
enum MusicXMLParserError: Error {
    case invalidData
    case parseFailure
    case missingRequiredElement(String)
}
```

## Usage

```swift
let parser = MusicXMLParser()

// From URL
let progression = try parser.parse(url: fileURL).toChordProgression()

// From Data
let progression = try parser.parse(data: xmlData).toChordProgression()

// From String
let progression = try parser.parse(xmlString: xmlContent).toChordProgression()
```

## Integration with ChordViewModel

```swift
func importMusicXML(from url: URL) {
    guard url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    
    let parsed = try musicXMLParser.parse(url: url)
    let progression = parsed.toChordProgression()
    setProgression(progression)
}
```

