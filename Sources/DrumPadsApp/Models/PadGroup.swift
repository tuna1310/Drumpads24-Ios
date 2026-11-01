import Foundation

public enum PadGroup: String, CaseIterable, Identifiable, Sendable {
    case drum = "Drum"
    case bass = "Bass"
    case melody = "Melody"
    case fx = "FX"

    public var id: String { rawValue }

    public var colorHex: String {
        switch self {
        case .drum: return "#E53935"
        case .bass: return "#8E24AA"
        case .melody: return "#00897B"
        case .fx: return "#FB8C00"
        }
    }
}
