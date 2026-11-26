import Foundation

public enum RecordingMode: String, Codable, CaseIterable, Sendable {
    case freeMode = "Free Mode"
    case loopMode = "Loop Mode"
}

public struct ClipHit: Codable, Equatable, Sendable {
    public var step: Int     // 0..15
    public var padIndex: Int // 0..23
    public var velocity: Float

    public init(step: Int, padIndex: Int, velocity: Float = 1.0) {
        self.step = step
        self.padIndex = padIndex
        self.velocity = velocity
    }
}

public struct ClipSlot: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var name: String
    public var colorHex: String
    public var hits: [ClipHit]
    public var isPlaying: Bool

    public init(
        id: Int,
        name: String,
        colorHex: String,
        hits: [ClipHit] = [],
        isPlaying: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.hits = hits
        self.isPlaying = isPlaying
    }

    public var hasHits: Bool { !hits.isEmpty }
}

public enum ClipPatternPresets {
    public static let presetNames: [String] = [
        "PATTERN 1 • Trap Bounce",
        "PATTERN 2 • House Groove",
        "PATTERN 3 • Phonk Drift",
        "PATTERN 4 • Dubstep Drop"
    ]

    public static func defaultClips() -> [ClipSlot] {
        let colors = [
            "#E040FB", "#FF2A85", "#00E5FF", "#38E54D",
            "#FF7A00", "#FFD233", "#7B2CBF", "#00F5D4",
            "#FF2E93", "#00B0FF", "#9D00FF", "#FFD600"
        ]
        var slots: [ClipSlot] = []
        for idx in 0..<12 {
            let hits: [ClipHit]
            switch idx {
            case 0:
                hits = hitsForPreset(0)
            case 1:
                hits = hitsForPreset(1)
            case 2:
                hits = hitsForPreset(2)
            case 3:
                hits = [
                    ClipHit(step: 0, padIndex: 6),
                    ClipHit(step: 6, padIndex: 7),
                    ClipHit(step: 8, padIndex: 8),
                    ClipHit(step: 14, padIndex: 9)
                ]
            default:
                hits = []
            }
            slots.append(
                ClipSlot(
                    id: idx,
                    name: "Clip \(idx + 1)",
                    colorHex: colors[idx % colors.count],
                    hits: hits,
                    isPlaying: false
                )
            )
        }
        return slots
    }

    public static func hitsForPreset(_ presetIndex: Int) -> [ClipHit] {
        switch presetIndex % 4 {
        case 0: // Trap Bounce
            return [
                ClipHit(step: 0, padIndex: 0), ClipHit(step: 6, padIndex: 0), ClipHit(step: 10, padIndex: 0),
                ClipHit(step: 4, padIndex: 2), ClipHit(step: 12, padIndex: 2),
                ClipHit(step: 0, padIndex: 4), ClipHit(step: 2, padIndex: 4), ClipHit(step: 4, padIndex: 4),
                ClipHit(step: 6, padIndex: 4), ClipHit(step: 8, padIndex: 4), ClipHit(step: 10, padIndex: 4),
                ClipHit(step: 11, padIndex: 4), ClipHit(step: 12, padIndex: 4), ClipHit(step: 14, padIndex: 4),
                ClipHit(step: 0, padIndex: 6), ClipHit(step: 10, padIndex: 7)
            ]
        case 1: // House Groove
            return [
                ClipHit(step: 0, padIndex: 0), ClipHit(step: 4, padIndex: 0), ClipHit(step: 8, padIndex: 0), ClipHit(step: 12, padIndex: 0),
                ClipHit(step: 2, padIndex: 5), ClipHit(step: 6, padIndex: 5), ClipHit(step: 10, padIndex: 5), ClipHit(step: 14, padIndex: 5),
                ClipHit(step: 4, padIndex: 3), ClipHit(step: 12, padIndex: 3),
                ClipHit(step: 0, padIndex: 12), ClipHit(step: 6, padIndex: 14), ClipHit(step: 12, padIndex: 15)
            ]
        case 2: // Phonk Drift
            return [
                ClipHit(step: 0, padIndex: 1), ClipHit(step: 3, padIndex: 1), ClipHit(step: 8, padIndex: 1),
                ClipHit(step: 4, padIndex: 2), ClipHit(step: 12, padIndex: 2),
                ClipHit(step: 0, padIndex: 12), ClipHit(step: 2, padIndex: 13), ClipHit(step: 4, padIndex: 14),
                ClipHit(step: 6, padIndex: 13), ClipHit(step: 8, padIndex: 15), ClipHit(step: 10, padIndex: 14),
                ClipHit(step: 12, padIndex: 16), ClipHit(step: 14, padIndex: 13)
            ]
        default: // Dubstep Drop
            return [
                ClipHit(step: 0, padIndex: 0), ClipHit(step: 10, padIndex: 0),
                ClipHit(step: 8, padIndex: 2),
                ClipHit(step: 0, padIndex: 6), ClipHit(step: 4, padIndex: 7), ClipHit(step: 8, padIndex: 8), ClipHit(step: 12, padIndex: 9),
                ClipHit(step: 0, padIndex: 20)
            ]
        }
    }
}
