import SwiftUI

public struct MainAppContainer: View {
    @State private var store = DrumPadsStore.shared

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.navyBackground
                .ignoresSafeArea()

            switch store.activeScreen {
            case .main:
                VStack(spacing: 0) {
                    Group {
                        switch store.selectedTab {
                        case .sounds:
                            SoundsScreen(store: store)
                        case .feed:
                            FeedScreen(store: store)
                        case .my:
                            MyStudioScreen(store: store)
                        case .account:
                            AccountScreen(store: store)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: 4) {
                        Divider().background(AppTheme.navyBorder)
                        if let track = store.miniPlayerTrack {
                            MiniPlayerBar(
                                trackTitle: track,
                                duration: store.miniPlayerDuration,
                                isPlaying: store.isMiniPlayerPlaying,
                                onTogglePlay: { store.toggleMiniPlayer() },
                                onNext: { store.nextMiniPlayerTrack() }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        AppBottomNavBar(
                            selectedTab: store.selectedTab,
                            onTabSelected: { store.selectTab($0) }
                        )
                    }
                    .background(AppTheme.navySurface)
                }
                .transition(.opacity)

            case .padPlayer:
                PadPlayerScreen(store: store)
                    .transition(.move(edge: .bottom))

            case .settings:
                SettingsScreen(store: store)
                    .transition(.move(edge: .trailing))

            case .editProfile:
                EditProfileScreen(store: store)
                    .transition(.move(edge: .trailing))

            case .recentlyUsed:
                RecentlyUsedScreen(store: store)
                    .transition(.move(edge: .trailing))

            case .paywall:
                PaywallScreen(store: store)
                    .transition(.opacity)

            case .padEditor:
                PadEditorScreen(store: store)
                    .transition(.move(edge: .bottom))

            case .soundEditor:
                SoundEditorScreen(store: store)
                    .transition(.move(edge: .trailing))

            case .clipEditor:
                ClipEditorScreen(store: store)
                    .transition(.move(edge: .trailing))

            case .projectEditor:
                ProjectEditorView(store: store)
                    .transition(.move(edge: .bottom))

            case .recordings:
                RecordingsScreen(store: store)
                    .transition(.move(edge: .trailing))
            }

            if store.activeScreen != .padPlayer, let msg = store.statusBannerMessage {
                VStack {
                    Text(msg)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.navyCardElevated.opacity(0.96))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppTheme.accentCyan, lineWidth: 1)
                                )
                        )
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.activeScreen)
        .preferredColorScheme(.dark)
    }
}
