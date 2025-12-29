# ReharmAnything Project Structure

ReharmAnything is a jazz reharmonization and playback application that allows users to import chord progressions, apply various jazz reharmonization strategies, generate professional voicings with optimized voice leading, and play them back with a humanized jazz piano feel.

## Component Overview

### View Layer (`Views/`)
- `ContentView`: The main container view that manages tab navigation between the chart input and reharmonization screens.
- `ChordInputView`: Handles the input and parsing of chord charts (iReal Pro URLs, text, etc.).
- `ReharmView`: Provides controls for reharmonization strategies, playback settings, and visual analysis of voicings.

### ViewModel Layer (`ViewModels/`)
- `ChordViewModel`: The central hub that orchestrates the app state. It coordinates interactions between the UI and various services like parsing, reharmonization, voicing generation, and audio playback.

### Service Layer (`Services/`)
- `IrealParser`: Responsible for parsing iReal Pro encoded data and simple text chord charts into a structured `ChordProgression`.
- `ReharmManager`: Manages and applies reharmonization strategies (e.g., Tritone Substitution, Related ii-V) to chord progressions.
- `VoicingGenerator`: Generates professional two-hand piano voicings (Rootless A/B, Shell, Quartal, etc.) based on chord qualities.
- `VoiceLeadingOptimizer`: Optimizes the transition between voicings using a cost-function-based dynamic programming approach to ensure smooth musical movement.

### Audio Layer (`Audio/`)
- `HumanizedPlaybackEngine`: Schedules and manages the timing of MIDI events with support for looping, tempo, and style-based humanization.
- `JazzPianoRenderer`: Renders rhythm patterns into humanized MIDI note events, applying timing jitter, velocity variation, and jazz-specific articulations like anticipation hits.
- `SoundFontManager` & `SharedAudioEngine`: Manages the loading of SoundFont (.sf2) files and handles low-level MIDI note playback via `AVAudioUnitSampler`.
- `RhythmPatternLibrary`: A collection of predefined jazz rhythm patterns (Swing, Bossa, Ballad, etc.).

### Model Layer (`Models/`)
- `Chord`: Defines a musical chord with root, quality, bass note, and extensions.
- `ChordProgression`: A sequence of chord events over time.
- `Voicing`: A specific realization of a chord as a set of MIDI notes, often split into left and right hand parts.

## Data Flow

1. **Import & Parsing**: 
   `ChordInputView` -> `ChordViewModel.importChart()` -> `IrealParser` -> `ChordProgression`.
2. **Voicing Optimization**: 
   `ChordViewModel` -> `VoiceLeadingOptimizer.optimizeProgression()` (uses `VoicingGenerator`) -> `[Voicing]`.
3. **Reharmonization**: 
   `ReharmView` -> `ChordViewModel.applyReharm()` -> `ReharmManager` -> Modified `ChordProgression`.
4. **Playback Execution**: 
   `ChordViewModel.play()` -> `HumanizedPlaybackEngine` -> `JazzPianoRenderer` -> `[NoteEvent]`.
5. **Audio Output**: 
   `HumanizedPlaybackEngine` -> `SoundFontManager` -> `SharedAudioEngine` -> Sound Output.

## Documentation Index

- [ChordViewModel.md](docs/ChordViewModel.md)
- [IrealParser.md](docs/IrealParser.md)
- [ReharmManager.md](docs/ReharmManager.md)
- [VoicingGenerator.md](docs/VoicingGenerator.md)
- [VoiceLeadingOptimizer.md](docs/VoiceLeadingOptimizer.md)
- [HumanizedPlaybackEngine.md](docs/HumanizedPlaybackEngine.md)
- [JazzPianoRenderer.md](docs/JazzPianoRenderer.md)
- [SoundFontManager.md](docs/SoundFontManager.md)
