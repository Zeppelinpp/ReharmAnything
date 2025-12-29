# MusicHumanizer

A service that applies musical humanization to note events and handles adaptive pattern selection based on chord density.

## Key Responsibilities

- **Humanization Application**: Applies timing jitter, velocity variation, and articulation to raw note events.
- **Adaptive Pattern Selection**: Automatically selects appropriate rhythm patterns based on how many chords are in each measure.
- **Grid-Aligned Timing**: Ensures rhythm patterns stay consistent across chord changes by aligning to absolute beat positions.

## Adaptive Pattern Selection

The humanizer analyzes the chord density per measure and selects patterns accordingly:

| Chords per Measure | Chord Duration | Selected Pattern | Rationale                                      |
|--------------------|----------------|------------------|------------------------------------------------|
| ≥ 4                | ≤ 1.0 beats    | None (on-beat)   | Too dense for patterns; play exactly at chord's start. |
| 2                  | ~2.0 beats     | "Syncopated"     | Half-bar chords benefit from syncopation.      |
| 1                  | ≥ 4.0 beats    | **Weighted Random** | Favour sustaining the chord (70%) over syncopation (30%). |

### Weighted Selection for Sparse Bars

When an entire measure (usually 4 beats) contains only one chord, the humanizer uses a **weighted random selection** to decide how to play it:

- **90% Chance: "Whole Note" Pattern**
  - The chord is sustained through the entire measure.
  - More natural for slower ballads or traditional jazz accompaniment.
  - Preferred to avoid "short staccato" feel in sparse charts.
- **10% Chance: "Syncopated" Pattern**
  - Adds occasional rhythmic interest with a syncopated feel.
  - Rare enough to prevent repetitive "jumpy" behavior.

This logic ensures that "playing on beat 1 and stopping" (which often happens with short-duration patterns) is avoided in favor of more musical sustain.

### Implementation

```swift
private func selectPatternForDensity(
    chordsInMeasure: Int,
    chordDuration: Double,
    beatsPerMeasure: Double,
    fallbackPattern: RhythmPattern?
) -> RhythmPattern?
```

1. **Density Analysis**: `analyzeMeasureDensity()` counts chords per measure number.
2. **Pattern Selection**: Based on count and duration, returns appropriate pattern from `RhythmPatternLibrary`.
3. **Fallback**: If no specific pattern applies, uses the provided fallback.

## Grid-Aligned Pattern Application

The `applyRhythmPattern()` method ensures patterns align to the absolute beat grid:

```swift
var currentPatternBase = floor(startBeat / pattern.lengthInBeats) * pattern.lengthInBeats
```

This prevents patterns from drifting when chords don't start on pattern boundaries.

### Algorithm

1. Calculate the pattern base aligned to the grid.
2. Iterate through pattern hits.
3. For each hit, check if its absolute position falls within the chord's time range.
4. If so, generate humanized notes with appropriate duration.
5. Move to next pattern repetition until past the chord's end beat.

## Humanization Pipeline

For each chord event:

1. **Measure Analysis**: Determine which measure the chord is in.
2. **Pattern Selection**: Call `selectPatternForDensity()`.
3. **Pattern Application**: If a pattern is selected, call `applyRhythmPattern()`.
4. **Humanization**: Apply `humanize()` to the resulting notes.
5. **Fallback**: If no pattern, play a sustained chord at the start beat.

## Component Interaction

```
ChordViewModel.generateVoicings()
    │
    ▼
HumanizedPlaybackEngine.setProgression()
    │
    ▼
MusicHumanizer.generateNoteEvents()
    │
    ├─▶ analyzeMeasureDensity()
    │
    ├─▶ selectPatternForDensity()
    │       │
    │       └─▶ RhythmPatternLibrary.getPattern(named:)
    │
    ├─▶ applyRhythmPattern() [grid-aligned]
    │       │
    │       └─▶ generateHitNotes()
    │
    └─▶ humanize() ──▶ [NoteEvent]
```

## Key Methods

- `generateNoteEvents(from:voicings:pattern:)`: Main entry point for humanized event generation.
- `analyzeMeasureDensity(events:beatsPerMeasure:)`: Returns a dictionary of measure number to chord count.
- `selectPatternForDensity(...)`: Chooses the appropriate pattern based on density.
- `applyRhythmPattern(pattern:to:startBeat:duration:)`: Generates notes from a pattern with grid alignment.
- `humanize(notes:startBeat:)` / `humanize(voicingEvent:)`: Applies micro-timing and velocity variations.

