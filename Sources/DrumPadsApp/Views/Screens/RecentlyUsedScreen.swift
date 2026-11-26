import SwiftUI

public struct RecentlyUsedScreen: View {
    public var store: DrumPadsStore
    @State private var showSearch: Bool = false
    @State private var searchQuery: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
    }

    private var filteredRecentPacks: [SoundPack] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.recentlyUsedPacks }
        return store.recentlyUsedPacks.filter {
            $0.title.lowercased().contains(q) || $0.genre.displayName.lowercased().contains(q)
        }
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Top Header
                HStack {
                    Button(action: { store.navigateBack() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Text("Recently used")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {
                        showSearch.toggle()
                        if !showSearch { searchQuery = "" }
                    }) {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(showSearch ? AppTheme.accentCyan : AppTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if showSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.accentCyan)
                        TextField("Filter recent packs...", text: $searchQuery)
                            .foregroundColor(AppTheme.textPrimary)
                            .font(.system(size: 14))
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.navyCard)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.navyBorder, lineWidth: 1))
                    )
                    .padding(.horizontal, 16)
                }

                // Recent Packs List
                VStack(spacing: 12) {
                    if filteredRecentPacks.isEmpty {
                        Text("No matching recent packs")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else {
                        ForEach(filteredRecentPacks) { pack in
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
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

