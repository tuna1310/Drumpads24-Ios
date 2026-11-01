import SwiftUI

public struct FeedScreen: View {
    public var store: DrumPadsStore
    @State private var selectedFilter: String = "Featured"
    private let filterTabs = ["Featured", "Following", "Latest"]
    private let genreTags = ["Old Town Road", "Chillhop", "Phonk", "Trap", "Lo-Fi"]

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Header
                HStack {
                    Text("Feed")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }

                        Button(action: { store.openPadPlayer(packName: "My New Beat") }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }

                        Button(action: { store.navigateTo(.paywall) }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 2. Filter Tabs (Featured, Following, Latest)
                HStack(spacing: 10) {
                    ForEach(filterTabs, id: \.self) { tab in
                        let isSelected = selectedFilter == tab
                        Button(action: { selectedFilter = tab }) {
                            Text(tab)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? AppTheme.navyCardElevated : AppTheme.navyCard)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? AppTheme.accentCyan : AppTheme.navyBorder, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                // 3. Genre Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genreTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.accentCyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.navyCard)
                                        .overlay(Capsule().stroke(AppTheme.navyBorder, lineWidth: 1))
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 4. Feed Posts List
                ForEach(store.feedPosts) { post in
                    FeedPostCard(post: post) {
                        store.likePost(post.id)
                    } onPlayTrack: {
                        store.openPadPlayer(packName: post.trackTitle)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

private struct FeedPostCard: View {
    let post: FeedPost
    let onLike: () -> Void
    let onPlayTrack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post Author Header
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: post.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(String(post.authorName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.authorName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(post.authorHandle)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Text("\(post.timeAgo) • \(post.genre) • \(post.bpm) BPM")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Caption
            Text(post.caption)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(4)

            // Video / Performance Visualizer Card
            Button(action: onPlayTrack) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: post.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)

                    // Overlay waveform simulation lines
                    HStack(spacing: 4) {
                        ForEach(0..<24, id: \.self) { bar in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 4, height: CGFloat(20 + ((bar * 13) % 70)))
                        }
                    }

                    // Centered Play Button
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )

                    // Bottom info bar
                    VStack {
                        Spacer()
                        HStack {
                            Text(post.trackTitle)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("TAP TO JAM")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(AppTheme.accentYellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
            }
            .buttonStyle(.plain)

            // Social Action Counters: Like, Comment, Share
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? AppTheme.accentPink : AppTheme.textSecondary)
                        Text("\(post.likesCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(post.isLiked ? AppTheme.accentPink : AppTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(post.commentsCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
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
}

