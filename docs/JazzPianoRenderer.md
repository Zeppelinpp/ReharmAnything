# JazzPianoRenderer

The core engine for transforming static chord voicings into expressive, humanized musical performances.

## Key Responsibilities

- **Micro-timing Jitter**: Adds subtle, Gaussian-distributed variations to note start times to simulate human fallibility.
- **Lay-back & Push**: Adjusts the timing relative to the beat to create "feel" (e.g., jazz lay-back or funk pushing).
- **Strumming (Rolling)**: Simulates the physical action of a pianist's hands by slightly staggering note onset times within a chord.
- **Velocity Dynamics**: Applies realistic velocity variations, including melody accents, register-based brightness (pitch bias), and softer left-hand touches.
- **Anticipation Handling**: Implements the crucial jazz concept of "anticipation hits" (and-of-4), where the *next* chord is played slightly before the bar line and tied over.

## Configuration Presets (`JazzRendererConfig`)

The renderer uses `JazzRendererConfig` to define its personality:

| Preset    | `timingJitter` | `layBackAmount` | `strumSpeed` | `legatoFactor` | Description                              |
|-----------|----------------|-----------------|--------------|----------------|------------------------------------------|
| `swing`   | 0.022          | 0.012           | 0.018        | 0.85           | Moderate jitter, standard swing feel.    |
| `bebop`   | 0.018          | 0.008           | 0.012        | 0.78           | Tighter, more agile.                     |
| `ballad`  | 0.028          | 0.025           | 0.038        | 0.95           | Slower strumming, more legato.           |
| `latin`   | 0.012          | 0.005           | 0.008        | 0.82           | Tight, even timing.                      |
| `funk`    | 0.01           | -0.008 (push)   | 0.006        | 0.7            | Staccato, slightly ahead of beat.        |
| `gospel`  | 0.03           | 0.018           | 0.045        | 0.92           | Wide dynamics, expressive rolling.       |
| `robotic` | 0              | 0               | 0            | 1.0            | Zero humanization, perfect timing.       |

## Core Rendering Algorithm

### Main Entry: `render(progression:voicings:pattern:)`

1. **Anticipation Detection Pass**: Scans the rhythm pattern to check if any hits fall on the "and-of-4" (position >= 3.4).
2. **Iteration**: For each chord event:
   - Determines `currentVoicing` and `nextVoicing` (for anticipation).
   - Checks if the *previous* chord had an anticipation hit (if so, skips beat 1 of the current chord to avoid double-triggering).
   - Calls `renderPatternWithAnticipation()` or `renderSustainedChord()`.

### Pattern Rendering: `renderPatternWithAnticipation(...)`

For each hit in the pattern:
1. **Skip Logic**: If `skipBeatOne` is true and this hit is at position 0.0, skip it.
2. **Voicing Selection**: If this is an anticipation hit, use `nextVoicing`; otherwise, use `currentVoicing`.
3. **Duration Calculation**: For anticipation hits, extend duration into the next bar.
4. **Note Selection**: Based on `RhythmHitType` (fullChord, bassOnly, topNote, leftHand, rightHand, rest).
5. **Humanization**: Call `renderHit()` to apply all micro-timing and velocity variations.

### Single Hit Rendering: `renderHit(...)`

1. **Chord Timing Offset**: A single Gaussian random value shared by all notes in the chord.
2. **Feel Offset**: `layBackAmount` for normal hits, `anticipationPush` for anticipation.
3. **Strum Calculation**: If strumming, calculate per-note delay based on index.
4. **Per-Note Velocity**: Base velocity + pitch bias + left-hand reduction + melody accent + random jitter.
5. **Duration**: `baseDuration * legatoFactor + durationJitter`.
6. **Output**: Creates `NoteEvent` objects.

## Helper Utilities

- `GaussianRandom`: Box-Muller transform for normal distribution randomization.
- `selectNotes(for:voicing:allNotes:)`: Maps `RhythmHitType` to actual MIDI notes.
- `isAnticipationHit(_:)`: Checks if a hit's position falls in the anticipation zone (>= 3.4 beats in a 4-beat bar).

## Style Mapping

`MusicStyle` extension provides a `rendererConfig` property that maps each style to its corresponding `JazzRendererConfig` preset.

## Dynamic Comping Selector

`DynamicCompingSelector` provides intelligent pattern selection based on musical context:
- `selectPattern(for:intensity:previousPattern:)`: Filters patterns by hit count based on intensity level (0.0-1.0).
- `selectWeightedPattern(for:weights:)`: Weighted random selection favoring specified patterns.
