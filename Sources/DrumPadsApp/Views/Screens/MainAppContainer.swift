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
                ZStack(alignment: .bottom) {
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
        }
        .animation(.easeInOut(duration: 0.22), value: store.activeScreen)
        .preferredColorScheme(.dark)
    }
}
