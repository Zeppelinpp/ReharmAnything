# RhythmPatternLibrary

A singleton library that provides predefined rhythm patterns for different musical styles.

## Key Responsibilities

- **Pattern Storage**: Maintains a dictionary of patterns organized by `MusicStyle`.
- **Pattern Generation**: Creates standardized patterns (Whole Note, Syncopated, Quarter Note, Half Note) for each style.
- **Pattern Retrieval**: Provides methods to get patterns by style, name, or tempo suitability.

## Pattern Types

The library generates four basic pattern types for each style:

### 1. Whole Note Pattern
- **Hits**: One chord at beat 0 with 4-beat duration.
- **Use Case**: Sustained chords, ballads, sparse accompaniment.

### 2. Syncopated Pattern
- **Hits**: 
  - 8th note #2 (position 0.5) - duration 0.5 beats
  - Beat 3 (position 2.0) - duration 1.0 beat
- **Use Case**: Standard jazz comping, 2-chord-per-measure progressions.
- **Swing Factor**: 0.17 for swing/gospel styles, 0 for others.

### 3. Quarter Note Pattern
- **Hits**: Four chords at beats 0, 1, 2, 3 with 1-beat durations each.
- **Use Case**: Dense chord changes (4+ chords per measure), walking feel.
- **Velocity**: Accented on beats 1 and 3 (0.85, 0.80), lighter on 2 and 4 (0.70).

### 4. Half Note Pattern
- **Hits**: Two chords at beats 0 and 2 with 2-beat durations each.
- **Use Case**: Two-feel, moderate density progressions.

## Supported Styles

All patterns are generated for each `MusicStyle`:
- `swing`
- `bossa`
- `ballad`
- `latin`
- `funk`
- `gospel`
- `stride`

## Pattern Structure

```swift
struct RhythmPattern {
    let id: UUID
    let name: String
    let style: MusicStyle
    let lengthInBeats: Double
    let hits: [RhythmHit]
    let swingFactor: Double
    let description: String
}

struct RhythmHit {
    let position: Double      // Position in beats within the pattern
    let velocity: Double      // 0.0 - 1.0 relative velocity
    let type: RhythmHitType   // fullChord, bassOnly, topNote, etc.
    let duration: Double?     // Optional explicit duration
}
```

## Key Methods

- `getPatterns(for style:)`: Returns all patterns for a given style.
- `getPattern(named:)`: Returns a specific pattern by name (e.g., "Syncopated").
- `randomPattern(for style:)`: Returns the first (basic) pattern for a style.
- `patterns(for style:tempo:)`: Returns patterns suitable for a given tempo (simplified).

## Swing Factor

The `swingFactor` property determines how much to shift off-beat hits:
- **0.0**: Straight timing (even 8th notes).
- **0.17**: Light swing (typical for jazz).
- **0.33**: Heavy swing (triplet feel).

The `withSwing()` method on `RhythmPattern` applies the swing factor to hit positions.

## Integration with MusicHumanizer

The `MusicHumanizer` uses `RhythmPatternLibrary.shared.getPattern(named:)` to retrieve patterns for adaptive selection:

```swift
// In selectPatternForDensity()
if chordsInMeasure == 2 {
    return library.getPattern(named: "Syncopated")
}
```

## Style-Specific Humanizer Configs

Each `MusicStyle` also provides a `humanizer` property that returns a `HumanizerConfig` with appropriate timing, velocity, and legato settings for that style.

