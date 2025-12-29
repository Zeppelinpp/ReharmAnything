# HumanizedPlaybackEngine

The real-time playback controller that manages the conversion of musical models into scheduled audio events.

## Key Responsibilities

- **Timer Management**: Uses `CADisplayLink` for high-precision, drift-free timing (120Hz frame rate).
- **Count-in (Pre-roll)**: Plays one full measure of metronome clicks before actual playback starts.
- **Note Scheduling**: Converts a `ChordProgression` and its `Voicings` into a sequence of humanized `NoteEvent` objects via `MusicHumanizer`.
- **Rhythm & Style**: Applies selected `MusicStyle` and `RhythmPattern` configurations.
- **Dynamic Looping**: Manages the loop state, resetting playback and stopping active notes at the end.
- **Click Track**: Contains `ClickSoundGenerator` for metronome clicks synchronized to the time signature.

## Count-in Logic

- When starting playback from the beginning (`currentBeat == 0`), the engine entering a **Count-in Phase**.
- The number of count-in beats is determined by the **Time Signature** (e.g., 4 beats for 4/4).
- The first count-in click triggers **immediately** on user interaction for zero-latency feedback.
- Subsequent clicks are scheduled at correct intervals.
- The `isCountingIn` flag notifies the UI to show a visual countdown (dots).
- No count-in is applied during loop wrap-around or when resuming from pause.

## High-Precision Timing

- Uses `CADisplayLink` for smoother, drift-free playback.
- Uses absolute time (`CFAbsoluteTimeGetCurrent()`) to calculate current beat position, preventing cumulative drift.
- `playbackStartTime` and `playbackStartBeat` track the reference point. For count-in, `playbackStartBeat` is set to `-countInBeatsTotal`.

## Click Track Support

- `clickEnabled`: Toggle for metronome click.
- `ClickSoundGenerator`: A dedicated inner class that generates a short 1kHz sine wave burst using `AVAudioEngine` and `AVAudioPlayerNode`.
- Click placement respects time signature:
  - **4/4**: Clicks on beats 2 and 4 (backbeat).
  - **3/4**: Click on beat 1 only.
  - Other time signatures: Click on beat 1 by default.

## ADSR-Aware Note Playback

- Notes are played via `SharedAudioEngine.playNote(_:velocity:channel:duration:)` which schedules automatic release.
- Integrates with `SharedAudioEngine`'s ADSR envelope for natural note articulation.

## Logic Flow

1. **Initialization**: Accepts a `SoundFontManager` and initializes a `MusicHumanizer`.
2. **Regeneration**: Whenever the progression, style, or pattern changes, calls `MusicHumanizer.generateNoteEvents()` to regenerate the list of `scheduledNotes`.
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
    ├─▶ MusicHumanizer.generateNoteEvents()
    │
    ├─▶ ClickSoundGenerator.playClick()
    │
    └─▶ SharedAudioEngine.playNote(duration:)
```

## Key Methods

- `play()` / `pause()` / `stop()`: Controls the `CADisplayLink` and audio state.
- `setProgression(_:voicings:)`: Updates the source data and triggers note regeneration.
- `setStyle(_:)` / `setPattern(_:)`: Updates the aesthetic parameters of the rendering.
- `applyPreset(_:)`: Applies humanization presets (robotic, tight, natural, loose, expressive).
- `seekTo(beat:)`: Allows jumping to a specific position in the progression.

## Humanization Presets

| Preset | Description |
|--------|-------------|
| `robotic` | Zero humanization, perfect timing |
| `tight` | Minimal jitter, precise feel |
| `natural` | Default balanced humanization |
| `loose` | More variation, relaxed feel |
| `expressive` | Maximum expression with chord rolling |
| `styleDefault` | Uses the selected MusicStyle's default config |
