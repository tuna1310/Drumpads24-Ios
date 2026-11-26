import SwiftUI

public struct FeedComment: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let author: String
    public let text: String
    public let timestamp: String

    public init(id: String = UUID().uuidString, author: String, text: String, timestamp: String = "Just now") {
        self.id = id
        self.author = author
        self.text = text
        self.timestamp = timestamp
    }
}

public struct TutorialStep: Codable, Hashable, Sendable {
    public let padIndex: Int
    public let delayMs: Int
    public let label: String

    public init(padIndex: Int, delayMs: Int, label: String) {
        self.padIndex = padIndex
        self.delayMs = delayMs
        self.label = label
    }
}

public struct FeedPost: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var authorName: String
    public var authorHandle: String
    public var avatarColorHex: String
    public var trackTitle: String
    public var packUsed: String
    public var packId: String
    public var genreTag: String
    public var likesCount: Int
    public var commentsCount: Int
    public var isLiked: Bool
    public var isFollowingAuthor: Bool
    public var isCrewTutorial: Bool
    public var tutorialSteps: [TutorialStep]
    public var comments: [FeedComment]
    public var durationString: String
    public var timeAgo: String
    public var category: FeedCategory
    public var recordingFilePath: String?

    public enum FeedCategory: String, CaseIterable, Codable, Sendable {
        case featured = "FEATURED"
        case following = "FOLLOWING"
        case latest = "EXPLORE"
    }

    public init(
        id: String,
        authorName: String,
        authorHandle: String,
        avatarColorHex: String,
        trackTitle: String,
        packUsed: String,
        packId: String = "edm_festival",
        genreTag: String = "EDM",
        likesCount: Int,
        commentsCount: Int,
        isLiked: Bool = false,
        isFollowingAuthor: Bool = false,
        isCrewTutorial: Bool = false,
        tutorialSteps: [TutorialStep] = [],
        comments: [FeedComment] = [],
        durationString: String,
        timeAgo: String,
        category: FeedCategory,
        recordingFilePath: String? = nil
    ) {
        self.id = id
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.avatarColorHex = avatarColorHex
        self.trackTitle = trackTitle
        self.packUsed = packUsed
        self.packId = packId
        self.genreTag = genreTag
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLiked = isLiked
        self.isFollowingAuthor = isFollowingAuthor
        self.isCrewTutorial = isCrewTutorial
        self.tutorialSteps = tutorialSteps
        self.comments = comments
        self.durationString = durationString
        self.timeAgo = timeAgo
        self.category = category
        self.recordingFilePath = recordingFilePath
    }

    public var avatarColor: Color {
        Color(hex: avatarColorHex)
    }
}

public enum FeedCatalog {
    public static let samplePosts: [FeedPost] = [
        FeedPost(
            id: "crew_1",
            authorName: "Paul Lipnyagov",
            authorHandle: "@beatmaker_crew",
            avatarColorHex: "#FFD233",
            trackTitle: "Lesson 1: Phonk Cowbell Drift Drop",
            packUsed: "PHONK DRIFT",
            packId: "phonk_drift",
            genreTag: "PHONK",
            likesCount: 4820,
            commentsCount: 312,
            isFollowingAuthor: true,
            isCrewTutorial: true,
            tutorialSteps: [
                TutorialStep(padIndex: 0, delayMs: 0, label: "Kick"),
                TutorialStep(padIndex: 12, delayMs: 320, label: "Cowbell C"),
                TutorialStep(padIndex: 13, delayMs: 320, label: "Cowbell D#"),
                TutorialStep(padIndex: 2, delayMs: 320, label: "Snare"),
                TutorialStep(padIndex: 6, delayMs: 320, label: "808 Reese"),
                TutorialStep(padIndex: 14, delayMs: 320, label: "Cowbell F"),
                TutorialStep(padIndex: 4, delayMs: 280, label: "Hat"),
                TutorialStep(padIndex: 15, delayMs: 320, label: "Cowbell G")
            ],
            comments: [
                FeedComment(author: "KaitoBeats", text: "Clean cowbell pattern! Helped me nail the drift groove."),
                FeedComment(author: "NovaMix", text: "Lightshow follow mode is super responsive!")
            ],
            durationString: "0:28",
            timeAgo: "Pinned Lesson",
            category: .featured
        ),
        FeedPost(
            id: "crew_2",
            authorName: "DJ Scratch • Crew",
            authorHandle: "@djscratch_crew",
            avatarColorHex: "#00E5FF",
            trackTitle: "Lesson 2: Trap 808 Finger Drum Basics",
            packUsed: "TRAP GOD",
            packId: "trap_god",
            genreTag: "TRAP",
            likesCount: 3190,
            commentsCount: 198,
            isFollowingAuthor: true,
            isCrewTutorial: true,
            tutorialSteps: [
                TutorialStep(padIndex: 0, delayMs: 0, label: "808 Kick"),
                TutorialStep(padIndex: 4, delayMs: 240, label: "Roll Hat"),
                TutorialStep(padIndex: 4, delayMs: 240, label: "Roll Hat"),
                TutorialStep(padIndex: 2, delayMs: 280, label: "Clap"),
                TutorialStep(padIndex: 6, delayMs: 300, label: "808 Boom"),
                TutorialStep(padIndex: 12, delayMs: 320, label: "Flute")
            ],
            comments: [
                FeedComment(author: "BassHead", text: "Best beginner trap finger-drumming drill.")
            ],
            durationString: "0:34",
            timeAgo: "Crew Academy",
            category: .featured
        ),
        FeedPost(
            id: "post_3",
            authorName: "KaitoBeats",
            authorHandle: "@kaitobeats",
            avatarColorHex: "#FF2A85",
            trackTitle: "Tokyo Drift 3AM (Live Finger Drum)",
            packUsed: "PHONK DRIFT",
            packId: "phonk_drift",
            genreTag: "PHONK",
            likesCount: 1420,
            commentsCount: 84,
            comments: [
                FeedComment(author: "LunaSynth", text: "That 808 distortion goes hard!")
            ],
            durationString: "1:12",
            timeAgo: "2h ago",
            category: .featured
        ),
        FeedPost(
            id: "post_4",
            authorName: "LunaSynth",
            authorHandle: "@lunasynth_io",
            avatarColorHex: "#7B2CBF",
            trackTitle: "Cyberpunk Sunset One-Take",
            packUsed: "RETRO WAVE",
            packId: "neon_synthwave",
            genreTag: "SYNTHWAVE",
            likesCount: 938,
            commentsCount: 41,
            isLiked: true,
            isFollowingAuthor: true,
            durationString: "1:45",
            timeAgo: "4h ago",
            category: .following
        ),
        FeedPost(
            id: "post_5",
            authorName: "808_Vortex",
            authorHandle: "@vortex_drops",
            avatarColorHex: "#38E54D",
            trackTitle: "Festival Mainstage Wobble Session",
            packUsed: "DUBSTEP WOBBLE",
            packId: "wobble_king",
            genreTag: "DUBSTEP",
            likesCount: 2156,
            commentsCount: 128,
            durationString: "2:08",
            timeAgo: "6h ago",
            category: .latest
        ),
        FeedPost(
            id: "post_6",
            authorName: "ChillWaveLab",
            authorHandle: "@chillwavelab",
            avatarColorHex: "#00B0FF",
            trackTitle: "Rainy Midnight Study Beats",
            packUsed: "RAINY LO-FI",
            packId: "lofi_rain",
            genreTag: "LO-FI",
            likesCount: 1840,
            commentsCount: 97,
            durationString: "1:54",
            timeAgo: "9h ago",
            category: .latest
        )
    ]
}
