# IrealParser

A service specialized in decoding and parsing chord progressions from various formats, with a focus on the iReal Pro ecosystem.

## Key Responsibilities

- **iReal URL Parsing**: Decodes the obfuscated `irealb://` protocol used by the iReal Pro app.
- **HTML Extraction**: Scans exported HTML files for embedded iReal Pro links and extracts multiple progressions.
- **Chord Symbol Analysis**: Tokenizes chord strings and decomposes them into root, quality, bass (for slash chords), and extensions.
- **Chart Import**: Provides fallback parsing for simple space-separated or line-separated text chord charts.

## Logic Details

- **Decoding**: iReal URLs use a custom obfuscation that involves percent-decoding, string reversal, and specific character substitutions (e.g., `LZ` -> `[`, `XyQ` -> `|`).
- **Tokenization**: Chord data is split by bar lines (`|`) and spaces while respecting brackets for measures and control tokens for repeats or sections.
- **Quality Mapping**: Maps string patterns (like `maj7`, `m7b5`, `7alt`) to a fixed `ChordQuality` enum, handling numerous jazz notation variations.
- **Target Identification**: Automatically identifies "reharm targets" (primarily dominant chords) in a progression.

## Key Methods

- `parseIrealURL(_:)`: Entry point for standard iReal Pro sharing links.
- `parseIrealHTML(_:)`: Utility for batch-importing from HTML exports.
- `parseChordSymbol(_:)`: The core regex-based engine that converts strings like "Dbmaj7(#11)/F" into a structured `Chord` object.
- `identifyReharmTargets(in:)`: Logic to find chords suitable for reharmonization strategies.

