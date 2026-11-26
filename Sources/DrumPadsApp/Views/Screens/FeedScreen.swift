import SwiftUI

public struct FeedScreen: View {
    public var store: DrumPadsStore
    @State private var commentingPost: FeedPost? = nil
    @State private var commentInput: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explore Community")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                        Text("Global Beats & Beat Maker Crew Tutorials")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Category Tabs: FEATURED | FOLLOWING | EXPLORE
                HStack(spacing: 8) {
                    ForEach(FeedPost.FeedCategory.allCases, id: \.self) { cat in
                        let selected = store.selectedFeedCategory == cat
                        Button(action: { store.selectedFeedCategory = cat }) {
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(selected ? .black : AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(selected ? AppTheme.accentYellow : AppTheme.navyCard))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                // Feed Cards
                VStack(spacing: 14) {
                    ForEach(store.filteredFeedPosts) { post in
                        feedPostCard(post)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .sheet(item: $commentingPost) { post in
            commentSheet(for: post)
        }
    }

    private func feedPostCard(_ post: FeedPost) -> some View {
        let isPlaying = store.playingPostId == post.id
        return VStack(alignment: .leading, spacing: 12) {
            // Author Header + CREW badge + Follow button aligned on the same top baseline
            HStack(alignment: .center, spacing: 10) {
                Circle()
                    .fill(post.avatarColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.authorName.prefix(1)))
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.black)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .center, spacing: 6) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(post.authorName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            if post.isCrewTutorial {
                                Text("CREW")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(AppTheme.accentYellow))
                            }
                        }

                        Spacer(minLength: 6)

                        Button(action: { store.toggleFollowAuthor(postId: post.id) }) {
                            Text(post.isFollowingAuthor ? "Following" : "Follow")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(post.isFollowingAuthor ? AppTheme.accentCyan : .black)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(post.isFollowingAuthor ? AppTheme.navyCardElevated : AppTheme.accentCyan))
                        }
                    }

                    Text("\(post.authorHandle) • \(post.timeAgo)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            // Track Title + Genre Tag
            HStack {
                Text(post.trackTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(post.genreTag)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(AppTheme.accentPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppTheme.accentPink.opacity(0.15)))
            }

            // Playable Sound Preview Strip
            HStack(spacing: 12) {
                Button(action: { store.togglePlayPost(post) }) {
                    Circle()
                        .fill(isPlaying ? AppTheme.accentYellow : AppTheme.accentCyan)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .foregroundColor(.black)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sound Pack: \(post.packUsed)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("Duration: \(post.durationString)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if post.isCrewTutorial {
                    Button(action: { store.startCrewTutorial(post) }) {
                        Text("START LESSON")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                } else {
                    Button(action: { store.openPadPlayer(packName: post.packUsed) }) {
                        Text("DOWNLOAD PACK")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppTheme.accentCyan))
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.navySurface))

            // Likes / Comments / Share Bar
            HStack(spacing: 18) {
                Button(action: { store.toggleLike(postId: post.id) }) {
                    Label("\(post.likesCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(post.isLiked ? AppTheme.accentPink : AppTheme.textSecondary)
                }

                Button(action: { commentingPost = post }) {
                    Label("\(post.commentsCount)", systemImage: "bubble.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: {
                    AudioExportService.shared.shareText("Listen to '\(post.trackTitle)' by \(post.authorName) using Sound Pack \(post.packUsed) on Drum Pads 24!")
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.navyCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(post.isCrewTutorial ? AppTheme.accentYellow.opacity(0.4) : AppTheme.navyBorder, lineWidth: 1)
                )
        )
    }

    private func commentSheet(for post: FeedPost) -> some View {
        let livePost = store.feedPosts.first(where: { $0.id == post.id }) ?? post
        return VStack(spacing: 12) {
            Text("Comments • \(livePost.trackTitle)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if livePost.comments.isEmpty {
                        Text("No comments yet. Start the conversation!")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding()
                    } else {
                        ForEach(livePost.comments) { c in
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(c.author) • \(c.timestamp)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.accentCyan)
                                Text(c.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 8) {
                TextField("Write a comment...", text: $commentInput)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
                    .foregroundColor(.white)
                Button(action: {
                    store.addComment(postId: post.id, text: commentInput)
                    commentInput = ""
                }) {
                    Text("Send")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(AppTheme.accentYellow))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}
