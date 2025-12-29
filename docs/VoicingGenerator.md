# VoicingGenerator

A foundational service for constructing professional-grade piano voicings from chord symbols.

## Key Responsibilities

- **Template Dictionary**: Stores a library of professional "templates" for different chord qualities and voicing styles.
- **Two-Hand Splitting**: Explicitly defines left-hand and right-hand components for realistic piano performance.
- **Register Management**: Automatically finds the best octaves to place voicings around typical piano registers (e.g., C3 for LH, E4 for RH).
- **Variant Generation**: Can generate multiple octave-shifted and transformed versions of a voicing for optimization purposes.

## Supported Voicing Types

- **Rootless A/B**: Classic Bill Evans style voicings (3-5-7-9 or 7-9-3-5 stacks).
- **Shell**: Minimalist voicings focusing on the root and "shell" (3rd and 7th).
- **Quartal**: McCoy Tyner style stacks built primarily on perfect fourths.
- **Drop 2 / Drop 3**: Open position voicings derived by dropping voices from a closed stack.
- **Diminished Stack**: Special polychord realizations for dominant chords.

## Technical Details

- **Pitch Class Arithmetic**: Uses semitone-based intervals from the root to calculate MIDI notes.
- **Fallback Logic**: Provides basic realizations if a complex template isn't available for a specific quality.
- **Cluster Control**: Includes logic to count and limit "clusters" (intervals of a major/minor 2nd) for better clarity.
- **Transformations**: Supports inversions and transpositions while respecting the physical range of a standard piano (MIDI 36-96).

