import Foundation

public final class StudioStorage: @unchecked Sendable {
    public static let shared = StudioStorage()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let recordings = "dp24_recordings_v1"
        static let customPacks = "dp24_custom_packs_v1"
        static let favoritePackIds = "dp24_favorites_v1"
        static let recentPackIds = "dp24_recents_v1"
        static let userProfile = "dp24_profile_v1"
        static let customPadsPrefix = "dp24_custom_pads_"
        static let userFeedPosts = "dp24_user_posts_v1"
    }

    public func loadRecordings() -> [RecordingItem] {
        guard let data = defaults.data(forKey: Keys.recordings),
              let items = try? decoder.decode([RecordingItem].self, from: data) else {
            return []
        }
        return items
    }

    public func saveRecordings(_ items: [RecordingItem]) {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: Keys.recordings)
        }
    }

    public func loadCustomPacks() -> [SoundPack] {
        guard let data = defaults.data(forKey: Keys.customPacks),
              let items = try? decoder.decode([SoundPack].self, from: data) else {
            return []
        }
        return items
    }

    public func saveCustomPacks(_ packs: [SoundPack]) {
        if let data = try? encoder.encode(packs) {
            defaults.set(data, forKey: Keys.customPacks)
        }
    }

    public func loadCustomPads(for packId: String) -> [Pad]? {
        guard let data = defaults.data(forKey: Keys.customPadsPrefix + packId),
              let pads = try? decoder.decode([Pad].self, from: data),
              pads.count == 24 else {
            return nil
        }
        return pads
    }

    public func saveCustomPads(_ pads: [Pad], for packId: String) {
        if let data = try? encoder.encode(pads) {
            defaults.set(data, forKey: Keys.customPadsPrefix + packId)
        }
    }

    public func loadFavorites() -> Set<String> {
        let array = defaults.stringArray(forKey: Keys.favoritePackIds) ?? []
        return Set(array)
    }

    public func saveFavorites(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: Keys.favoritePackIds)
    }

    public func loadRecentIds() -> [String] {
        defaults.stringArray(forKey: Keys.recentPackIds) ?? ["trap_god", "phonk_drift", "edm_festival"]
    }

    public func saveRecentIds(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.recentPackIds)
    }

    public func loadProfile() -> UserProfile {
        guard let data = defaults.data(forKey: Keys.userProfile),
              let p = try? decoder.decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return p
    }

    public func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: Keys.userProfile)
        }
    }

    public func loadUserPosts() -> [FeedPost] {
        guard let data = defaults.data(forKey: Keys.userFeedPosts),
              let posts = try? decoder.decode([FeedPost].self, from: data) else {
            return []
        }
        return posts
    }

    public func saveUserPosts(_ posts: [FeedPost]) {
        if let data = try? encoder.encode(posts) {
            defaults.set(data, forKey: Keys.userFeedPosts)
        }
    }
}
