import SwiftUI

public struct SoundsScreen: View {
    @Bindable public var store: DrumPadsStore
    @State private var selectedGenre: Genre = .all
    @State private var searchQuery: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Top Header
                HStack {
                    Text("Drum Pads 24")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(AppTheme.accentCyan)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {
                            if let randomPack = store.soundPacks.randomElement() {
                                store.openPadPlayer(packName: randomPack.title)
                            }
                        }) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }

                        Button(action: { store.navigateTo(.paywall) }) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "#FF2A85"))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 2. Horizontal Stories Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.stories) { story in
                            Button(action: { store.openPadPlayer(packName: story.title) }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: story.gradientColors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2.5
                                            )
                                            .frame(width: 66, height: 66)

                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: story.gradientColors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 58, height: 58)

                                        Text(String(story.title.prefix(2)).uppercased())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    Text(story.title)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(1)
                                        .frame(width: 70)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 3. Recently Used Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recently used")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Button(action: { store.navigateTo(.recentlyUsed) }) {
                            Text("See all >")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.accentYellow)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Recently used card banner (Hyphy)
                    Button(action: { store.openPadPlayer(packName: "Hyphy") }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#E94057"), Color(hex: "#F27121")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)

                                Image(systemName: "play.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Hyphy")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)

                                Text("Drum Pads 24 • Trap • 138 BPM")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
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

                // 4. Genres Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Genre.allCases) { genre in
                            let isSelected = selectedGenre == genre
                            Button(action: { selectedGenre = genre }) {
                                Text(genre.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ? AppTheme.accentYellow : AppTheme.navyCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(isSelected ? Color.clear : AppTheme.navyBorder, lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 5. Sound Packs Collection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sound Packs")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 16)

                    let filteredPacks = store.soundPacks.filter { pack in
                        selectedGenre == .all || pack.genre.lowercased() == selectedGenre.rawValue.lowercased()
                    }

                    ForEach(filteredPacks) { pack in
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

                                    Image(systemName: "music.note")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(pack.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)

                                        if pack.isPro {
                                            Text("PRO")
                                                .font(.system(size: 9, weight: .heavy))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(AppTheme.proBadge)
                                                )
                                        }
                                    }

                                    Text("\(pack.subtitle) • \(pack.genre) • \(pack.bpm) BPM")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Button(action: {
                                    // Trigger preview pad
                                    store.onPadDown(0)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        store.onPadUp(0)
                                    }
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.accentCyan)
                                }
                                .buttonStyle(.plain)
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

                // 6. Upcoming Kits Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coming Soon")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 16)

                    ForEach(SoundPackCatalog.upcomingPacks, id: \.self) { upcoming in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppTheme.accentYellow)
                            Text(upcoming)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("SOON")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.accentYellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().stroke(AppTheme.accentYellow, lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.bottom, 100) // Space for floating bottom nav
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

