# SoundFontManager

The bridge between high-level MIDI note requests and low-level audio synthesis using SoundFont (.sf2) files.

## Key Responsibilities

- **Audio Engine Lifecycle**: Initializes and manages the `AVAudioEngine` and `AVAudioUnitSampler`.
- **SoundFont Loading**: Locates and loads specific `.sf2` files from the app bundle (e.g., "UprightPianoKW" for grand piano, "jRhodes3" for Rhodes).
- **ADSR Envelope**: Implements attack-decay-sustain-release envelope simulation for natural note articulation.
- **Note Execution**: Forwards `startNote` and `stopNote` commands to the sampler unit with proper envelope handling.
- **Resource Management**: Handles audio session configuration (iOS) and ensures the engine is started and stopped correctly.

## New Features

### ADSR Envelope System

The `ADSREnvelope` struct defines articulation parameters:

| Preset     | Attack  | Decay  | Sustain | Release | Use Case                     |
|------------|---------|--------|---------|---------|------------------------------|
| `piano`    | 0.005s  | 0.1s   | 0.7     | 0.15s   | Default for Grand Piano.     |
| `rhodes`   | 0.01s   | 0.15s  | 0.6     | 0.2s    | Electric piano feel.         |
| `staccato` | 0.002s  | 0.05s  | 0.3     | 0.08s   | Short, percussive notes.     |
| `legato`   | 0.01s   | 0.2s   | 0.85    | 0.25s   | Smooth, connected notes.     |

Each `SoundFontType` has a `defaultADSR` property that automatically applies the appropriate envelope.

### Duration-Based Note Playback

New method `playNote(_:velocity:channel:duration:)`:
1. Plays the note immediately.
2. Schedules a `releaseTimer` to call `stopNoteWithRelease()` after the specified duration.
3. Enables precise note lengths for rhythmic patterns.

### Natural Release Envelope

`stopNoteWithRelease(_:channel:)`:
- Implements a multi-step fade-out over the `release` duration.
- Divides the release into 5 steps for smooth decay.
- Prevents abrupt note cutoffs that sound mechanical.

## Component Hierarchy

- **`SharedAudioEngine`**: A singleton that holds the actual `AVAudioEngine` and handles the low-level `AVAudioUnitSampler` calls. It includes logic for:
  - Finding SoundFont files in the bundle or documents.
  - Handling bank/program selection.
  - Managing active notes and release timers.
  - ADSR envelope simulation.
- **`SoundFontSource`**: Implements the `SoundSource` protocol, wrapping the shared engine for specific instrument types.
- **`SoundFontManager`**: The top-level interface used by the ViewModels and Playback Engine to trigger chords and select instruments.

## Performance & Utility

- **Timer Management**: Maintains both `fadeOutTimers` and `releaseTimers` for different note-off scenarios.
- **Sound Types**: Supports multiple instrument profiles defined in `SoundFontType` (Grand Piano, Rhodes).
- **Error Handling**: Tracks initialization state and load errors to inform the UI.
- **Safety**: Includes `stopAllNotesImmediate()` to clear any hanging MIDI voices.

## Component Interaction

```
HumanizedPlaybackEngine
    │
    ▼ playNote(note, velocity, channel, duration)
SharedAudioEngine
    │
    ├─▶ sampler.startNote() [with attack velocity]
    │
    └─▶ releaseTimer (after duration) ──▶ stopNoteWithRelease()
                                              │
                                              └─▶ Multi-step fade ──▶ sampler.stopNote()
```
