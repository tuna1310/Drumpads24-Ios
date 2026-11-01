import Foundation

public struct Pad: Identifiable, Hashable, Sendable {
    public let id: Int
    public let index: Int
    public let name: String
    public let group: PadGroup
    public let sampleId: String
    public let sampleFile: String
    public let colorHex: String

    public init(index: Int, name: String, group: PadGroup, sampleId: String, sampleFile: String, colorHex: String) {
        self.id = index
        self.index = index
        self.name = name
        self.group = group
        self.sampleId = sampleId
        self.sampleFile = sampleFile
        self.colorHex = colorHex
    }
}
