import Foundation

public struct Pad: Identifiable, Hashable, Sendable {
    public let id: Int
    public let index: Int
    public var name: String
    public let group: PadGroup
    public let sampleId: String
    public let sampleFile: String
    public var colorHex: String
    public var volume: Float
    public var pitch: Float
    public var pan: Float
    public var isMuted: Bool
    public var isSolo: Bool
    public var customSampleURL: URL?

    public init(
        index: Int,
        name: String,
        group: PadGroup,
        sampleId: String,
        sampleFile: String,
        colorHex: String,
        volume: Float = 1.0,
        pitch: Float = 0.0,
        pan: Float = 0.0,
        isMuted: Bool = false,
        isSolo: Bool = false,
        customSampleURL: URL? = nil
    ) {
        self.id = index
        self.index = index
        self.name = name
        self.group = group
        self.sampleId = sampleId
        self.sampleFile = sampleFile
        self.colorHex = colorHex
        self.volume = volume
        self.pitch = pitch
        self.pan = pan
        self.isMuted = isMuted
        self.isSolo = isSolo
        self.customSampleURL = customSampleURL
    }
}
