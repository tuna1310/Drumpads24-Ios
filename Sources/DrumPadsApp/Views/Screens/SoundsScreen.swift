import SwiftUI

public struct SoundsScreen: View {
    public var store: DrumPadsStore
    @State private var isSearchVisible: Bool = false

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header: EXPLORE SOUNDS + Create + Search + Random
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explore Sounds")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                        Text("12 Genres • Play, Preview & Create")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button(action: { store.navigateTo(.projectEditor) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .black))
                            Text("Create")
                                .font(.system(size: 12, weight: .black))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppTheme.accentYellow))
                    }
                    Button(action: {
                        withAnimation { isSearchVisible.toggle() }
                    }) {
                        Image(systemName: isSearchVisible ? "xmark" : "magnifyingglass")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.navyCard))
                    }
                    Button(action: {
                        if let randomPack = store.allPacks.randomElement() {
                            store.loadSoundPack(randomPack)
                            store.navigateTo(.padPlayer)
                        }
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.accentCyan))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                    if isSearchVisible {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Search packs or genres (Phonk, Trap, Lo-Fi...)", text: Binding(
                                get: { store.searchQuery },
                                set: { store.searchQuery = $0 }
                            ))
                            .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.navyCard))
                        .padding(.horizontal, 16)
                    }

                    // Horizontal 12-Genre Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MusicGenre.allCases, id: \.self) { genre in
                                let sel = store.selectedGenreFilter == genre
                                Button(action: { store.selectedGenreFilter = genre }) {
                                    Text(genre.displayName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(sel ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(sel ? AppTheme.accentYellow : AppTheme.navyCard))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Featured Stories Carousel
                    if store.selectedGenreFilter == .all && store.searchQuery.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FEATURED PACKS")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(SoundPackCatalog.featuredStories) { pack in
                                        featuredStoryCard(pack)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // All / Filtered Sound Packs Grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(store.selectedGenreFilter == .all ? "ALL SOUND PACKS" : "\(store.selectedGenreFilter.displayName.uppercased()) PACKS")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("\(store.filteredPacks.count) packs")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.accentCyan)
                        }
                        .padding(.horizontal, 16)

                        if store.filteredPacks.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.accentCyan)
                                Text("No sound packs found")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Try clearing your search or switching back to All.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                                Button("Reset Filters") {
                                    store.searchQuery = ""
                                    store.selectedGenreFilter = .all
                                    isSearchVisible = false
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AppTheme.accentCyan))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                        } else {
                            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(store.filteredPacks) { pack in
                                    soundPackGridCard(pack)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(AppTheme.navyBackground.ignoresSafeArea())
        }

    private func featuredStoryCard(_ pack: SoundPack) -> some View {
        let isPreviewing = store.previewingPackId == pack.id
        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: pack.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 146, height: 146)
                    .overlay(
                        VStack(alignment: .leading) {
                            HStack {
                                Text(pack.genre.displayName.uppercased())
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(AppTheme.accentYellow))
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Button(action: { store.previewSoundPack(pack) }) {
                                    Circle()
                                        .fill(Color.black.opacity(0.55))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        )
                                }
                                Spacer()
                                Text("\(pack.bpm) BPM")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(10)
                    )

                Button(action: { store.toggleFavorite(packId: pack.id) }) {
                    Image(systemName: store.favoritePackIds.contains(pack.id) ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(store.favoritePackIds.contains(pack.id) ? AppTheme.accentPink : .white)
                        .padding(8)
                }
            }
            .onTapGesture {
                store.loadSoundPack(pack)
                store.navigateTo(.padPlayer)
            }

            Text(pack.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(pack.subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 146)
    }

    private func soundPackGridCard(_ pack: SoundPack) -> some View {
        let isFav = store.favoritePackIds.contains(pack.id)
        let isPreviewing = store.previewingPackId == pack.id

        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: pack.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 118)
                    .overlay(
                        VStack {
                            HStack {
                                Text(pack.isCustom ? "CUSTOM" : pack.genre.displayName.uppercased())
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.black.opacity(0.45)))
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Button(action: { store.previewSoundPack(pack) }) {
                                    Circle()
                                        .fill(Color.black.opacity(0.55))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white)
                                        )
                                }
                                Spacer()
                                Text("LOAD")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(AppTheme.accentYellow))
                            }
                        }
                        .padding(10)
                    )

                Button(action: { store.toggleFavorite(packId: pack.id) }) {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isFav ? AppTheme.accentPink : .white)
                        .padding(8)
                }
            }
            .onTapGesture {
                store.loadSoundPack(pack)
                store.navigateTo(.padPlayer)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(pack.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(pack.bpm) BPM • \(pack.subtitle)")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.navyCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.navyBorder, lineWidth: 1)
                )
        )
    }
}
