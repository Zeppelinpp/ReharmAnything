# ChordViewModel

The central orchestrator for the ReharmAnything application. It manages the application state, handles user interactions, and coordinates data flow between services.

## Key Responsibilities

- **State Management**: Maintains the original and reharmonized chord progressions, current voicings, playback state (tempo, current beat, isPlaying), and UI-related flags.
- **Service Coordination**: Uses `IrealParser` for imports, `ReharmManager` for logic, `VoiceLeadingOptimizer` for voicing calculation, and `HumanizedPlaybackEngine` for audio.
- **Audio Control**: Provides high-level methods for playback (play, pause, stop, toggle) and sound font selection.
- **Data Transformation**: Bridges raw input strings to structured musical models and finally to optimized performance data.

## Principal Data & State

- `originalProgression`: The primary chord chart imported by the user.
- `reharmedProgression`: The version of the chart after applying a transformation strategy.
- `currentVoicings`: The optimized MIDI realizations for each chord in the active progression.
- `playbackEngine`: An instance of `HumanizedPlaybackEngine` that handles the real-time audio thread.

## Key Methods

- `importChart()`: Attempts to parse `inputText` using both iReal and simple text formats.
- `setProgression(_:)`: Updates the internal state, identifies reharmonization targets, and triggers initial voicing generation.
- `generateVoicings(for:)`: Delegates to `VoiceLeadingOptimizer` to create a smooth sequence of voicings and updates the playback engine.
- `applyReharm()`: Applies the currently selected `ReharmStrategy` from `ReharmManager` to the original progression.
- `updateTempo(_:)`: Updates the BPM and synchronizes the playback engine.
- `previewChord(at:)`: Plays a one-off realization of a specific chord in the progression for auditory feedback.

## Observables

As a `@MainActor` `ObservableObject`, it publishes updates to the UI whenever state changes, ensuring `ContentView`, `ChordInputView`, and `ReharmView` stay synchronized.

