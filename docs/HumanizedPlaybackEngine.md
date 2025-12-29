# HumanizedPlaybackEngine

The real-time playback controller that manages the conversion of musical models into scheduled audio events.

## Key Responsibilities

- **Timer Management**: Uses `CADisplayLink` for high-precision, drift-free timing (120Hz frame rate).
- **Note Scheduling**: Converts a `ChordProgression` and its `Voicings` into a sequence of humanized `NoteEvent` objects.
- **Rhythm & Style**: Applies selected `MusicStyle` and `RhythmPattern` configurations to the rendering process.
- **Dynamic Looping**: Manages the loop state, resetting playback and stopping active notes at the end of a progression.
- **Click Track**: Generates a metronome click synchronized to the time signature.

## New Features

### High-Precision Timing
- Replaced `Timer` with `CADisplayLink` for smoother, drift-free playback.
- Uses absolute time (`CFAbsoluteTimeGetCurrent()`) to calculate current beat position, preventing cumulative timing errors.
- `playbackStartTime` and `playbackStartBeat` track the reference point for timing calculations.

### Click Track Support
- `clickEnabled`: Toggle for metronome click.
- `ClickSoundGenerator`: A dedicated class that generates a short 1kHz sine wave burst using `AVAudioEngine` and `AVAudioPlayerNode`.
- Click placement respects time signature:
  - **4/4**: Clicks on beats 2 and 4 (backbeat).
  - **3/4**: Click on beat 1 only.
  - Other time signatures: Click on beat 1 by default.

### ADSR-Aware Note Playback
- `playNote(_:velocity:channel:duration:)`: New method that schedules automatic note release after a specified duration.
- Integrates with `SharedAudioEngine`'s ADSR envelope for natural note articulation.

## Logic Flow

1. **Initialization**: Accepts a `SoundFontManager` and initializes a `MusicHumanizer`.
2. **Regeneration**: Whenever the progression, style, or pattern changes, it calls `MusicHumanizer` (which uses `JazzPianoRenderer`) to regenerate the list of `scheduledNotes`.
3. **Tick Logic (`displayLinkTick`)**:
   - Calculates the current beat based on `CFAbsoluteTimeGetCurrent()` and tempo.
   - Handles loop wrap-around when `currentBeat >= totalBeats`.
   - Plays click track if enabled.
   - Triggers `playNote` for notes whose position has been reached.
4. **Looping**: Resets timing reference (`playbackStartTime`, `playbackStartBeat`) and clears played indices at loop boundary.

## Component Interaction

```
ChordViewModel
    │
    ▼ setProgression(), play(), stop()
HumanizedPlaybackEngine
    │
    ├─▶ MusicHumanizer.generateNoteEvents() ──▶ JazzPianoRenderer
    │
    ├─▶ ClickSoundGenerator.playClick()
    │
    └─▶ SharedAudioEngine.playNote(duration:)
```

## Key Methods

- `play()` / `pause()` / `stop()`: Controls the `CADisplayLink` and audio state.
- `setProgression(_:voicings:)`: Updates the source data and triggers note regeneration.
- `setStyle(_:)` / `setPattern(_:)`: Updates the aesthetic parameters of the rendering.
- `seekTo(beat:)`: Allows jumping to a specific position in the progression.
- `toggleClick()` (via ViewModel): Enables/disables the metronome.
