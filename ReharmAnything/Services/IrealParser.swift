import Foundation

// iReal Pro URL/HTML parser
class IrealParser {
    
    // Parse iReal Pro URL format
    func parseIrealURL(_ urlString: String) -> ChordProgression? {
        // iReal Pro URL format: irealb://[song data]
        guard let decoded = decodeIrealURL(urlString) else { return nil }
        return parseDecodedData(decoded)
    }
    
    // Parse iReal HTML content (from exported HTML files)
    func parseIrealHTML(_ html: String) -> [ChordProgression] {
        var progressions: [ChordProgression] = []
        
        // Extract song data from HTML
        // iReal HTML contains encoded chord data in specific format
        let pattern = #"irealb://([^"<>\s]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return progressions
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let urlRange = Range(match.range(at: 1), in: html) {
                let urlData = String(html[urlRange])
                if let decoded = decodeIrealURL("irealb://" + urlData),
                   let progression = parseDecodedData(decoded) {
                    progressions.append(progression)
                }
            }
        }
        
        return progressions
    }
    
    // Decode iReal URL encoding
    private func decodeIrealURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString),
              url.scheme == "irealb" else { return nil }
        
        var data = urlString.replacingOccurrences(of: "irealb://", with: "")
        
        // URL decode
        data = data.removingPercentEncoding ?? data
        
        // iReal uses a custom obfuscation - reverse and decode
        data = String(data.reversed())
        
        // Substitute characters
        let substitutions: [(String, String)] = [
            ("LZ", "["),
            ("XyQ", "|"),
            ("Kcl", "{")
        ]
        
        for (from, to) in substitutions {
            data = data.replacingOccurrences(of: from, with: to)
        }
        
        return data
    }
    
    // Parse decoded iReal data into chord progression
    private func parseDecodedData(_ data: String) -> ChordProgression? {
        // iReal format: Title=Composer=Style=Key=n=[chord data]
        let components = data.components(separatedBy: "=")
        guard components.count >= 6 else { return nil }
        
        let title = components[0]
        let chordData = components[5]
        
        let events = parseChordData(chordData)
        guard !events.isEmpty else { return nil }
        
        return ChordProgression(title: title, events: events, tempo: 120)
    }
    
    // Parse chord data string into chord events
    private func parseChordData(_ data: String) -> [ChordEvent] {
        var events: [ChordEvent] = []
        var currentBeat: Double = 0
        let beatsPerMeasure: Double = 4
        
        // Tokenize chord data
        let tokens = tokenizeChordData(data)
        
        for token in tokens {
            if let chord = parseChordSymbol(token) {
                events.append(ChordEvent(chord: chord, startBeat: currentBeat, duration: beatsPerMeasure))
                currentBeat += beatsPerMeasure
            }
        }
        
        return events
    }
    
    // Tokenize iReal chord data
    private func tokenizeChordData(_ data: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inBracket = false
        
        for char in data {
            switch char {
            case "[", "{":
                inBracket = true
            case "]", "}":
                inBracket = false
            case "|":
                if !current.isEmpty {
                    tokens.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }
            case " ":
                if !current.isEmpty && !inBracket {
                    tokens.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }
            default:
                current.append(char)
            }
        }
        
        if !current.isEmpty {
            tokens.append(current.trimmingCharacters(in: .whitespaces))
        }
        
        return tokens.filter { !$0.isEmpty && !isControlToken($0) }
    }
    
    private func isControlToken(_ token: String) -> Bool {
        let controlTokens = ["N1", "N2", "S", "Q", "Y", "U", "r", "p", "f", "s", "l", "n", "*A", "*B", "*C", "*D"]
        return controlTokens.contains(token) || token.hasPrefix("T") || token.hasPrefix("*")
    }
    
    // Parse a chord symbol string into a Chord object
    func parseChordSymbol(_ symbol: String) -> Chord? {
        var remaining = symbol.trimmingCharacters(in: .whitespaces)
        
        // Skip empty or control symbols
        guard !remaining.isEmpty else { return nil }
        if remaining == "x" || remaining == "n" || remaining == "W" { return nil }
        
        // Parse root note
        guard let (root, afterRoot) = parseRoot(remaining) else { return nil }
        remaining = afterRoot
        
        // Parse bass note (slash chord)
        var bass: NoteName? = nil
        if let slashIndex = remaining.firstIndex(of: "/") {
            let bassString = String(remaining[remaining.index(after: slashIndex)...])
            if let (bassNote, _) = parseRoot(bassString) {
                bass = bassNote
            }
            remaining = String(remaining[..<slashIndex])
        }
        
        // Parse quality and extensions
        let (quality, extensions) = parseQuality(remaining)
        
        return Chord(root: root, quality: quality, bass: bass, extensions: extensions)
    }
    
    // Parse root note from beginning of string
    private func parseRoot(_ str: String) -> (NoteName, String)? {
        guard !str.isEmpty else { return nil }
        
        let first = str.first!
        var rootStr = String(first)
        var remaining = String(str.dropFirst())
        
        // Check for accidental
        if !remaining.isEmpty {
            let second = remaining.first!
            if second == "b" || second == "#" {
                rootStr.append(second)
                remaining = String(remaining.dropFirst())
            }
        }
        
        guard let root = NoteName.parse(rootStr) else { return nil }
        return (root, remaining)
    }
    
    // Parse chord quality from string
    private func parseQuality(_ str: String) -> (ChordQuality, [String]) {
        var extensions: [String] = []
        
        // Match quality patterns (order matters - longer patterns first)
        let qualityPatterns: [(String, ChordQuality)] = [
            ("-7b5", .halfDiminished),
            ("m7b5", .halfDiminished),
            ("ø", .halfDiminished),
            ("dim7", .diminished7),
            ("o7", .diminished7),
            ("dim", .diminished),
            ("o", .diminished),
            ("maj9", .major9),
            ("maj7", .major7),
            ("M7", .major7),
            ("Δ7", .major7),
            ("Δ", .major7),
            ("-9", .minor9),
            ("m9", .minor9),
            ("-7", .minor7),
            ("m7", .minor7),
            ("mi7", .minor7),
            ("min7", .minor7),
            ("7alt", .altered),
            ("7#9", .altered),
            ("13", .dominant13),
            ("9", .dominant9),
            ("7", .dominant7),
            ("aug", .augmented),
            ("+", .augmented),
            ("sus4", .sus4),
            ("sus2", .sus2),
            ("sus", .sus4),
            ("-", .minor),
            ("m", .minor),
            ("mi", .minor),
            ("min", .minor),
        ]
        
        for (pattern, quality) in qualityPatterns {
            if str.hasPrefix(pattern) {
                let rest = String(str.dropFirst(pattern.count))
                if !rest.isEmpty {
                    extensions = parseExtensions(rest)
                }
                return (quality, extensions)
            }
        }
        
        // Default to major if no quality specified
        if !str.isEmpty {
            extensions = parseExtensions(str)
        }
        return (.major, extensions)
    }
    
    // Parse chord extensions like (b9), (#11), etc.
    private func parseExtensions(_ str: String) -> [String] {
        var extensions: [String] = []
        
        // Match extensions in parentheses or directly
        let extensionPattern = #"[b#]?(?:9|11|13|5)"#
        guard let regex = try? NSRegularExpression(pattern: extensionPattern, options: []) else {
            return extensions
        }
        
        let range = NSRange(str.startIndex..., in: str)
        let matches = regex.matches(in: str, options: [], range: range)
        
        for match in matches {
            if let matchRange = Range(match.range, in: str) {
                extensions.append(String(str[matchRange]))
            }
        }
        
        return extensions
    }
    
    // Identify dominant chords that are reharm targets
    func identifyReharmTargets(in progression: ChordProgression) -> [Int] {
        var targets: [Int] = []
        
        for (index, event) in progression.events.enumerated() {
            if event.chord.isDominant {
                targets.append(index)
            }
        }
        
        return targets
    }
    
    // Parse simple text chord chart (one chord per line or space-separated)
    func parseSimpleChart(_ text: String) -> ChordProgression? {
        let lines = text.components(separatedBy: .newlines)
        var events: [ChordEvent] = []
        var currentBeat: Double = 0
        let defaultDuration: Double = 4 // One measure
        
        for line in lines {
            let chords = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            for chordStr in chords {
                if let chord = parseChordSymbol(chordStr) {
                    events.append(ChordEvent(chord: chord, startBeat: currentBeat, duration: defaultDuration))
                    currentBeat += defaultDuration
                }
            }
        }
        
        guard !events.isEmpty else { return nil }
        return ChordProgression(title: "Imported Chart", events: events, tempo: 120)
    }
}

// Extension for common jazz standards parsing
extension IrealParser {
    
    // Parse common chord notation variations
    func normalizeChordSymbol(_ symbol: String) -> String {
        var normalized = symbol
        
        // Common substitutions
        let substitutions: [(String, String)] = [
            ("Maj7", "maj7"),
            ("MA7", "maj7"),
            ("Ma7", "maj7"),
            ("MIN7", "-7"),
            ("Min7", "-7"),
            ("MI7", "-7"),
            ("Mi7", "-7"),
            ("DOM7", "7"),
            ("Dom7", "7"),
            ("HALF", "-7b5"),
            ("Half", "-7b5"),
            ("DIM", "dim"),
            ("Dim", "dim"),
            ("AUG", "aug"),
            ("Aug", "aug"),
        ]
        
        for (from, to) in substitutions {
            normalized = normalized.replacingOccurrences(of: from, with: to)
        }
        
        return normalized
    }
}

