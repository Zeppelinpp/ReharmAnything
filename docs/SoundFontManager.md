# SoundFontManager

The bridge between high-level MIDI note requests and low-level audio synthesis using SoundFont (.sf2) files.

## Key Responsibilities

- **Audio Engine Lifecycle**: Initializes and manages the `AVAudioEngine` and `AVAudioUnitSampler`.
- **SoundFont Loading**: Locates and loads specific `.sf2` files from the app bundle (e.g., "UprightPianoKW" for grand piano, "jRhodes3" for Rhodes).
- **Note Execution**: Forwards `startNote` and `stopNote` commands to the sampler unit.
- **Resource Management**: Handles audio session configuration (iOS) and ensures the engine is started and stopped correctly.

## Component Hierarchy

- **`SharedAudioEngine`**: A singleton that holds the actual `AVAudioEngine` and handles the low-level `AVAudioUnitSampler` calls. It includes logic for:
  - Finding SoundFont files in the bundle or documents.
  - Handling bank/program selection.
  - Managing active notes to prevent hanging.
- **`SoundFontSource`**: Implements the `SoundSource` protocol, wrapping the shared engine for specific instrument types.
- **`SoundFontManager`**: The top-level interface used by the ViewModels and Playback Engine to trigger chords and select instruments.

## Performance & Utility

- **Fade-out Logic**: Implements basic note stopping that minimizes clicks by removing notes from the active set.
- **Sound Types**: Supports multiple instrument profiles defined in `SoundFontType`.
- **Error Handling**: Tracks initialization state and load errors to inform the UI.
- **Safety**: Includes `stopAllNotesImmediate()` to clear any hanging MIDI voices.

