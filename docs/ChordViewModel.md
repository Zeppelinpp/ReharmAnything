# ChordViewModel

The central orchestrator for the ReharmAnything application. It manages the application state, handles user interactions, and coordinates data flow between services.

## Key Responsibilities

- **State Management**: Maintains the original and reharmonized chord progressions, current voicings, playback state (tempo, current beat, isPlaying), and UI-related flags.
- **Service Coordination**: Uses `IrealParser` and `MusicXMLParser` for imports, `ReharmManager` for logic, `VoiceLeadingOptimizer` for voicing calculation, and `HumanizedPlaybackEngine` for audio.
- **Audio Control**: Provides high-level methods for playback (play, pause, stop, toggle), sound font selection, and click track toggling.
- **Data Transformation**: Bridges raw input strings to structured musical models and finally to optimized performance data.
- **Recent Imports Management**: Tracks and persists recently imported files for quick re-access.

## New Features

### MusicXML Import

- `musicXMLParser`: Instance of `MusicXMLParser` for parsing `.musicxml` and `.xml` files.
- `importMusicXML(from:)`: Handles security-scoped file access, parses the file, and converts to `ChordProgression`.
- `showingFilePicker`: Controls the document picker UI.

### Recent Imports

- `RecentImport`: A `Codable` struct storing file name, title, import date, and bookmark data.
- `recentImports`: Published array of recent imports (max 10).
- `addRecentImport(...)` / `removeRecentImport(...)` / `clearRecentImports()`: Management methods.
- `importFromRecent(_:)`: Re-imports from a saved bookmark.
- Persisted to `UserDefaults` via `recentImportsKey`.

### Click Track Control

- `clickEnabled`: Published state for metronome toggle.
- `toggleClick()`: Toggles click and syncs with `HumanizedPlaybackEngine`.

### Improved Chord Preview

- `previewStopTask`: A `DispatchWorkItem` for cancellable preview stop scheduling.
- `previewChord(at:)`: Plays a single chord with automatic stop after 2 seconds, cancelling any previous preview.

## Principal Data & State

- `originalProgression`: The primary chord chart imported by the user.
- `reharmedProgression`: The version of the chart after applying a transformation strategy.
- `currentVoicings`: The optimized MIDI realizations for each chord in the active progression.
- `playbackEngine`: An instance of `HumanizedPlaybackEngine` that handles the real-time audio thread.

## Key Methods

- `importChart()`: Attempts to parse `inputText` using both iReal and simple text formats.
- `importMusicXML(from:)`: Parses a MusicXML file and sets the progression.
- `setProgression(_:)`: Updates the internal state, identifies reharmonization targets, and triggers initial voicing generation.
- `generateVoicings(for:)`: Delegates to `VoiceLeadingOptimizer` to create a smooth sequence of voicings and updates the playback engine.
- `applyReharm()`: Applies the currently selected `ReharmStrategy` from `ReharmManager` to the original progression.
- `updateTempo(_:)`: Updates the BPM and synchronizes the playback engine.
- `previewChord(at:)`: Plays a one-off realization of a specific chord in the progression for auditory feedback.

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
