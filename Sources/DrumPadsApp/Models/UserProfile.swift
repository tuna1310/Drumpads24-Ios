import Foundation

public struct UserProfile: Sendable {
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

public struct RecordingItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let date: Date
    public let durationFormatted: String
    public let packName: String
    public let bpm: Int
    public let fileURL: URL?

    public init(
        id: String = UUID().uuidString,
        title: String,
        date: Date = Date(),
        durationFormatted: String = "00:45",
        packName: String = "Neon Pulse 24",
        bpm: Int = 120,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationFormatted = durationFormatted
        self.packName = packName
        self.bpm = bpm
        self.fileURL = fileURL
    }
}

