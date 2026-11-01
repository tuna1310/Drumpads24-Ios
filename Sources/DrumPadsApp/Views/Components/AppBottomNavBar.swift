import SwiftUI

public struct AppBottomNavBar: View {
    public let selectedTab: NavTab
    public let onTabSelected: (NavTab) -> Void

    public init(selectedTab: NavTab, onTabSelected: @escaping (NavTab) -> Void) {
        self.selectedTab = selectedTab
        self.onTabSelected = onTabSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            NavItemView(
                title: "Sounds",
                systemIcon: "play.circle.fill",
                isSelected: selectedTab == .sounds
            ) {
                onTabSelected(.sounds)
            }

            NavItemView(
                title: "Feed",
                systemIcon: "square.stack.fill",
                isSelected: selectedTab == .feed
            ) {
                onTabSelected(.feed)
            }

            NavItemView(
                title: "My",
                systemIcon: "heart.fill",
                isSelected: selectedTab == .my
            ) {
                onTabSelected(.my)
            }

            NavItemView(
                title: "Account",
                systemIcon: "person.crop.circle.fill",
                isSelected: selectedTab == .account
            ) {
                onTabSelected(.account)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(AppTheme.navySurface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(AppTheme.navyBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

private struct NavItemView: View {
    let title: String
    let systemIcon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppTheme.accentYellow : AppTheme.textSecondary)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? AppTheme.accentYellow : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AppTheme.navyCardElevated : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

public struct MiniPlayerBar: View {
    public let trackTitle: String
    public let duration: String
    public let isPlaying: Bool
    public let onTogglePlay: () -> Void

    public init(trackTitle: String, duration: String, isPlaying: Bool, onTogglePlay: @escaping () -> Void) {
        self.trackTitle = trackTitle
        self.duration = duration
        self.isPlaying = isPlaying
        self.onTogglePlay = onTogglePlay
    }

    public var body: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePlay) {
                ZStack {
                    Circle()
                        .fill(AppTheme.brandPinkCyan)
                        .frame(width: 34, height: 34)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(trackTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text("Drum Pads 24 • \(duration)")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "waveform")
                .font(.system(size: 16))
                .foregroundColor(isPlaying ? AppTheme.accentCyan : AppTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.navySurface.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.navyBorder.opacity(0.8), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
