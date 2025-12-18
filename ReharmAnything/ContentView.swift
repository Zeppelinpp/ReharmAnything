import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChordViewModel()
    @State private var selectedTab = 0
    @State private var isInitialized = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            NordicTheme.Dynamic.background(colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // App header
                appHeader
                
                // Main content
                TabView(selection: $selectedTab) {
                    ChordInputView(viewModel: viewModel)
                        .tag(0)
                    
                    ReharmView(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom tab bar
                customTabBar
            }
        }
        .task {
            if !isInitialized {
                await viewModel.initializeAudio()
                isInitialized = true
            }
        }
    }
    
    private var appHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ReharmAnything")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(NordicTheme.Dynamic.text(colorScheme))
                
                Text("Jazz Reharmonization")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
            }
            
            Spacer()
            
            // Sound indicator
            if SoundFontManager.shared.isInitialized {
                HStack(spacing: 6) {
                    Circle()
                        .fill(NordicTheme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NordicTheme.Dynamic.textSecondary(colorScheme))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(NordicTheme.Dynamic.surfaceSecondary(colorScheme))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(NordicTheme.Dynamic.surface(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NordicTheme.Dynamic.border(colorScheme))
                .frame(height: 0.5)
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 4) {
            TabBarButton(
                icon: "square.stack.3d.up",
                title: "Charts",
                isSelected: selectedTab == 0,
                colorScheme: colorScheme
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }
            
            TabBarButton(
                icon: "slider.horizontal.3",
                title: "Reharm",
                isSelected: selectedTab == 1,
                badge: viewModel.originalProgression != nil,
                colorScheme: colorScheme
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NordicTheme.Dynamic.surface(colorScheme))
                .shadow(color: NordicTheme.Dynamic.shadowColor(colorScheme), radius: 8, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
        )
        .padding(.horizontal, 60)
        .padding(.bottom, 10)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var badge: Bool = false
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    if badge {
                        Circle()
                            .fill(NordicTheme.Colors.success)
                            .frame(width: 6, height: 6)
                            .offset(x: 3, y: -3)
                    }
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected 
                ? NordicTheme.Colors.primary 
                : NordicTheme.Dynamic.textSecondary(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected 
                        ? NordicTheme.Colors.primary.opacity(colorScheme == .dark ? 0.2 : 0.1)
                        : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
