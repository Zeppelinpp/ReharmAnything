import SwiftUI

struct ReharmView: View {
    @ObservedObject var viewModel: ChordViewModel
    @Binding var isZenMode: Bool
    @State private var selectedChordIndex: Int? = nil
    @Environment(\.colorScheme) var colorScheme
    
    // Get the index to display on piano: playing chord takes priority, then selected chord
    private var displayedChordIndex: Int? {
        if viewModel.isPlaying, let progression = viewModel.activeProgression {
            // Find currently playing chord index
            for (index, event) in progression.events.enumerated() {
                if viewModel.currentBeat >= event.startBeat &&
                   viewModel.currentBeat < event.startBeat + event.duration {
                    return index
                }
            }
        }
        return selectedChordIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isZenMode {
                // Zen Mode: Full screen chord view with piano
                zenModeContent
            } else {
                // Normal Mode
                normalModeContent
            }
            
            // Playback controls (always at bottom)
            playbackControlsSection
        }
        .background(NordicTheme.Dynamic.background(colorScheme))
    }
    
    // MARK: - Zen Mode Content
    
    private var zenModeContent: some View {
        VStack(spacing: 0) {
            // Minimal header in zen mode
            zenModeHeader
            
            // Full screen chord chart and piano
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Chord progression - takes most of the space
                    if let progression = viewModel.activeProgression {
                        ScrollView {
                            progressionSection(progression)
                                .id(progression.id)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .frame(height: geometry.size.height * 0.55)
                    } else {
                        Spacer()
                            .frame(height: geometry.size.height * 0.55)
                    }
                    
                    // Piano keyboard - larger in zen mode
                    if let index = displayedChordIndex,
                       !viewModel.currentVoicings.isEmpty,
                       index < viewModel.currentVoicings.count {
                        zenModePianoSection(voicing: viewModel.currentVoicings[index], chordIndex: index)
                            .frame(height: geometry.size.height * 0.45)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeInOut(duration: 0.15), value: index)
                    } else {
                        // Show empty piano when no chord selected
                        emptyPianoSection
                            .frame(height: geometry.size.height * 0.45)
                    }
                }
            }
        }
    }
    
    private var zenModeHeader: some View {
        HStack {
            // Exit zen mode button
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isZenMode = false 
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Exit")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
            
            Spacer()
            
            // Song title
            VStack(spacing: 2) {
                Text(viewModel.activeProgression?.title ?? "No Chart")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                
                // Current chord display
                if let index = displayedChordIndex,
                   let progression = viewModel.activeProgression,
                   index < progression.events.count {
                    Text(progression.events[index].chord.displayName)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(NordicTheme.Colors.primary)
                }
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NordicTheme.Dynamic.border(colorScheme))
                .frame(height: 0.5)
        }
    }
    
    private func zenModePianoSection(voicing: Voicing, chordIndex: Int) -> some View {
        VStack(spacing: 12) {
            // Chord name and voicing info
            VStack(spacing: 4) {
                Text(voicing.chord.displayName)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                
                if let voicingType = voicing.voicingType {
                    Text(voicingType.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(NordicTheme.Colors.primary)
                }
                
                // Hand separation display
                let hands = voicing.handsDescription()
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("L.H.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                        Text(hands.left.isEmpty ? "-" : hands.left)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                    }
                    VStack(spacing: 2) {
                        Text("R.H.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                        Text(hands.right.isEmpty ? "-" : hands.right)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                    }
                }
            }
            .padding(.top, 8)
            
            // Large piano keyboard
            PianoKeyboardView(highlightedNotes: Set(voicing.notes), colorScheme: colorScheme)
                .frame(height: 140)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var emptyPianoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "pianokeys")
                .font(.system(size: 48))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme).opacity(0.5))
            
            Text("Select or play a chord to see voicing")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Normal Mode Content
    
    private var normalModeContent: some View {
        VStack(spacing: 0) {
            // Header with title
            headerSection
            
            ScrollView {
                VStack(spacing: 16) {
                    // Chord progression display
                    if let progression = viewModel.activeProgression {
                        progressionSection(progression)
                            .id(progression.id)  // Force refresh when progression changes
                            .onChange(of: progression.id) { _, _ in
                                // Reset selection when progression changes
                                selectedChordIndex = nil
                            }
                    }
                    
                    // Piano keyboard for voicing visualization
                    if let index = displayedChordIndex, 
                       !viewModel.currentVoicings.isEmpty,
                       index < viewModel.currentVoicings.count {
                        pianoKeyboardSection(voicing: viewModel.currentVoicings[index], chordIndex: index)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeInOut(duration: 0.15), value: index)
                    }
                    
                    // Reharm controls
                    reharmControlsSection
                    
                    // Humanization / Feel controls
                    humanizationSection
                    
                    // Settings
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.activeProgression?.title ?? "No Chart Loaded")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            // Show style and composer if available
            if let progression = viewModel.activeProgression {
                HStack(spacing: 8) {
                    if let style = progression.style {
                        Text("(\(style))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    }
                    if let composer = progression.composer {
                        Text(composer)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    }
                }
            }
            
            if viewModel.reharmedProgression != nil {
                HStack(spacing: 5) {
                    Circle()
                        .fill(NordicTheme.Colors.highlight)
                        .frame(width: 6, height: 6)
                    Text("Reharmonized")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(NordicTheme.Colors.highlight)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NordicTheme.Dynamic.border(colorScheme))
                .frame(height: 0.5)
        }
    }
    
    private func progressionSection(_ progression: ChordProgression) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sheet music style header
            sheetMusicHeader(progression)
            
            // Chord chart with measure bars
            chordChartView(progression)
        }
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
    }
    
    /// Sheet music style header with key and tempo
    private func sheetMusicHeader(_ progression: ChordProgression) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Key center (inferred from first chord or default to C)
            VStack(alignment: .leading, spacing: 2) {
                Text("Key")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                Text(inferKeyCenter(from: progression))
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            }
            
            // Time signature
            VStack(spacing: -2) {
                Text("\(progression.timeSignature.beats)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                Text("\(progression.timeSignature.beatType)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
            }
            .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Spacer()
            
            // Tempo marking
            HStack(spacing: 4) {
                Image(systemName: "metronome")
                    .font(.system(size: 12))
                Text("♩= \(Int(progression.tempo))")
                    .font(.system(size: 13, weight: .medium, design: .serif))
            }
            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            
            // Measure count
            Text("\(progression.totalMeasures) bars")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
    }
    
    /// Get key center from progression (parsed from MusicXML or inferred)
    private func inferKeyCenter(from progression: ChordProgression) -> String {
        // Use parsed key signature if available
        if let keySignature = progression.keySignature {
            return keySignature.shortName
        }
        // Fallback: use the root of the last chord
        if let lastEvent = progression.events.last {
            return lastEvent.chord.root.rawValue
        }
        return "C"
    }
    
    /// Chord chart with measure bars, 4 measures per row
    private func chordChartView(_ progression: ChordProgression) -> some View {
        let measures = groupChordsIntoMeasures(progression)
        let rows = measures.chunked(into: 4)  // 4 measures per row
        
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { measureIndex, measure in
                        let globalMeasureIndex = rowIndex * 4 + measureIndex
                        let measureNum = globalMeasureIndex + 1
                        
                        // Get section label for this measure
                        let sectionLabel = progression.sectionLabel(forMeasure: measureNum) 
                            ?? measure.first?.sectionLabel
                        
                        MeasureCell(
                            measure: measure,
                            measureNumber: measureNum,
                            isFirstInRow: measureIndex == 0,
                            isLastInRow: measureIndex == row.count - 1,
                            playingChordIndex: currentPlayingChordIndex(in: progression),
                            selectedChordIndex: selectedChordIndex,
                            reharmTargets: viewModel.reharmTargets,
                            colorScheme: colorScheme,
                            sectionLabel: sectionLabel
                        ) { chordIndex in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedChordIndex = (selectedChordIndex == chordIndex) ? nil : chordIndex
                            }
                            viewModel.previewChord(at: chordIndex)
                        }
                    }
                    
                    // Fill empty cells if row is incomplete
                    if row.count < 4 {
                        ForEach(0..<(4 - row.count), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1.2, contentMode: .fit)
                        }
                    }
                }
                
                // Row separator (except for last row)
                if rowIndex < rows.count - 1 {
                    Rectangle()
                        .fill(NordicTheme.Dynamic.border(colorScheme))
                        .frame(height: 0.5)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    /// Group chord events into measures
    private func groupChordsIntoMeasures(_ progression: ChordProgression) -> [[MeasureChord]] {
        var measures: [[MeasureChord]] = []
        let beatsPerMeasure = progression.timeSignature.beatsPerMeasure
        
        var currentMeasure: [MeasureChord] = []
        var currentMeasureStart: Double = 0
        
        for (index, event) in progression.events.enumerated() {
            let measureIndex = Int(event.startBeat / beatsPerMeasure)
            let expectedMeasureStart = Double(measureIndex) * beatsPerMeasure
            
            // If we've moved to a new measure, save the current one
            while currentMeasureStart < expectedMeasureStart {
                if !currentMeasure.isEmpty {
                    measures.append(currentMeasure)
                    currentMeasure = []
                } else {
                    // Empty measure
                    measures.append([])
                }
                currentMeasureStart += beatsPerMeasure
            }
            
            // Calculate position within measure (in beats)
            let positionInMeasure = event.startBeat - currentMeasureStart
            let durationInMeasure = min(event.duration, beatsPerMeasure - positionInMeasure)
            
            currentMeasure.append(MeasureChord(
                chord: event.chord,
                globalIndex: index,
                positionInMeasure: positionInMeasure,
                duration: durationInMeasure,
                sectionLabel: event.sectionLabel
            ))
        }
        
        // Add final measure
        if !currentMeasure.isEmpty {
            measures.append(currentMeasure)
        }
        
        return measures
    }
    
    /// Get currently playing chord index
    private func currentPlayingChordIndex(in progression: ChordProgression) -> Int? {
        guard viewModel.isPlaying else { return nil }
        for (index, event) in progression.events.enumerated() {
            if viewModel.currentBeat >= event.startBeat &&
               viewModel.currentBeat < event.startBeat + event.duration {
                return index
            }
        }
        return nil
    }
    
    private func isChordPlaying(at index: Int, in progression: ChordProgression) -> Bool {
        guard viewModel.isPlaying else { return false }
        let event = progression.events[index]
        return viewModel.currentBeat >= event.startBeat &&
               viewModel.currentBeat < event.startBeat + event.duration
    }
    
    // Piano keyboard section
    private func pianoKeyboardSection(voicing: Voicing, chordIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Show chord name
                HStack(spacing: 6) {
                    Text(voicing.chord.root.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                    Text(voicing.chord.quality.rawValue.isEmpty ? "maj" : voicing.chord.quality.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    
                    if viewModel.isPlaying {
                        Circle()
                            .fill(NordicTheme.Colors.primary)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                Text(voicing.notesDescription())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
            
            PianoKeyboardView(highlightedNotes: Set(voicing.notes), colorScheme: colorScheme)
                .frame(height: 80)
                .id(chordIndex) // Force redraw when chord changes
        }
        .padding(16)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.isPlaying ? NordicTheme.Colors.primary.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
    
    private var reharmControlsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Strategy")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Strategy picker
            VStack(spacing: 6) {
                ForEach(Array(viewModel.strategies.enumerated()), id: \.offset) { index, strategy in
                    StrategyButton(
                        title: strategy,
                        isSelected: viewModel.selectedStrategy == index,
                        colorScheme: colorScheme
                    ) {
                        viewModel.selectedStrategy = index
                    }
                }
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.applyReharm()
                }) {
                    Text("Apply")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(NordicTheme.Colors.primary)
                        )
                        .foregroundColor(.white)
                }
                .disabled(viewModel.originalProgression == nil)
                .opacity(viewModel.originalProgression == nil ? 0.5 : 1)
                
                if viewModel.reharmedProgression != nil {
                    Button(action: {
                        viewModel.resetToOriginal()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .medium))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                            )
                            .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                    }
                }
            }
        }
        .padding(16)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Sound selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                
                HStack(spacing: 8) {
                    ForEach(SoundFontType.allCases) { type in
                        SoundButton(
                            title: type.rawValue,
                            isSelected: viewModel.selectedSoundFont == type,
                            colorScheme: colorScheme
                        ) {
                            viewModel.selectSoundFont(type)
                        }
                    }
                }
            }
            
            // Voicing type
            VStack(alignment: .leading, spacing: 8) {
                Text("Voicing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(VoicingType.allCases) { type in
                            VoicingTypeButton(
                                title: type.rawValue,
                                subtitle: type.description,
                                isSelected: viewModel.selectedVoicingType == type,
                                colorScheme: colorScheme
                            ) {
                                viewModel.changeVoicingType(type)
                            }
                        }
                    }
                }
            }
            
            // Tempo
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tempo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    Spacer()
                    Text("\(Int(viewModel.tempo))")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(NordicTheme.Colors.primary)
                    + Text(" BPM")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                }
                
                Slider(value: $viewModel.tempo, in: 40...200, step: 1)
                    .tint(NordicTheme.Colors.primary)
                    .onChange(of: viewModel.tempo) { _, newValue in
                        viewModel.updateTempo(newValue)
                    }
            }
            
            // Loop toggle
            Toggle(isOn: $viewModel.isLooping) {
                HStack(spacing: 8) {
                    Image(systemName: "repeat")
                        .font(.system(size: 14))
                    Text("Loop")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            }
            .tint(NordicTheme.Colors.tertiary)
        }
        .padding(16)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
    }
    
    // MARK: - Humanization Section
    
    private var humanizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Feel & Groove")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                // Humanization toggle
                Toggle("", isOn: Binding(
                    get: { viewModel.humanizationEnabled },
                    set: { _ in viewModel.toggleHumanization() }
                ))
                .labelsHidden()
                .tint(NordicTheme.Colors.highlight)
            }
            
            // Style selection - Dropdown Menu
            DropdownPickerRow(
                title: "Style",
                selectedValue: viewModel.selectedStyle.rawValue,
                colorScheme: colorScheme,
                accentColor: NordicTheme.Colors.highlight
            ) {
                ForEach(viewModel.availableStyles) { style in
                    Button(action: { viewModel.setMusicStyle(style) }) {
                        HStack {
                            Text(style.rawValue)
                            if viewModel.selectedStyle == style {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            // Rhythm Pattern selection - Dropdown Menu
            DropdownPickerRow(
                title: "Rhythm",
                selectedValue: selectedPatternName,
                colorScheme: colorScheme,
                accentColor: NordicTheme.Colors.highlight
            ) {
                Button(action: { viewModel.setRhythmPattern(nil) }) {
                    HStack {
                        Text("Sustained")
                        if viewModel.selectedPattern == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                ForEach(viewModel.availablePatterns) { pattern in
                    Button(action: { viewModel.setRhythmPattern(pattern) }) {
                        HStack {
                            Text(pattern.name.replacingOccurrences(of: "\(viewModel.selectedStyle.rawValue) ", with: ""))
                            if viewModel.selectedPattern?.id == pattern.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            // Feel selection - Dropdown Menu
            DropdownPickerRow(
                title: "Feel",
                selectedValue: viewModel.selectedPreset.rawValue,
                colorScheme: colorScheme,
                accentColor: NordicTheme.Colors.primary
            ) {
                ForEach(viewModel.availablePresets) { preset in
                    Button(action: { viewModel.setHumanizationPreset(preset) }) {
                        HStack {
                            Text(preset.rawValue)
                            if viewModel.selectedPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
        .opacity(viewModel.humanizationEnabled ? 1.0 : 0.6)
    }
    
    // Computed property for rhythm pattern name
    private var selectedPatternName: String {
        if let pattern = viewModel.selectedPattern {
            return pattern.name.replacingOccurrences(of: "\(viewModel.selectedStyle.rawValue) ", with: "")
        }
        return "Sustained"
    }
    
    private var playbackControlsSection: some View {
        VStack(spacing: 0) {
            // Progress bar
            if let progression = viewModel.activeProgression {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        
                        Rectangle()
                            .fill(NordicTheme.Colors.primary)
                            .frame(width: geo.size.width * (viewModel.currentBeat / max(progression.totalBeats, 1)))
                    }
                }
                .frame(height: 2)
            }
            
            // Controls - compact inline design
            HStack(spacing: 20) {
                // Stop button
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        )
                }
                
                // Play/Pause button
                Button(action: { viewModel.togglePlayback() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(viewModel.activeProgression == nil 
                                    ? NordicTheme.Dynamic.textSecondary(colorScheme)
                                    : NordicTheme.Colors.primary)
                        )
                }
                .disabled(viewModel.activeProgression == nil)
                
                // Loop button
                Button(action: { viewModel.isLooping.toggle() }) {
                    Image(systemName: "repeat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.isLooping 
                            ? NordicTheme.Colors.tertiary 
                            : NordicTheme.Dynamic.textSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(viewModel.isLooping 
                                    ? NordicTheme.Colors.tertiary.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        )
                }
                
                // Click track button
                Button(action: { viewModel.toggleClick() }) {
                    Image(systemName: "metronome")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.clickEnabled 
                            ? NordicTheme.Colors.highlight 
                            : NordicTheme.Dynamic.textSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(viewModel.clickEnabled 
                                    ? NordicTheme.Colors.highlight.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        )
                }
                
                // Zen mode button
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isZenMode.toggle() 
                    }
                }) {
                    Image(systemName: isZenMode ? "rectangle.inset.filled" : "rectangle.expand.vertical")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isZenMode 
                            ? NordicTheme.Colors.tertiary 
                            : NordicTheme.Dynamic.textSecondary(colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isZenMode 
                                    ? NordicTheme.Colors.tertiary.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        )
                }
                
                Spacer()
                
                // Tempo display
                if viewModel.activeProgression != nil {
                    Text("\(Int(viewModel.tempo)) BPM")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NordicTheme.Dynamic.border(colorScheme))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Measure Data

/// Chord within a measure
struct MeasureChord: Identifiable {
    var id: String {
        // Unique ID based on chord content, position, and extensions
        let extStr = chord.extensions.joined(separator: ",")
        return "\(globalIndex)-\(chord.root.rawValue)-\(chord.quality.rawValue)-\(extStr)"
    }
    let chord: Chord
    let globalIndex: Int
    let positionInMeasure: Double  // Position in beats from measure start
    let duration: Double           // Duration in beats
    var sectionLabel: String?      // Section marker (A, B, C, etc.)
}

// MARK: - Measure Cell View

/// A single measure cell with bar lines
struct MeasureCell: View {
    let measure: [MeasureChord]
    let measureNumber: Int
    let isFirstInRow: Bool
    let isLastInRow: Bool
    let playingChordIndex: Int?
    let selectedChordIndex: Int?
    let reharmTargets: [Int]
    let colorScheme: ColorScheme
    var sectionLabel: String?  // Section marker for this measure
    let onChordTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Left bar line (thick for first measure in row)
            Rectangle()
                .fill(NordicTheme.Dynamic.text(colorScheme))
                .frame(width: isFirstInRow ? 2 : 1)
            
            // Measure content
            VStack(spacing: 4) {
                // Section label and measure number row
                HStack(alignment: .top, spacing: 4) {
                    // Section label (A, B, C, etc.)
                    if let label = sectionLabel {
                        Text(label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(NordicTheme.Colors.primary)
                            )
                    }
                    
                    // Measure number (small, top-left)
                    Text("\(measureNumber)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    
                    Spacer()
                }
                
                // Chords in measure
                if measure.isEmpty {
                    // Empty measure - show rest or repeat
                    Text("%")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if measure.count == 1 {
                    // Single chord - centered
                    singleChordView(measure[0])
                        .id(measure[0].id)  // Force refresh when chord changes
                } else {
                    // Multiple chords - split horizontally
                    HStack(spacing: 2) {
                        ForEach(measure) { measureChord in
                            chordInMeasureView(measureChord)
                                .id(measureChord.id)  // Force refresh when chord changes
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.2, contentMode: .fit)
            
            // Right bar line (thick for last measure in row)
            Rectangle()
                .fill(NordicTheme.Dynamic.text(colorScheme))
                .frame(width: isLastInRow ? 2 : 1)
        }
    }
    
    private func singleChordView(_ measureChord: MeasureChord) -> some View {
        let isPlaying = playingChordIndex == measureChord.globalIndex
        let isSelected = selectedChordIndex == measureChord.globalIndex
        let isTarget = reharmTargets.contains(measureChord.globalIndex)
        let isPolychord = measureChord.chord.extensions.contains("dimStack") && measureChord.chord.quality.isDominant
        
        return Button(action: { onChordTap(measureChord.globalIndex) }) {
            Group {
                if isPolychord {
                    // Polychord display: Root triad over lower triad (minor 3rd below)
                    let lowerRootPitchClass = (measureChord.chord.root.pitchClass - 3 + 12) % 12
                    let lowerRoot = NoteName.from(pitchClass: lowerRootPitchClass)
                    
                    VStack(spacing: 0) {
                        Text(measureChord.chord.root.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Rectangle()
                            .fill(chordTextColor(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget).opacity(0.5))
                            .frame(width: 20, height: 1)
                            .padding(.vertical, 1)
                        Text(lowerRoot.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                } else {
                    VStack(spacing: 1) {
                        Text(measureChord.chord.root.rawValue)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Text(measureChord.chord.quality.rawValue.isEmpty ? "" : measureChord.chord.quality.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            }
            .foregroundColor(chordTextColor(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(chordBackground(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget))
            .cornerRadius(6)
            .scaleEffect(isPlaying ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPlaying)
        }
        .buttonStyle(.plain)
    }
    
    private func chordInMeasureView(_ measureChord: MeasureChord) -> some View {
        let isPlaying = playingChordIndex == measureChord.globalIndex
        let isSelected = selectedChordIndex == measureChord.globalIndex
        let isTarget = reharmTargets.contains(measureChord.globalIndex)
        let isPolychord = measureChord.chord.extensions.contains("dimStack") && measureChord.chord.quality.isDominant
        
        return Button(action: { onChordTap(measureChord.globalIndex) }) {
            Group {
                if isPolychord {
                    // Polychord display: Root triad over lower triad (minor 3rd below)
                    let lowerRootPitchClass = (measureChord.chord.root.pitchClass - 3 + 12) % 12
                    let lowerRoot = NoteName.from(pitchClass: lowerRootPitchClass)
                    
                    VStack(spacing: 0) {
                        Text(measureChord.chord.root.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Rectangle()
                            .fill(chordTextColor(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget).opacity(0.5))
                            .frame(width: 16, height: 1)
                        Text(lowerRoot.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                } else {
                    VStack(spacing: 0) {
                        Text(measureChord.chord.root.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(measureChord.chord.quality.rawValue.isEmpty ? "" : measureChord.chord.quality.rawValue)
                            .font(.system(size: 8, weight: .medium))
                    }
                }
            }
            .foregroundColor(chordTextColor(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(chordBackground(isPlaying: isPlaying, isSelected: isSelected, isTarget: isTarget))
            .cornerRadius(4)
            .scaleEffect(isPlaying ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPlaying)
        }
        .buttonStyle(.plain)
    }
    
    private func chordTextColor(isPlaying: Bool, isSelected: Bool, isTarget: Bool) -> Color {
        if isPlaying {
            return .white
        }
        return NordicTheme.Dynamic.text(colorScheme)
    }
    
    private func chordBackground(isPlaying: Bool, isSelected: Bool, isTarget: Bool) -> Color {
        if isPlaying {
            return NordicTheme.Colors.primary
        } else if isSelected {
            return NordicTheme.Colors.highlight.opacity(colorScheme == .dark ? 0.3 : 0.2)
        } else if isTarget {
            return NordicTheme.Colors.warning.opacity(colorScheme == .dark ? 0.2 : 0.12)
        }
        return Color.clear
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Supporting Views

struct ChordCell: View {
    let chord: Chord
    let isReharmTarget: Bool
    let isPlaying: Bool
    var isSelected: Bool = false
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    private var isPolychord: Bool {
        chord.extensions.contains("dimStack") && chord.quality.isDominant
    }
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if isPolychord {
                    polychordView
                } else {
                    standardChordView
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: (isPlaying || isSelected) ? 1.5 : 0.5)
            )
            .scaleEffect(isPlaying ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPlaying)
        }
        .buttonStyle(.plain)
    }
    
    private var standardChordView: some View {
        VStack(spacing: 2) {
            Text(chord.root.rawValue)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Text(chord.quality.rawValue.isEmpty ? "maj" : chord.quality.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
    }
    
    private var polychordView: some View {
        // Lower triad is minor 3rd below root (root - 3 semitones)
        // C7 -> C triad + A triad, display as C/A
        let lowerRootPitchClass = (chord.root.pitchClass - 3 + 12) % 12
        let lowerRoot = NoteName.from(pitchClass: lowerRootPitchClass)
        
        return VStack(spacing: 0) {
            // Root triad on top
            Text(chord.root.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Rectangle()
                .fill(NordicTheme.Dynamic.textSecondary(colorScheme))
                .frame(width: 24, height: 1)
                .padding(.vertical, 2)
            
            // Lower triad (minor 3rd below root)
            Text(lowerRoot.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
        }
    }
    
    private var backgroundColor: Color {
        if isPlaying {
            return NordicTheme.Colors.primary.opacity(colorScheme == .dark ? 0.25 : 0.12)
        } else if isSelected {
            return NordicTheme.Colors.highlight.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if isReharmTarget {
            return NordicTheme.Colors.warning.opacity(colorScheme == .dark ? 0.15 : 0.08)
        }
        return NordicTheme.Dynamic.surfaceSecondary(colorScheme)
    }
    
    private var borderColor: Color {
        if isPlaying {
            return NordicTheme.Colors.primary
        } else if isSelected {
            return NordicTheme.Colors.highlight
        } else if isReharmTarget {
            return NordicTheme.Colors.warning.opacity(0.4)
        }
        return NordicTheme.Dynamic.border(colorScheme)
    }
}

struct StrategyButton: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(isSelected ? NordicTheme.Colors.primary : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected 
                                ? NordicTheme.Colors.primary 
                                : NordicTheme.Dynamic.textSecondary(colorScheme), lineWidth: 1)
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected 
                        ? NordicTheme.Colors.primary.opacity(colorScheme == .dark ? 0.15 : 0.08)
                        : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}

struct SoundButton: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected 
                            ? NordicTheme.Colors.primary 
                            : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                )
                .foregroundColor(isSelected ? .white : NordicTheme.Dynamic.text(colorScheme))
        }
        .buttonStyle(.plain)
    }
}

struct VoicingTypeButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected 
                        ? NordicTheme.Colors.tertiary 
                        : NordicTheme.Dynamic.text(colorScheme))
                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected 
                        ? NordicTheme.Colors.tertiary.opacity(colorScheme == .dark ? 0.2 : 0.1)
                        : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? NordicTheme.Colors.tertiary.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// Dropdown Picker Row - expandable menu selector
struct DropdownPickerRow<MenuContent: View>: View {
    let title: String
    let selectedValue: String
    let colorScheme: ColorScheme
    var accentColor: Color = NordicTheme.Colors.primary
    @ViewBuilder let menuContent: () -> MenuContent
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Spacer()
            
            Menu {
                menuContent()
            } label: {
                HStack(spacing: 6) {
                    Text(selectedValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
            }
        }
        .padding(.vertical, 4)
    }
}


// Piano keyboard view
struct PianoKeyboardView: View {
    let highlightedNotes: Set<MIDINote>
    let colorScheme: ColorScheme
    
    // Expand range to cover typical voicing range: C2 (36) to C6 (84)
    private let startNote = 36
    private let endNote = 84
    private let whiteKeyOffsets = [0, 2, 4, 5, 7, 9, 11]
    
    var body: some View {
        GeometryReader { geo in
            let whiteKeyCount = countWhiteKeys()
            let whiteKeyWidth = geo.size.width / CGFloat(whiteKeyCount)
            let blackKeyWidth = whiteKeyWidth * 0.58
            let blackKeyHeight = geo.size.height * 0.58
            
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 1) {
                    ForEach(whiteKeys(), id: \.self) { midi in
                        whiteKey(midi: midi, width: whiteKeyWidth - 1, height: geo.size.height)
                    }
                }
                
                // Black keys
                ForEach(blackKeys(), id: \.midi) { key in
                    blackKey(midi: key.midi, width: blackKeyWidth, height: blackKeyHeight)
                        .offset(x: CGFloat(key.position) * whiteKeyWidth - blackKeyWidth / 2 + 0.5)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
    }
    
    private func countWhiteKeys() -> Int {
        (startNote..<endNote).filter { isWhiteKey($0) }.count
    }
    
    private func whiteKeys() -> [MIDINote] {
        (startNote..<endNote).filter { isWhiteKey($0) }
    }
    
    private func blackKeys() -> [(midi: MIDINote, position: Int)] {
        var result: [(midi: MIDINote, position: Int)] = []
        var whiteKeyIndex = 0
        
        for midi in startNote..<endNote {
            if isWhiteKey(midi) {
                whiteKeyIndex += 1
            } else {
                result.append((midi: midi, position: whiteKeyIndex))
            }
        }
        return result
    }
    
    private func isWhiteKey(_ midi: MIDINote) -> Bool {
        whiteKeyOffsets.contains(midi % 12)
    }
    
    private func whiteKey(midi: MIDINote, width: CGFloat, height: CGFloat) -> some View {
        let isHighlighted = highlightedNotes.contains(midi)
        
        return Rectangle()
            .fill(isHighlighted 
                ? NordicTheme.Colors.primary 
                : (colorScheme == .dark 
                    ? Color(white: 0.92) 
                    : Color.white))
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
            )
            .overlay(alignment: .bottom) {
                if isHighlighted {
                    Text(noteNameShort(midi))
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.bottom, 3)
                }
            }
    }
    
    private func blackKey(midi: MIDINote, width: CGFloat, height: CGFloat) -> some View {
        let isHighlighted = highlightedNotes.contains(midi)
        
        return Rectangle()
            .fill(isHighlighted 
                ? NordicTheme.Colors.highlight 
                : (colorScheme == .dark 
                    ? Color(white: 0.18) 
                    : Color(white: 0.12)))
            .frame(width: width, height: height)
            .cornerRadius(2, corners: [.bottomLeft, .bottomRight])
            .overlay(alignment: .bottom) {
                if isHighlighted {
                    Text(noteNameShort(midi))
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                }
            }
    }
    
    private func noteNameShort(_ midi: MIDINote) -> String {
        let noteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        return noteNames[midi % 12]
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ReharmView(viewModel: ChordViewModel())
}
