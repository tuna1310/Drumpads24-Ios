import Foundation
import SwiftUI

public struct FeedPost: Identifiable, Hashable, Sendable {
    public let id: String
    public let authorName: String
    public let authorHandle: String
    public let timeAgo: String
    public let caption: String
    public let bpm: Int
    public let trackTitle: String
    public let genre: String
    public var likesCount: Int
    public var isLiked: Bool
    public let commentsCount: Int
    public let gradientHexes: [String]

    public init(
        id: String = UUID().uuidString,
        authorName: String,
        authorHandle: String = "@producer",
        timeAgo: String,
        caption: String,
        bpm: Int,
        trackTitle: String,
        genre: String,
        likesCount: Int = 42,
        isLiked: Bool = false,
        commentsCount: Int = 12,
        gradientHexes: [String] = ["#3A86FF", "#8338EC"]
    ) {
        self.id = id
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.timeAgo = timeAgo
        self.caption = caption
        self.bpm = bpm
        self.trackTitle = trackTitle
        self.genre = genre
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.commentsCount = commentsCount
        self.gradientHexes = gradientHexes
    }

    public var gradientColors: [Color] {
        gradientHexes.map { Color(hex: $0) }
    }
}

public enum FeedCatalog {
    public static let initialPosts: [FeedPost] = [
        FeedPost(
            id: "post_1",
            authorName: "DJ Kairo",
            authorHandle: "@kairobeat",
            timeAgo: "2h ago",
            caption: "Live finger drumming jam with the new Neon Pulse 24 pack! Those 808 subs hit crazy hard 🔥",
            bpm: 128,
            trackTitle: "Midnight Velocity",
            genre: "EDM",
            likesCount: 142,
            isLiked: false,
            commentsCount: 23,
            gradientHexes: ["#FF007F", "#7928CA"]
        ),
        FeedPost(
            id: "post_2",
            authorName: "Beat Maker Crew",
            authorHandle: "@drumpads24official",
            timeAgo: "5h ago",
            caption: "PRO TIP: Tap the 'Fill' button right before the drop to generate rapid snare/tom rolls seamlessly! 🥁",
            bpm: 120,
            trackTitle: "Fill & Clean Tutorial",
            genre: "Masterclass",
            likesCount: 389,
            isLiked: true,
            commentsCount: 45,
            gradientHexes: ["#00F5D4", "#00B0FF"]
        ),
        FeedPost(
            id: "post_3",
            authorName: "Chloe Beats",
            authorHandle: "@chloebass",
            timeAgo: "8h ago",
            caption: "Late night Lo-Fi coffee session on 12-pad Scene A. Enjoy the warm cassette tape flutter vibes ☕️",
            bpm: 85,
            trackTitle: "Rainy Sunday Morning",
            genre: "Lo-Fi",
            likesCount: 215,
            isLiked: false,
            commentsCount: 31,
            gradientHexes: ["#F12711", "#F5AF19"]
        ),
        FeedPost(
            id: "post_4",
            authorName: "Marcus 808",
            authorHandle: "@marcus_trap",
            timeAgo: "1d ago",
            caption: "21 savage x Drake type beat created using Clips Mode loops & multi-layer recording 🚀",
            bpm: 140,
            trackTitle: "Relentless Grind",
            genre: "Trap",
            likesCount: 182,
            isLiked: false,
            commentsCount: 19,
            gradientHexes: ["#8A2387", "#E94057"]
        )
    ]
}
