# ReharmAnything Project Structure

ReharmAnything is a jazz reharmonization and playback application that allows users to import chord progressions, apply various jazz reharmonization strategies, generate professional voicings with optimized voice leading, and play them back with a humanized jazz piano feel.

## Component Overview

### View Layer (`Views/`)
- `ContentView`: The main container view that manages tab navigation. Now includes `isZenMode` state to hide headers/tab-bars.
- `ChordInputView`: Handles the input and parsing of chord charts. Includes a scrollable recent imports list.
- `ReharmView`: Provides controls for reharmonization and playback.
  - **Zen Mode**: A distraction-free full-screen mode with auto-scrolling chord chart and enlarged piano keyboard.
  - **Dropdown Selection**: Menu-based pickers for Style, Rhythm, and Feel.

### ViewModel Layer (`ViewModels/`)
- `ChordViewModel`: Orchestrates app state. Now tracks **count-in state**, **Zen mode state**, and maintains **Key Signature** through reharmonization.

### Service Layer (`Services/`)
- `IrealParser`: Responsible for parsing iReal Pro encoded data.
- `MusicXMLParser`: Parses MusicXML files, now with full **Key Signature (fifths/mode)** support.
- `ReharmManager`: Manages reharmonization strategies.
- `VoicingGenerator`: Generates professional two-hand piano voicings.
- `VoiceLeadingOptimizer`: Optimizes voicing transitions using dynamic programming.

### Audio Layer (`Audio/`)
- `HumanizedPlaybackEngine`: High-precision playback using `CADisplayLink`. Now includes **Count-in (pre-roll)** logic based on time signature.
- `MusicHumanizer`: Applies timing jitter and adaptive pattern selection. Weighted probabilities now favor **Whole Note** (sustained) for single-chord measures.
- `RhythmPatternLibrary`: Defines music styles and rhythmic templates.
- `SoundFontManager` & `SharedAudioEngine`: Low-level MIDI playback with ADSR envelope simulation.

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
│  │  │ MusicHumanizer                                                  │ │   │
│  │  │   • Adaptive pattern selection (by chord density)               │ │   │
│  │  │   • Micro-timing jitter                                         │ │   │
│  │  │   • Velocity dynamics & accents                                 │ │   │
│  │  │   • Hand separation                                             │ │   │
│  │  │   • Chord rolling (optional)                                    │ │   │
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
- [MusicHumanizer.md](MusicHumanizer.md) - Adaptive humanization and pattern selection
- [RhythmPatternLibrary.md](RhythmPatternLibrary.md) - Rhythm pattern definitions and music styles
- [SoundFontManager.md](SoundFontManager.md) - Audio engine with ADSR envelope
- [MusicXMLParser.md](MusicXMLParser.md) - MusicXML file parsing with repeat expansion
