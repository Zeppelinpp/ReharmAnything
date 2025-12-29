import Foundation

// Reharm strategy protocol for extensibility
protocol ReharmStrategy {
    var name: String { get }
    var description: String { get }
    func canApply(to chord: Chord) -> Bool
    func apply(to chord: Chord) -> [Chord]
}

// Tritone Substitution: Replace dominant chord with dominant chord a tritone away
// e.g., G7 -> Db7 (both share the same tritone: B-F / Cb-F)
class TritoneSubstitution: ReharmStrategy {
    let name = "Tritone Substitution"
    let description = "Replace dominant 7th with chord a tritone (b5) away"
    
    func canApply(to chord: Chord) -> Bool {
        chord.isDominant
    }
    
    func apply(to chord: Chord) -> [Chord] {
        guard canApply(to: chord) else { return [chord] }
        
        // Tritone = 6 semitones
        let newRootPitchClass = (chord.root.pitchClass + 6) % 12
        let newRoot = NoteName.from(pitchClass: newRootPitchClass)
        
        return [Chord(root: newRoot, quality: chord.quality, bass: chord.bass, extensions: chord.extensions)]
    }
}

// Diminished Principle: Dominant chord as stacked triads (POLYCHORD VOICING)
// C7 -> C + A (major triads) or C- + A- (minor triads)
// This creates a SINGLE chord with polychord voicing, NOT two separate chords in time
// The voicing is: C E G + A C# E = C A E G C# E (stacked as one harmony)
class DiminishedStackStrategy: ReharmStrategy {
    let name = "Diminished Stack"
    let description = "Polychord: Root triad + minor 3rd below triad (C7 → C+A)"
    
    enum TriadType: String, CaseIterable {
        case major = "Major"      // C + A
        case minor = "Minor"      // C- + A-
    }
    
    var triadType: TriadType = .major
    
    func canApply(to chord: Chord) -> Bool {
        chord.isDominant
    }
    
    func apply(to chord: Chord) -> [Chord] {
        guard canApply(to: chord) else { return [chord] }
        
        // Return the SAME chord - the polychord voicing is handled by VoicingGenerator
        // We mark it with an extension to indicate it should use diminished stack voicing
        return [Chord(
            root: chord.root,
            quality: chord.quality,
            bass: chord.bass,
            extensions: chord.extensions + ["dimStack"]
        )]
    }
}

// Related ii-V insertion: Add the ii chord before a dominant
// G7 -> D-7 G7
class RelatedIIVStrategy: ReharmStrategy {
    let name = "Related ii-V"
    let description = "Add related ii chord before dominant"
    
    func canApply(to chord: Chord) -> Bool {
        chord.isDominant
    }
    
    func apply(to chord: Chord) -> [Chord] {
        guard canApply(to: chord) else { return [chord] }
        
        // ii chord is a 5th above the dominant root (or 4th below)
        let iiRootPitchClass = (chord.root.pitchClass + 7) % 12 // D for G7
        let iiRoot = NoteName.from(pitchClass: iiRootPitchClass)
        
        return [
            Chord(root: iiRoot, quality: .minor7),
            chord
        ]
    }
}

// Backdoor ii-V: Replace V7 with bVII7
// G7 -> F7 (backdoor dominant)
class BackdoorDominantStrategy: ReharmStrategy {
    let name = "Backdoor Dominant"
    let description = "Replace V7 with bVII7 (backdoor resolution)"
    
    func canApply(to chord: Chord) -> Bool {
        chord.isDominant
    }
    
    func apply(to chord: Chord) -> [Chord] {
        guard canApply(to: chord) else { return [chord] }
        
        // bVII is 2 semitones below the root
        let newRootPitchClass = (chord.root.pitchClass + 10) % 12
        let newRoot = NoteName.from(pitchClass: newRootPitchClass)
        
        return [Chord(root: newRoot, quality: .dominant7)]
    }
}

// Manager for all reharm strategies
class ReharmManager: ObservableObject {
    static let shared = ReharmManager()
    
    @Published var availableStrategies: [any ReharmStrategy] = []
    @Published var selectedStrategy: (any ReharmStrategy)?
    
    private init() {
        availableStrategies = [
            TritoneSubstitution(),
            DiminishedStackStrategy(),
            RelatedIIVStrategy(),
            BackdoorDominantStrategy()
        ]
        selectedStrategy = availableStrategies.first
    }
    
    func registerStrategy(_ strategy: any ReharmStrategy) {
        availableStrategies.append(strategy)
    }
    
    func applyReharm(to progression: ChordProgression, strategy: any ReharmStrategy) -> ChordProgression {
        var newEvents: [ChordEvent] = []
        var currentBeat: Double = 0
        
        for event in progression.events {
            if strategy.canApply(to: event.chord) {
                let reharmedChords = strategy.apply(to: event.chord)
                let durationPerChord = event.duration / Double(reharmedChords.count)
                
                for (index, chord) in reharmedChords.enumerated() {
                    newEvents.append(ChordEvent(
                        chord: chord,
                        startBeat: currentBeat,
                        duration: durationPerChord,
                        measureNumber: event.measureNumber,
                        sectionLabel: index == 0 ? event.sectionLabel : nil
                    ))
                    currentBeat += durationPerChord
                }
            } else {
                newEvents.append(ChordEvent(
                    chord: event.chord,
                    startBeat: currentBeat,
                    duration: event.duration,
                    measureNumber: event.measureNumber,
                    sectionLabel: event.sectionLabel
                ))
                currentBeat += event.duration
            }
        }
        
        return ChordProgression(
            title: progression.title + " (Reharmed)",
            events: newEvents,
            tempo: progression.tempo,
            timeSignature: progression.timeSignature,
            composer: progression.composer,
            style: progression.style,
            sectionMarkers: progression.sectionMarkers,
            repeats: progression.repeats
        )
    }
    
    // Apply reharm only to dominant chords
    func applyToAllDominants(progression: ChordProgression, strategy: any ReharmStrategy) -> ChordProgression {
        var newEvents: [ChordEvent] = []
        var currentBeat: Double = 0
        
        for event in progression.events {
            if event.chord.isDominant && strategy.canApply(to: event.chord) {
                let reharmedChords = strategy.apply(to: event.chord)
                let durationPerChord = event.duration / Double(reharmedChords.count)
                
                for (index, chord) in reharmedChords.enumerated() {
                    newEvents.append(ChordEvent(
                        chord: chord,
                        startBeat: currentBeat,
                        duration: durationPerChord,
                        measureNumber: event.measureNumber,
                        sectionLabel: index == 0 ? event.sectionLabel : nil
                    ))
                    currentBeat += durationPerChord
                }
            } else {
                newEvents.append(ChordEvent(
                    chord: event.chord,
                    startBeat: currentBeat,
                    duration: event.duration,
                    measureNumber: event.measureNumber,
                    sectionLabel: event.sectionLabel
                ))
                currentBeat += event.duration
            }
        }
        
        return ChordProgression(
            title: progression.title + " (Reharmed)",
            events: newEvents,
            tempo: progression.tempo,
            timeSignature: progression.timeSignature,
            composer: progression.composer,
            style: progression.style,
            sectionMarkers: progression.sectionMarkers,
            repeats: progression.repeats
        )
    }
}

