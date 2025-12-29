# JazzPianoRenderer

The core engine for transforming static chord voicings into expressive, humanized musical performances.

## Key Responsibilities

- **Micro-timing Jitter**: Adds subtle, Gaussian-distributed variations to note start times to simulate human fallibility.
- **Lay-back & Push**: Adjusts the timing relative to the beat to create "feel" (e.g., jazz lay-back or funk pushing).
- **Strumming (Rolling)**: Simulates the physical action of a pianist's hands by slightly staggering note onset times within a chord.
- **Velocity Dynamics**: Applies realistic velocity variations, including melody accents, register-based brightness (pitch bias), and softer left-hand touches.
- **Anticipation Handling**: Implements the crucial jazz concept of "anticipation hits" (and-of-4), where the *next* chord is played slightly before the bar line and tied over.

## Configuration Presets

The renderer uses `JazzRendererConfig` to define its personality:
- **Swing**: Moderate jitter and lay-back, with standard strumming.
- **Ballad**: Slower strumming, higher velocity variation, and more legato.
- **Funk**: Very tight timing, slightly ahead of the beat (pushing), and staccato articulation.
- **Robotic**: Zero jitter, perfect timing, and fixed velocity for testing purposes.

## Core Rendering Algorithm

1. **Anticipation Pass**: Analyzes the rhythm pattern to identify hits that should use the *next* chord's voicing.
2. **Hit Detection**: Iterates through rhythm patterns, identifying which notes from the voicing to play (bass only, top note, full chord, etc.).
3. **Humanization Logic**: 
   - Calculates a shared `chordTimingOffset`.
   - Calculates individual `strumDelay` for each note.
   - Computes velocity based on base velocity + pitch bias + hand reduction + random jitter.
4. **NoteEvent Creation**: Produces a list of `NoteEvent` objects containing MIDI note, velocity, exact position (in beats), and duration.

