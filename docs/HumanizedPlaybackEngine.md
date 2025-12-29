# HumanizedPlaybackEngine

The real-time playback controller that manages the conversion of musical models into scheduled audio events.

## Key Responsibilities

- **Timer Management**: Runs a high-precision tick timer (10ms) to handle beat-accurate playback.
- **Note Scheduling**: Converts a `ChordProgression` and its `Voicings` into a sequence of humanized `NoteEvent` objects.
- **Rhythm & Style**: Applies selected `MusicStyle` and `RhythmPattern` configurations to the rendering process.
- **Dynamic Looping**: Manages the loop state, resetting playback and stopping active notes at the end of a progression.

## Logic Flow

1. **Initialization**: Accepts a `SoundFontManager` and initializes a `MusicHumanizer`.
2. **Regeneration**: Whenever the progression, style, or pattern changes, it calls `JazzPianoRenderer` to regenerate the list of `scheduledNotes`.
3. **Tick Logic**: 
   - Calculates the current beat based on system time and tempo.
   - Compares the `currentBeat` against the sorted list of `scheduledNotes`.
   - Triggers `playNote` via the audio engine for notes whose position has been reached.
   - Monitors active notes and triggers `stopNote` when their duration has expired.
4. **Looping**: If `loopEnabled` is true, resets `currentBeat` to 0 when the total duration is reached and clears the set of "already played" indices.

## Key Methods

- `play()` / `pause()` / `stop()`: Controls the timer and audio state.
- `setProgression(_:voicings:)`: Updates the source data and triggers note regeneration.
- `setStyle(_:)` / `setPattern(_:)`: Updates the aesthetic parameters of the rendering.
- `seekTo(beat:)`: Allows jumping to a specific position in the progression.

