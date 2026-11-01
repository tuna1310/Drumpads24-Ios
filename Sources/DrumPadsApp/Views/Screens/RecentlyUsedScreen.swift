import SwiftUI

public struct RecentlyUsedScreen: View {
    @Bindable public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Top Header
                HStack {
                    Button(action: { store.navigateTo(.main) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Text("Recently used")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Recent Packs List
                VStack(spacing: 12) {
                    ForEach(store.recentlyUsedPacks) { pack in
                        Button(action: { store.openPadPlayer(packName: pack.title) }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: pack.gradientColors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 58, height: 58)

                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(pack.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text("\(pack.subtitle) • Tap to play • \(pack.bpm) BPM")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(AppTheme.navyCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(AppTheme.navyBorder, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

