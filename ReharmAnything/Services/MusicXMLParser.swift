import Foundation

// MARK: - MusicXML Parser

/// Parser for MusicXML files exported from iReal Pro
class MusicXMLParser {
    
    // MARK: - Parsing Result
    
    struct ParsedProgression {
        var title: String
        var composer: String?
        var style: String?
        var timeSignature: TimeSignature
        var divisions: Int  // Divisions per quarter note
        var events: [ChordEvent]
        var tempo: Double
        var sectionMarkers: [SectionMarker]
        var repeats: [RepeatInfo]
        
        func toChordProgression() -> ChordProgression {
            return ChordProgression(
                title: title,
                events: events,
                tempo: tempo,
                timeSignature: timeSignature,
                composer: composer,
                style: style,
                sectionMarkers: sectionMarkers,
                repeats: repeats
            )
        }
    }
    
    // MARK: - Raw Parsed Data (before expansion)
    
    struct RawMeasureData {
        var measureNumber: Int
        var chords: [(chord: Chord, positionInMeasure: Double)]  // position in beats within measure
        var sectionLabel: String?
        var isRepeatStart: Bool = false
        var isRepeatEnd: Bool = false
        var endingNumber: Int? = nil  // 1 = first ending, 2 = second ending, etc.
    }
    
    // MARK: - Public API
    
    /// Parse MusicXML file from URL
    func parse(url: URL) throws -> ParsedProgression {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }
    
    /// Parse MusicXML from Data
    func parse(data: Data) throws -> ParsedProgression {
        let parser = XMLParser(data: data)
        let delegate = MusicXMLParserDelegate()
        parser.delegate = delegate
        
        if parser.parse() {
            var result = delegate.result
            // Expand repeats to get full progression
            result = expandRepeats(result, rawMeasures: delegate.rawMeasures, timeSignature: result.timeSignature)
            return result
        } else if let error = parser.parserError {
            throw error
        } else {
            throw MusicXMLParserError.parseFailure
        }
    }
    
    /// Parse MusicXML from string
    func parse(xmlString: String) throws -> ParsedProgression {
        guard let data = xmlString.data(using: .utf8) else {
            throw MusicXMLParserError.invalidData
        }
        return try parse(data: data)
    }
    
    // MARK: - Repeat Expansion
    
    /// Expand repeats to create full linear progression
    private func expandRepeats(_ parsed: ParsedProgression, rawMeasures: [RawMeasureData], timeSignature: TimeSignature) -> ParsedProgression {
        guard !rawMeasures.isEmpty else { return parsed }
        
        var expandedEvents: [ChordEvent] = []
        var expandedSectionMarkers: [SectionMarker] = []
        var currentOutputMeasure = 1
        let beatsPerMeasure = timeSignature.beatsPerMeasure
        
        // Find repeat structures
        var repeatStart: Int? = nil
        var firstEndingMeasures: Set<Int> = []
        var secondEndingMeasures: Set<Int> = []
        var repeatEndMeasure: Int? = nil
        
        // Scan for repeat and ending markers
        for measure in rawMeasures {
            if measure.isRepeatStart {
                repeatStart = measure.measureNumber
            }
            if measure.isRepeatEnd {
                repeatEndMeasure = measure.measureNumber
            }
            if let ending = measure.endingNumber {
                if ending == 1 {
                    firstEndingMeasures.insert(measure.measureNumber)
                } else if ending == 2 {
                    secondEndingMeasures.insert(measure.measureNumber)
                }
            }
        }
        
        // Build measure lookup
        var measureLookup: [Int: RawMeasureData] = [:]
        for measure in rawMeasures {
            measureLookup[measure.measureNumber] = measure
        }
        
        let lastMeasure = rawMeasures.map { $0.measureNumber }.max() ?? 1
        
        // Helper to add a measure to output
        func addMeasure(_ measureNum: Int, outputMeasure: inout Int, addSectionLabel: Bool = true) {
            guard let measure = measureLookup[measureNum] else { return }
            
            let measureStartBeat = Double(outputMeasure - 1) * beatsPerMeasure
            
            // Add section marker if present
            if addSectionLabel, let label = measure.sectionLabel {
                expandedSectionMarkers.append(SectionMarker(label: label, measureNumber: outputMeasure))
            }
            
            // Add chords from this measure
            for (chord, posInMeasure) in measure.chords {
                let startBeat = measureStartBeat + posInMeasure
                let sectionLabel = addSectionLabel ? measure.sectionLabel : nil
                expandedEvents.append(ChordEvent(
                    chord: chord,
                    startBeat: startBeat,
                    duration: 0,  // Will be calculated later
                    measureNumber: outputMeasure,
                    sectionLabel: sectionLabel
                ))
            }
            
            outputMeasure += 1
        }
        
        // If there's a repeat structure with endings
        if let repStart = repeatStart, let repEnd = repeatEndMeasure {
            // First pass: from repeat start to repeat end, including first ending, skipping second ending
            for measureNum in repStart...repEnd {
                if secondEndingMeasures.contains(measureNum) {
                    continue  // Skip second ending on first pass
                }
                addMeasure(measureNum, outputMeasure: &currentOutputMeasure)
            }
            
            // Second pass: from repeat start, skip first ending measures, include second ending
            // Find where first ending starts (the measure before repeat end that's in first ending)
            let firstEndingStart = firstEndingMeasures.min() ?? repEnd
            
            // Play from repeat start to just before first ending
            for measureNum in repStart..<firstEndingStart {
                // Don't add section label again on repeat (already shown first time)
                addMeasure(measureNum, outputMeasure: &currentOutputMeasure, addSectionLabel: false)
            }
            
            // Now add second ending measures
            let sortedSecondEnding = secondEndingMeasures.sorted()
            for measureNum in sortedSecondEnding {
                addMeasure(measureNum, outputMeasure: &currentOutputMeasure)
            }
            
            // Find where to continue after the repeat structure
            // This is after both the repeat end and second ending
            let afterRepeatStart = max(repEnd + 1, (secondEndingMeasures.max() ?? repEnd) + 1)
            
            // Add remaining measures after the repeat structure
            if afterRepeatStart <= lastMeasure {
                for measureNum in afterRepeatStart...lastMeasure {
                    addMeasure(measureNum, outputMeasure: &currentOutputMeasure)
                }
            }
        } else {
            // No repeat structure, just add all measures linearly
            for measure in rawMeasures.sorted(by: { $0.measureNumber < $1.measureNumber }) {
                addMeasure(measure.measureNumber, outputMeasure: &currentOutputMeasure)
            }
        }
        
        // Calculate durations for each chord event
        expandedEvents = calculateDurations(expandedEvents, totalMeasures: currentOutputMeasure - 1, beatsPerMeasure: beatsPerMeasure)
        
        return ParsedProgression(
            title: parsed.title,
            composer: parsed.composer,
            style: parsed.style,
            timeSignature: parsed.timeSignature,
            divisions: parsed.divisions,
            events: expandedEvents,
            tempo: parsed.tempo,
            sectionMarkers: expandedSectionMarkers,
            repeats: []  // Repeats are now expanded
        )
    }
    
    /// Calculate duration for each chord event based on next chord's start
    private func calculateDurations(_ events: [ChordEvent], totalMeasures: Int, beatsPerMeasure: Double) -> [ChordEvent] {
        guard !events.isEmpty else { return events }
        
        var result: [ChordEvent] = []
        let totalBeats = Double(totalMeasures) * beatsPerMeasure
        
        for i in 0..<events.count {
            let event = events[i]
            let nextStartBeat: Double
            
            if i + 1 < events.count {
                nextStartBeat = events[i + 1].startBeat
            } else {
                nextStartBeat = totalBeats
            }
            
            let duration = max(nextStartBeat - event.startBeat, 0.5)
            result.append(ChordEvent(
                chord: event.chord,
                startBeat: event.startBeat,
                duration: duration,
                measureNumber: event.measureNumber,
                sectionLabel: event.sectionLabel
            ))
        }
        
        return result
    }
}

// MARK: - Parser Errors

enum MusicXMLParserError: Error {
    case invalidData
    case parseFailure
    case missingRequiredElement(String)
}

// MARK: - XML Parser Delegate

private class MusicXMLParserDelegate: NSObject, XMLParserDelegate {
    
    var result = MusicXMLParser.ParsedProgression(
        title: "Untitled",
        composer: nil,
        style: nil,
        timeSignature: .common,
        divisions: 768,
        events: [],
        tempo: 120,
        sectionMarkers: [],
        repeats: []
    )
    
    // Raw measure data for repeat expansion
    var rawMeasures: [MusicXMLParser.RawMeasureData] = []
    
    // Parsing state
    private var currentElement = ""
    private var currentText = ""
    private var inHarmony = false
    private var inAttributes = false
    private var inTime = false
    private var inRoot = false
    private var inBass = false
    private var inDegree = false
    private var inWork = false
    private var inIdentification = false
    private var inCreator = false
    private var inDirection = false
    private var inBarline = false
    private var inEnding = false
    private var creatorType = ""
    
    // Current harmony being parsed
    private var currentRootStep: String?
    private var currentRootAlter: Int = 0
    private var currentKind: String?
    private var currentKindText: String?
    private var currentBassStep: String?
    private var currentBassAlter: Int = 0
    private var currentDegrees: [(value: Int, alter: Int, type: String)] = []
    
    // Time signature parsing
    private var timeBeats: Int?
    private var timeBeatType: Int?
    
    // Position tracking
    private var currentMeasure = 0
    private var currentPositionInMeasure = 0  // In divisions
    private var currentBeat: Double = 0
    
    // Section and repeat tracking
    private var currentSectionLabel: String?
    private var repeatStartMeasure: Int?
    private var currentEndingNumber: Int?
    private var currentEndingStartMeasure: Int?
    private var pendingEndings: [RepeatInfo.Ending] = []
    
    // Current measure data being built
    private var currentMeasureData: MusicXMLParser.RawMeasureData?
    private var activeEndingNumber: Int? = nil  // Track which ending we're currently in
    
    // Previous chord for duration calculation
    private var pendingChordEvent: (chord: Chord, startBeat: Double, measureNumber: Int, sectionLabel: String?)?
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        switch elementName {
        case "work":
            inWork = true
        case "identification":
            inIdentification = true
        case "creator":
            inCreator = true
            creatorType = attributeDict["type"] ?? ""
        case "attributes":
            inAttributes = true
        case "time":
            inTime = true
        case "harmony":
            inHarmony = true
            resetCurrentHarmony()
        case "root":
            inRoot = true
        case "bass":
            inBass = true
        case "degree":
            inDegree = true
        case "direction":
            inDirection = true
        case "barline":
            inBarline = true
        case "measure":
            if let numStr = attributeDict["number"], let num = Int(numStr) {
                currentMeasure = num
                currentPositionInMeasure = 0
                // Initialize new measure data
                currentMeasureData = MusicXMLParser.RawMeasureData(
                    measureNumber: num,
                    chords: [],
                    sectionLabel: nil,
                    isRepeatStart: false,
                    isRepeatEnd: false,
                    endingNumber: activeEndingNumber  // Inherit active ending
                )
            }
        case "repeat":
            // Handle repeat markers
            if inBarline {
                let direction = attributeDict["direction"]
                if direction == "forward" {
                    repeatStartMeasure = currentMeasure
                    currentMeasureData?.isRepeatStart = true
                } else if direction == "backward" {
                    currentMeasureData?.isRepeatEnd = true
                    // End of repeat - create RepeatInfo
                    if let start = repeatStartMeasure {
                        let repeatInfo = RepeatInfo(
                            startMeasure: start,
                            endMeasure: currentMeasure,
                            times: 2,
                            endings: pendingEndings
                        )
                        result.repeats.append(repeatInfo)
                        pendingEndings = []
                        repeatStartMeasure = nil
                    }
                }
            }
        case "ending":
            // Handle first/second endings
            if inBarline {
                let endingType = attributeDict["type"]
                if endingType == "start" {
                    if let numStr = attributeDict["number"], let num = Int(numStr) {
                        currentEndingNumber = num
                        currentEndingStartMeasure = currentMeasure
                        activeEndingNumber = num
                        currentMeasureData?.endingNumber = num
                        inEnding = true
                    }
                } else if endingType == "stop" || endingType == "discontinue" {
                    // End of ending bracket
                    if let num = currentEndingNumber, let start = currentEndingStartMeasure {
                        let ending = RepeatInfo.Ending(
                            number: num,
                            startMeasure: start,
                            endMeasure: currentMeasure
                        )
                        pendingEndings.append(ending)
                    }
                    currentEndingNumber = nil
                    currentEndingStartMeasure = nil
                    activeEndingNumber = nil
                    inEnding = false
                }
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "work":
            inWork = false
        case "work-title":
            if inWork {
                result.title = text
            }
        case "identification":
            inIdentification = false
        case "creator":
            if inIdentification {
                if creatorType == "composer" {
                    result.composer = text
                } else if creatorType == "lyricist" {
                    // iReal Pro stores style in lyricist field
                    result.style = text
                }
            }
            inCreator = false
        case "divisions":
            if inAttributes, let div = Int(text) {
                result.divisions = div
            }
        case "beats":
            if inTime, let beats = Int(text) {
                timeBeats = beats
            }
        case "beat-type":
            if inTime, let beatType = Int(text) {
                timeBeatType = beatType
            }
        case "time":
            if let beats = timeBeats, let beatType = timeBeatType {
                result.timeSignature = TimeSignature(beats: beats, beatType: beatType)
            }
            inTime = false
        case "attributes":
            inAttributes = false
            
        // Rehearsal mark (section label)
        case "rehearsal":
            if inDirection && !text.isEmpty {
                currentSectionLabel = text
                currentMeasureData?.sectionLabel = text
                // Add section marker (will be recalculated after expansion)
                let marker = SectionMarker(label: text, measureNumber: currentMeasure)
                result.sectionMarkers.append(marker)
            }
            
        case "direction":
            inDirection = false
            
        case "barline":
            inBarline = false
            
        // Root parsing
        case "root-step":
            if inHarmony && inRoot {
                currentRootStep = text
            }
        case "root-alter":
            if inHarmony && inRoot, let alter = Int(text) {
                currentRootAlter = alter
            }
        case "root":
            inRoot = false
            
        // Bass parsing
        case "bass-step":
            if inHarmony && inBass {
                currentBassStep = text
            }
        case "bass-alter":
            if inHarmony && inBass, let alter = Int(text) {
                currentBassAlter = alter
            }
        case "bass":
            inBass = false
            
        // Kind parsing
        case "kind":
            if inHarmony {
                currentKind = text
            }
            
        // Degree parsing
        case "degree-value":
            if inDegree, let value = Int(text) {
                currentDegrees.append((value: value, alter: 0, type: ""))
            }
        case "degree-alter":
            if inDegree, let alter = Int(text), !currentDegrees.isEmpty {
                currentDegrees[currentDegrees.count - 1].alter = alter
            }
        case "degree-type":
            if inDegree, !currentDegrees.isEmpty {
                currentDegrees[currentDegrees.count - 1].type = text
            }
        case "degree":
            inDegree = false
            
        // Harmony complete
        case "harmony":
            finalizeHarmony()
            inHarmony = false
            
        // Note duration (advances position)
        case "duration":
            if let duration = Int(text) {
                currentPositionInMeasure += duration
            }
            
        // Measure end
        case "measure":
            // Save current measure data
            if let measureData = currentMeasureData {
                rawMeasures.append(measureData)
            }
            currentMeasureData = nil
            
            // Calculate beat position for next measure
            currentBeat = Double(currentMeasure) * result.timeSignature.beatsPerMeasure
            // Clear section label after first chord in measure
            currentSectionLabel = nil
            
        default:
            break
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // Finalize last pending chord
        if let pending = pendingChordEvent {
            let duration = currentBeat - pending.startBeat
            let event = ChordEvent(
                chord: pending.chord,
                startBeat: pending.startBeat,
                duration: max(duration, 1.0),
                measureNumber: pending.measureNumber,
                sectionLabel: pending.sectionLabel
            )
            result.events.append(event)
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetCurrentHarmony() {
        currentRootStep = nil
        currentRootAlter = 0
        currentKind = nil
        currentKindText = nil
        currentBassStep = nil
        currentBassAlter = 0
        currentDegrees = []
    }
    
    private func finalizeHarmony() {
        guard let rootStep = currentRootStep else { return }
        
        // Convert root to NoteName
        guard let root = parseNoteName(step: rootStep, alter: currentRootAlter) else { return }
        
        // Convert kind to ChordQuality
        let quality = parseChordQuality(kind: currentKind ?? "major")
        
        // Parse bass note if present
        var bass: NoteName? = nil
        if let bassStep = currentBassStep {
            bass = parseNoteName(step: bassStep, alter: currentBassAlter)
        }
        
        // Parse extensions from degrees
        let extensions = currentDegrees.compactMap { degree -> String? in
            guard degree.type == "add" || degree.type == "alter" else { return nil }
            let alterStr = degree.alter < 0 ? "b" : (degree.alter > 0 ? "#" : "")
            return "\(alterStr)\(degree.value)"
        }
        
        let chord = Chord(root: root, quality: quality, bass: bass, extensions: extensions)
        
        // Calculate position within measure in beats
        let positionInBeats = Double(currentPositionInMeasure) / Double(result.divisions)
        
        // Add chord to current measure data
        currentMeasureData?.chords.append((chord: chord, positionInMeasure: positionInBeats))
        
        // Calculate start beat for this chord (for legacy events array)
        let measureStartBeat = Double(currentMeasure - 1) * result.timeSignature.beatsPerMeasure
        let chordStartBeat = measureStartBeat + positionInBeats
        
        // Finalize previous chord with duration
        if let pending = pendingChordEvent {
            let duration = chordStartBeat - pending.startBeat
            let event = ChordEvent(
                chord: pending.chord,
                startBeat: pending.startBeat,
                duration: max(duration, 0.5),
                measureNumber: pending.measureNumber,
                sectionLabel: pending.sectionLabel
            )
            result.events.append(event)
        }
        
        // Store current chord as pending (capture section label for first chord in section)
        pendingChordEvent = (
            chord: chord,
            startBeat: chordStartBeat,
            measureNumber: currentMeasure,
            sectionLabel: currentSectionLabel
        )
        
        // Clear section label after using it
        if currentSectionLabel != nil {
            currentSectionLabel = nil
        }
    }
    
    private func parseNoteName(step: String, alter: Int) -> NoteName? {
        let noteMap: [String: Int] = [
            "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
        ]
        
        guard let basePitch = noteMap[step] else { return nil }
        let pitch = (basePitch + alter + 12) % 12
        return NoteName.from(pitchClass: pitch)
    }
    
    private func parseChordQuality(kind: String) -> ChordQuality {
        switch kind {
        case "major", "":
            return .major
        case "minor":
            return .minor
        case "dominant", "dominant-seventh":
            return .dominant7
        case "major-seventh":
            return .major7
        case "minor-seventh":
            return .minor7
        case "major-sixth":
            return .major  // Treat as major for now
        case "minor-sixth":
            return .minor
        case "diminished":
            return .diminished
        case "diminished-seventh":
            return .diminished7
        case "half-diminished":
            return .halfDiminished
        case "augmented":
            return .augmented
        case "suspended-fourth":
            return .sus4
        case "suspended-second":
            return .sus2
        case "dominant-ninth":
            return .dominant9
        case "dominant-13th":
            return .dominant13
        case "minor-ninth":
            return .minor9
        case "major-ninth":
            return .major9
        default:
            // Try to infer from kind string
            if kind.contains("minor") && kind.contains("seventh") {
                return .minor7
            } else if kind.contains("dominant") {
                return .dominant7
            } else if kind.contains("major") && kind.contains("seventh") {
                return .major7
            } else if kind.contains("minor") {
                return .minor
            }
            return .major
        }
    }
}
