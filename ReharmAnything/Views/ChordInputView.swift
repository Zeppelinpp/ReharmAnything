import SwiftUI
import UniformTypeIdentifiers

struct ChordInputView: View {
    @ObservedObject var viewModel: ChordViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Spacer()
            
            // Import button
            importSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Quick load section
            quickLoadSection
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Error message
            if let error = viewModel.importError {
                errorSection(error)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
            
            // Status indicator
            if viewModel.originalProgression != nil {
                loadedStatusSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .background(NordicTheme.Dynamic.background(colorScheme))
        .fileImporter(
            isPresented: $viewModel.showingFilePicker,
            allowedContentTypes: [.xml, UTType(filenameExtension: "musicxml") ?? .xml],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importMusicXML(from: url)
                }
            case .failure(let error):
                viewModel.importError = error.localizedDescription
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Minimal icon
            Image(systemName: "music.note.list")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(NordicTheme.Colors.primary)
                .padding(.bottom, 4)
            
            Text("Select a Chart")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Text("Import MusicXML or choose a standard")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
    
    private var importSection: some View {
        Button(action: {
            viewModel.showMusicXMLPicker()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 20, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import MusicXML")
                        .font(.system(size: 15, weight: .semibold))
                    Text("From iReal Pro or other apps")
                        .font(.system(size: 12, weight: .regular))
                        .opacity(0.8)
                }
                
                Spacer()
                
                if viewModel.isImporting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(NordicTheme.Colors.primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isImporting)
    }
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(NordicTheme.Colors.error)
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(NordicTheme.Colors.error)
            
            Spacer()
            
            Button(action: {
                viewModel.importError = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(NordicTheme.Colors.error.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var quickLoadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recent imports section
            if !viewModel.recentImports.isEmpty {
                recentImportsSection
            }
            
            Text("Standards")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 10) {
                ProgressionCard(
                    title: "ii-V-I",
                    subtitle: "Basic cadence in C major",
                    colorScheme: colorScheme
                ) {
                    viewModel.loadSampleProgression()
                }
                
                ProgressionCard(
                    title: "Autumn Leaves",
                    subtitle: "A section (8 bars)",
                    colorScheme: colorScheme
                ) {
                    viewModel.loadAutumnLeaves()
                }
                
                ProgressionCard(
                    title: "All The Things You Are",
                    subtitle: "A section (8 bars)",
                    colorScheme: colorScheme
                ) {
                    viewModel.loadAllTheThings()
                }
            }
        }
        .padding(20)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .cornerRadius(12)
    }
    
    private var recentImportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Button(action: {
                    viewModel.clearRecentImports()
                }) {
                    Text("Clear")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NordicTheme.Colors.primary)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentImports.prefix(3)) { recent in
                    RecentImportCard(
                        recent: recent,
                        colorScheme: colorScheme,
                        onTap: {
                            viewModel.importFromRecent(recent)
                        },
                        onDelete: {
                            viewModel.removeRecentImport(recent)
                        }
                    )
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    private var loadedStatusSection: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(NordicTheme.Colors.success)
                .frame(width: 8, height: 8)
            
            Text(viewModel.originalProgression?.title ?? "Loaded")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("Swipe to Reharm")
                    .font(.system(size: 12, weight: .regular))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(NordicTheme.Colors.success.opacity(colorScheme == .dark ? 0.15 : 0.08))
        .cornerRadius(10)
    }
}

struct ProgressionCard: View {
    let title: String
    let subtitle: String
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct RecentImportCard: View {
    let recent: RecentImport
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: recent.importDate, relativeTo: Date())
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(NordicTheme.Colors.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recent.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(recent.fileName)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                            .lineLimit(1)
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                        
                        Text(formattedDate)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme).opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(NordicTheme.Colors.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChordInputView(viewModel: ChordViewModel())
}
