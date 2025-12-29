# ReharmAnything Project Structure

ReharmAnything is a jazz reharmonization and playback application that allows users to import chord progressions, apply various jazz reharmonization strategies, generate professional voicings with optimized voice leading, and play them back with a humanized jazz piano feel.

## Component Overview

### View Layer (`Views/`)
- `ContentView`: The main container view that manages tab navigation between the chart input and reharmonization screens.
- `ChordInputView`: Handles the input and parsing of chord charts (iReal Pro URLs, text, MusicXML files).
- `ReharmView`: Provides controls for reharmonization strategies, playback settings, and visual analysis of voicings.

### ViewModel Layer (`ViewModels/`)
- `ChordViewModel`: The central hub that orchestrates the app state. It coordinates interactions between the UI and various services like parsing, reharmonization, voicing generation, and audio playback.

### Service Layer (`Services/`)
- `IrealParser`: Responsible for parsing iReal Pro encoded data and simple text chord charts into a structured `ChordProgression`.
- `MusicXMLParser`: Parses MusicXML files (`.musicxml`, `.xml`) into chord progressions with full metadata support (time signature, sections, repeats).
- `ReharmManager`: Manages and applies reharmonization strategies (e.g., Tritone Substitution, Related ii-V) to chord progressions.
- `VoicingGenerator`: Generates professional two-hand piano voicings (Rootless A/B, Shell, Quartal, etc.) based on chord qualities.
- `VoiceLeadingOptimizer`: Optimizes the transition between voicings using a cost-function-based dynamic programming approach to ensure smooth musical movement.

### Audio Layer (`Audio/`)
- `HumanizedPlaybackEngine`: Schedules and manages the timing of MIDI events using `CADisplayLink` for drift-free playback. Supports looping, tempo, style-based humanization, and click track.
- `JazzPianoRenderer`: Renders rhythm patterns into humanized MIDI note events, applying timing jitter, velocity variation, and jazz-specific articulations like anticipation hits.
- `MusicHumanizer`: Applies humanization to note events and handles adaptive pattern selection based on chord density.
- `SoundFontManager` & `SharedAudioEngine`: Manages the loading of SoundFont (.sf2) files and handles low-level MIDI note playback via `AVAudioUnitSampler` with ADSR envelope support.
- `RhythmPatternLibrary`: A collection of predefined jazz rhythm patterns (Whole Note, Syncopated, Quarter Note, Half Note) for each style.
- `ClickSoundGenerator`: Generates metronome click sounds synchronized to the time signature.

### Model Layer (`Models/`)
- `Chord`: Defines a musical chord with root, quality, bass note, and extensions.
- `ChordProgression`: A sequence of chord events over time, with support for time signature, section markers, and repeat structures.
- `ChordEvent`: A single chord occurrence with timing, measure number, and optional section label.
- `Voicing`: A specific realization of a chord as a set of MIDI notes, often split into left and right hand parts.
- `TimeSignature`: Represents musical time signatures (4/4, 3/4, etc.) with utility methods.
- `SectionMarker` / `RepeatInfo`: Structures for chart navigation and repeat handling.

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INPUT                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │ iReal URL    │  │ Text Chart   │  │ MusicXML     │                       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                       │
└─────────┼─────────────────┼─────────────────┼───────────────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PARSING LAYER                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        ChordViewModel                                 │   │
│  │  ┌─────────────┐  ┌─────────────────┐  ┌─────────────────┐           │   │
│  │  │ IrealParser │  │ parseSimpleChart│  │ MusicXMLParser  │           │   │
│  │  └──────┬──────┘  └────────┬────────┘  └────────┬────────┘           │   │
│  │         └──────────────────┼─────────────────────┘                   │   │
│  │                            ▼                                          │   │
│  │                   ChordProgression                                    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PROCESSING LAYER                                     │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    VoiceLeadingOptimizer                              │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │ VoicingGenerator.generateAllVariants()                          │ │   │
│  │  │   → Dynamic Programming (cost function)                         │ │   │
│  │  │   → Loop Optimization                                           │ │   │
│  │  │   → Spread Normalization                                        │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  │                            ▼                                          │   │
│  │                      [Voicing]                                        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      ReharmManager (Optional)                         │   │
│  │  • TritoneSubstitution                                                │   │
│  │  • DiminishedStackStrategy                                            │   │
│  │  • RelatedIIVStrategy                                                 │   │
│  │  • BackdoorDominantStrategy                                           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PLAYBACK LAYER                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                   HumanizedPlaybackEngine                             │   │
│  │  • CADisplayLink (120Hz drift-free timing)                           │   │
│  │  • Absolute time calculation (CFAbsoluteTimeGetCurrent)              │   │
│  │  • Loop handling                                                      │   │
│  │  • Click track (ClickSoundGenerator)                                  │   │
│  │                            │                                          │   │
│  │                            ▼                                          │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │ MusicHumanizer → JazzPianoRenderer                              │ │   │
│  │  │   • Adaptive pattern selection (by chord density)               │ │   │
│  │  │   • Micro-timing jitter (Gaussian)                              │ │   │
│  │  │   • Lay-back / Push feel                                        │ │   │
│  │  │   • Chord strumming                                             │ │   │
│  │  │   • Velocity dynamics                                           │ │   │
│  │  │   • Anticipation handling (and-of-4)                            │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  │                            ▼                                          │   │
│  │                      [NoteEvent]                                      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AUDIO LAYER                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      SharedAudioEngine                                │   │
│  │  • AVAudioEngine + AVAudioUnitSampler                                │   │
│  │  • SoundFont (.sf2) loading                                          │   │
│  │  • ADSR Envelope simulation                                          │   │
│  │  • Duration-based note release scheduling                            │   │
│  │                            │                                          │   │
│  │                            ▼                                          │   │
│  │                     🔊 Audio Output                                   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Data Structures

### ChordProgression
```
ChordProgression
├── title: String
├── composer: String?
├── style: String?
├── tempo: Double (BPM)
├── timeSignature: TimeSignature (e.g., 4/4, 3/4)
├── events: [ChordEvent]
│   └── ChordEvent
│       ├── chord: Chord
│       ├── startBeat: Double
│       ├── duration: Double
│       ├── measureNumber: Int
│       └── sectionLabel: String? (A, B, C...)
├── sectionMarkers: [SectionMarker]
└── repeats: [RepeatInfo]
```

### Voicing
```
Voicing
├── chord: Chord
├── notes: [MIDINote] (all notes sorted)
├── voicingType: VoicingType
├── leftHandNotes: [MIDINote]
└── rightHandNotes: [MIDINote]
```

## Documentation Index

- [ChordViewModel.md](ChordViewModel.md) - State orchestration and service coordination
- [IrealParser.md](IrealParser.md) - iReal Pro URL/HTML decoding
- [ReharmManager.md](ReharmManager.md) - Reharmonization strategy engine
- [VoicingGenerator.md](VoicingGenerator.md) - Professional piano voicing templates
- [VoiceLeadingOptimizer.md](VoiceLeadingOptimizer.md) - Cost-based voice leading optimization
- [HumanizedPlaybackEngine.md](HumanizedPlaybackEngine.md) - Real-time playback with click track
- [JazzPianoRenderer.md](JazzPianoRenderer.md) - Humanized MIDI event generation
- [SoundFontManager.md](SoundFontManager.md) - Audio engine with ADSR envelope
- [MusicHumanizer.md](MusicHumanizer.md) - Adaptive humanization and pattern selection
- [RhythmPatternLibrary.md](RhythmPatternLibrary.md) - Rhythm pattern definitions
