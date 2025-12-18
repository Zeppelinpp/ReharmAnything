import SwiftUI

struct ReharmView: View {
    @ObservedObject var viewModel: ChordViewModel
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
            // Header with title
            headerSection
            
            ScrollView {
                VStack(spacing: 16) {
                    // Chord progression display
                    if let progression = viewModel.activeProgression {
                        progressionSection(progression)
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
                    
                    // Settings
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Playback controls
            playbackControlsSection
        }
        .background(NordicTheme.Dynamic.background(colorScheme))
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.activeProgression?.title ?? "No Chart Loaded")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progression")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Text("\(progression.events.count) chords")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
            
            // Chord grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Array(progression.events.enumerated()), id: \.element.id) { index, event in
                    ChordCell(
                        chord: event.chord,
                        isReharmTarget: viewModel.reharmTargets.contains(index),
                        isPlaying: isChordPlaying(at: index, in: progression),
                        isSelected: selectedChordIndex == index,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedChordIndex = (selectedChordIndex == index) ? nil : index
                        }
                        viewModel.previewChord(at: index)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(viewModel.isPlaying ? NordicTheme.Colors.primary.opacity(0.5) : NordicTheme.Dynamic.border(colorScheme), lineWidth: viewModel.isPlaying ? 1 : 0.5)
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
    }
    
    private var playbackControlsSection: some View {
        VStack(spacing: 10) {
            // Progress bar
            if let progression = viewModel.activeProgression {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(NordicTheme.Colors.primary)
                            .frame(width: geo.size.width * (viewModel.currentBeat / max(progression.totalBeats, 1)))
                    }
                }
                .frame(height: 3)
            }
            
            // Controls
            HStack(spacing: 28) {
                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                }
                
                Button(action: { viewModel.togglePlayback() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(NordicTheme.Colors.primary)
                }
                .disabled(viewModel.activeProgression == nil)
                .opacity(viewModel.activeProgression == nil ? 0.4 : 1)
                
                Button(action: { viewModel.isLooping.toggle() }) {
                    Image(systemName: "repeat")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.isLooping 
                            ? NordicTheme.Colors.tertiary 
                            : NordicTheme.Dynamic.textSecondary(colorScheme))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NordicTheme.Dynamic.border(colorScheme))
                .frame(height: 0.5)
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
        let upperRootPitchClass = (chord.root.pitchClass + 4) % 12
        let upperRoot = NoteName.from(pitchClass: upperRootPitchClass)
        
        return VStack(spacing: 0) {
            Text(upperRoot.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Rectangle()
                .fill(NordicTheme.Dynamic.textSecondary(colorScheme))
                .frame(width: 24, height: 1)
                .padding(.vertical, 2)
            
            Text(chord.root.rawValue)
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
