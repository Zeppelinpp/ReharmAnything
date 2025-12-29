# ChordViewModel

The central orchestrator for the ReharmAnything application. It manages the application state, handles user interactions, and coordinates data flow between services.

## Key Responsibilities

- **State Management**: Maintains the original and reharmonized chord progressions, current voicings, playback state (tempo, current beat, isPlaying), and UI-related flags.
- **Service Coordination**: Uses `IrealParser` and `MusicXMLParser` for imports, `ReharmManager` for logic, `VoiceLeadingOptimizer` for voicing calculation, and `HumanizedPlaybackEngine` for audio.
- **Audio Control**: Provides high-level methods for playback (play, pause, stop, toggle), sound font selection, and count-in management.
- **Data Transformation**: Bridges raw input strings to structured musical models and finally to optimized performance data.
- **Key Signature Persistence**: Ensures that the **Key Signature** (fifths/mode) parsed from MusicXML is preserved across tempo updates and reharmonization.

## Recent Features

### Count-in Support
- `isCountingIn`: Published state indicating if the engine is in count-in phase.
- `countInBeat`: Tracks current count-in beat (1, 2, 3, 4) for visual feedback.
- Synced via Combine bindings from `HumanizedPlaybackEngine`.

### Zen Mode State
- `isZenMode`: Binding-capable state used by `ContentView` and `ReharmView` to toggle distraction-free full-screen layout.
- Auto-switches to the **Reharm** tab when Zen mode is enabled.

### Improved Data Integrity
- `setProgression(_:)`: Now explicitly preserves `keySignature`.
- `updateTempo(_:)`: Recreates `ChordProgression` while keeping metadata intact.
- Reharmonization logic updated to propagate the original key to the reharmed result.

### Improved Chord Preview
- `previewStopTask`: A `DispatchWorkItem` for cancellable preview stop scheduling.
- `previewChord(at:)`: Plays a single chord with automatic stop after 2 seconds, cancelling any previous preview.

## Principal Data & State
- `originalProgression`: The primary chord chart imported by the user.
- `reharmedProgression`: The version of the chart after applying a transformation strategy.
- `currentVoicings`: The optimized MIDI realizations for each chord in the active progression.
- `playbackEngine`: An instance of `HumanizedPlaybackEngine` that handles the real-time audio thread.
- `selectedTab`: Tracks current view (Charts vs Reharm).

## Key Methods
- `importChart()`: Attempts to parse `inputText` using both iReal and simple text formats.
- `importMusicXML(from:)`: Parses a MusicXML file and sets the progression with metadata.
- `setProgression(_:)`: Updates the internal state, identifies reharmonization targets, and triggers initial voicing generation.
- `generateVoicings(for:)`: Delegates to `VoiceLeadingOptimizer` to create a smooth sequence of voicings and updates the playback engine.
- `applyReharm()`: Applies the currently selected `ReharmStrategy` from `ReharmManager` to the original progression.
- `updateTempo(_:)`: Updates the BPM and synchronizes the playback engine.
- `previewChord(at:)`: Plays a one-off realization of a specific chord in the progression for auditory feedback.
- `initializeAudio()`: Asynchronously prepares the `SoundFontManager` and `SharedAudioEngine`.

## Observables

As a `@MainActor` `ObservableObject`, it publishes updates to the UI whenever state changes, ensuring `ContentView`, `ChordInputView`, and `ReharmView` stay synchronized.

## Component Interaction

```
User Input (ChordInputView / ReharmView)
    │
    ▼
ChordViewModel
    │
    ├─▶ IrealParser.parseIrealURL() / parseSimpleChart()
    │
    ├─▶ MusicXMLParser.parse(url:)
    │
    ├─▶ VoiceLeadingOptimizer.optimizeProgression()
    │       │
    │       └─▶ VoicingGenerator.generateAllVariants()
    │
    ├─▶ ReharmManager.applyToAllDominants()
    │
    └─▶ HumanizedPlaybackEngine.setProgression() / play() / stop()
            │
            └─▶ SoundFontManager / SharedAudioEngine
```
