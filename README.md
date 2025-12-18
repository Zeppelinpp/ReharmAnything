# ReharmAnything

A jazz reharmonization iOS app for musicians. Import chord charts, apply reharmonization strategies, and hear the results with optimized voice leading.

## Features

### 🎹 Sound Module
- **Grand Piano** - Classic acoustic piano sound
- **Rhodes** - Electric piano (Fender Rhodes style)
- Extensible architecture for adding more sound sources
- Uses AVAudioEngine with SoundFont (SF2) support

### 🎵 Reharm Strategies

1. **Tritone Substitution**
   - Replace dominant 7th chords with the dominant chord a tritone away
   - Example: G7 → Db7 (both share the tritone B-F)

2. **Diminished Stack**
   - Transform dominant chords into stacked triads based on diminished scale
   - Example: C7 → C + A (or C- + A-)
   - Creates rich polychordal textures

3. **Related ii-V**
   - Insert the related ii chord before a dominant
   - Example: G7 → D-7 G7

4. **Backdoor Dominant**
   - Replace V7 with bVII7 for a "backdoor" resolution
   - Example: G7 → F7

### 🎼 Voicing Generation (Voicing Dictionary)

Professional voicing templates based on jazz piano pedagogy:

- **Rootless A (Bill Evans)** - 3-5-7-9 voicing
- **Rootless B (Bill Evans)** - 7-9-3-5 voicing  
- **Quartal (McCoy Tyner)** - 四度叠置 (stacked 4ths)
- **Drop 2** - Second voice from top dropped an octave
- **Drop 3** - Third voice dropped an octave
- **Shell** - Root, 3rd, 7th (essential tones)

Each chord quality (maj7, min7, dom7, etc.) has dedicated voicing templates in the voicing dictionary.

### 🔄 Voice Leading Algorithm (Cost Function)

**Core Principle: 7th resolves to 3rd (七音连接到三音)**

The voice leading optimizer uses a sophisticated cost function:

```
Cost = Σ(Voice Motion Cost) 
     + 7→3 Resolution Bonus (半音/全音下行)
     + Common Tone Bonus (共同音保持)
     + Parallel Motion Penalty (平行五度/八度)
     + Voice Crossing Penalty
     + Range Penalty
```

**Key Features:**
- **7th to 3rd Resolution**: The dominant 7th resolving down by half/whole step to the 3rd of the next chord
- **Stepwise Motion Rewards**: Half-step motion (-3 cost), whole-step (-1 cost)
- **Common Tone Retention**: Bonus for holding notes that exist in both chords
- **Parallel 5ths/Octaves Avoidance**: Heavy penalty (+20) for parallel perfect intervals
- **Contrary Motion Bonus**: Outer voices moving in opposite directions
- **Loop Optimization**: Ensures smooth connection from last chord back to first

### 📝 iReal Pro Integration

- Parse iReal Pro URLs
- Import iReal HTML exports
- Simple text chord chart input
- Automatic dominant chord detection for reharm targeting

## Project Structure

```
ReharmAnything/
├── ReharmAnythingApp.swift      # App entry point
├── ContentView.swift            # Main tab view
├── Models/
│   └── Chord.swift              # Chord, Voicing, Progression models
├── Views/
│   ├── ChordInputView.swift     # Import/input interface
│   └── ReharmView.swift         # Main reharm interface
├── ViewModels/
│   └── ChordViewModel.swift     # Main view model
├── Services/
│   ├── ReharmStrategy.swift     # Reharm algorithms
│   ├── VoicingGenerator.swift   # Voicing generation
│   ├── VoiceLeading.swift       # Voice leading optimization
│   └── IrealParser.swift        # iReal Pro parser
├── Audio/
│   ├── AudioEngine.swift        # Playback engine
│   └── SoundFont.swift          # Sound source management
└── Assets.xcassets/             # App assets
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `ReharmAnything.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (⌘R)

### Optional: Add SoundFonts

For better sound quality, add SF2 soundfont files:
1. Download a General MIDI soundfont (e.g., FluidR3, GeneralUser GS)
2. Add the .sf2 file to the project
3. The app will automatically detect and use it

## Usage

### Import Chords

1. **Quick Start**: Tap preset progressions (ii-V-I, Autumn Leaves)
2. **Manual Input**: Type chords like `Dm7 G7 Cmaj7`
3. **iReal Pro**: Paste iReal Pro URL or import HTML

### Apply Reharm

1. Switch to the "Reharm" tab
2. View detected dominant chords (highlighted in orange)
3. Select a reharm strategy
4. Tap "Apply Reharm"
5. Listen with the play button

### Customize

- Change sound (Piano/Rhodes)
- Select voicing style
- Adjust tempo
- Toggle loop playback

## Chord Notation

Supported chord symbols:
- Major: `C`, `Cmaj7`, `CM7`, `CΔ7`
- Minor: `C-`, `Cm`, `Cmi`, `Cmin`, `C-7`, `Cm7`
- Dominant: `C7`, `C9`, `C13`
- Half-diminished: `C-7b5`, `Cm7b5`, `Cø`
- Diminished: `Cdim`, `Co`, `Cdim7`, `Co7`
- Augmented: `Caug`, `C+`
- Suspended: `Csus4`, `Csus2`
- Altered: `C7alt`, `C7#9`
- Slash chords: `C/E`, `G7/B`

## Architecture

The app follows MVVM architecture:
- **Models**: Pure data structures (Chord, Voicing, ChordProgression)
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI declarative UI
- **Services**: Domain-specific algorithms (reharm, voicing, parsing)

## Extending

### Add New Reharm Strategy

```swift
class MyCustomStrategy: ReharmStrategy {
    let name = "My Strategy"
    let description = "Description"
    
    func canApply(to chord: Chord) -> Bool {
        // Return true if strategy applies
    }
    
    func apply(to chord: Chord) -> [Chord] {
        // Return transformed chord(s)
    }
}

// Register in ReharmManager
reharmManager.registerStrategy(MyCustomStrategy())
```

### Add New Sound Source

```swift
class MySoundSource: SoundSource {
    let name = "My Sound"
    
    func loadSound() async throws { }
    func playNote(_ note: MIDINote, velocity: UInt8, channel: UInt8) { }
    func stopNote(_ note: MIDINote, channel: UInt8) { }
    func stopAllNotes() { }
}
```

## License

MIT License

## Acknowledgments

- Voice leading principles based on traditional jazz piano pedagogy
- iReal Pro format reverse-engineered for educational purposes

