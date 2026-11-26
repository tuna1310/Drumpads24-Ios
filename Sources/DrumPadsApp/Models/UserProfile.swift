import Foundation

public struct RecordedPadEvent: Codable, Hashable, Sendable {
    public let padIndex: Int
    public let timestampMs: Int64

    public init(padIndex: Int, timestampMs: Int64) {
        self.padIndex = padIndex
        self.timestampMs = timestampMs
    }
}

public struct UserProfile: Codable, Sendable {
    public var userName: String
    public var userBio: String
    public var userLink: String
    public var followersCount: Int
    public var followingCount: Int
    public var isProUser: Bool
    public var tracksCount: Int

    public init(
        userName: String = "Tuấn Phạm Anh",
        userBio: String = "Beat maker & Sound designer",
        userLink: String = "https://instagram.com/tuanphamanh",
        followersCount: Int = 128,
        followingCount: Int = 42,
        isProUser: Bool = false,
        tracksCount: Int = 7
    ) {
        self.userName = userName
        self.userBio = userBio
        self.userLink = userLink
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isProUser = isProUser
        self.tracksCount = tracksCount
    }
}

public struct RecordingItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var title: String
    public let date: Date
    public let durationFormatted: String
    public let durationMs: Int64
    public let packName: String
    public let bpm: Int
    public let fileURL: URL?
    public let padEvents: [RecordedPadEvent]

    public init(
        id: String = UUID().uuidString,
        title: String,
        date: Date = Date(),
        durationFormatted: String = "00:45",
        durationMs: Int64 = 0,
        packName: String = "FESTIVAL EDM",
        bpm: Int = 128,
        fileURL: URL? = nil,
        padEvents: [RecordedPadEvent] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationFormatted = durationFormatted
        self.durationMs = durationMs
        self.packName = packName
        self.bpm = bpm
        self.fileURL = fileURL
        self.padEvents = padEvents
    }
}
