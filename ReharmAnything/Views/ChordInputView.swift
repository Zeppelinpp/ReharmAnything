import SwiftUI

struct ChordInputView: View {
    @ObservedObject var viewModel: ChordViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Spacer()
            
            // Quick load section
            quickLoadSection
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Status indicator
            if viewModel.originalProgression != nil {
                loadedStatusSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .background(NordicTheme.Dynamic.background(colorScheme))
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
            
            Text("Choose a jazz standard to explore")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
    
    private var quickLoadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
        .shadow(color: NordicTheme.Dynamic.shadowColor(colorScheme), radius: 10, y: 4)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NordicTheme.Colors.success.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NordicTheme.Colors.success.opacity(0.3), lineWidth: 0.5)
        )
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChordInputView(viewModel: ChordViewModel())
}
