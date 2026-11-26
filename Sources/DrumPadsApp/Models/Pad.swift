import Foundation

public enum PadPlayMode: String, Codable, CaseIterable, Sendable {
    case oneShot = "ONE SHOT"
    case loop = "LOOP"
    case hold = "HOLD"
}

public struct Pad: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let index: Int
    public var name: String
    public var group: PadGroup
    public var sampleId: String
    public var sampleFile: String
    public var colorHex: String
    public var volume: Float
    public var pitch: Float // Semitones (-12 to +12)
    public var pan: Float   // -1.0 (Left) to +1.0 (Right)
    public var isMuted: Bool
    public var isSolo: Bool
    public var customSampleURL: URL?
    public var playMode: PadPlayMode
    public var trimStart: Float
    public var trimEnd: Float
    public var fadeInRatio: Float
    public var fadeOutRatio: Float
    public var chokeGroup: Int // 0 = None, 1 = Group 1, 2 = Group 2
    public var padReverbSend: Float
    public var padDistortion: Float

    public init(
        id: String? = nil,
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
        customSampleURL: URL? = nil,
        playMode: PadPlayMode = .oneShot,
        trimStart: Float = 0.0,
        trimEnd: Float = 1.0,
        fadeInRatio: Float = 0.0,
        fadeOutRatio: Float = 0.0,
        chokeGroup: Int = 0,
        padReverbSend: Float = 0.0,
        padDistortion: Float = 0.0
    ) {
        self.id = id ?? "pad_\(index)"
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
        self.playMode = playMode
        self.trimStart = trimStart
        self.trimEnd = trimEnd
        self.fadeInRatio = fadeInRatio
        self.fadeOutRatio = fadeOutRatio
        self.chokeGroup = chokeGroup
        self.padReverbSend = padReverbSend
        self.padDistortion = padDistortion
    }
}
