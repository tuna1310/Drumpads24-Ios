import XCTest
@testable import DrumPadsApp

final class PadMappingTests: XCTestCase {

    let repository = DefaultPadRepository.shared

    func testExactly24PadsConfigured() {
        let pads = repository.getPads()
        XCTAssertEqual(pads.count, 24, "Must configure exactly 24 pads")
    }

    func testPadIndicesAreSequential() {
        let pads = repository.getPads()
        for i in 0..<24 {
            XCTAssertEqual(pads[i].index, i)
        }
    }

    func testFourPadGroupsEquallyDistributed() {
        let pads = repository.getPads()
        let drums = pads.filter { $0.group == .drum }
        let basses = pads.filter { $0.group == .bass }
        let melodies = pads.filter { $0.group == .melody }
        let fxs = pads.filter { $0.group == .fx }

        XCTAssertEqual(drums.count, 6, "Must have 6 Drum pads")
        XCTAssertEqual(basses.count, 6, "Must have 6 Bass pads")
        XCTAssertEqual(melodies.count, 6, "Must have 6 Melody pads")
        XCTAssertEqual(fxs.count, 6, "Must have 6 FX pads")
    }

    func testSampleIdsAreUniqueAndValid() {
        let pads = repository.getPads()
        let ids = Set(pads.map { $0.sampleId })
        XCTAssertEqual(ids.count, 24, "All 24 sample IDs must be unique")

        for pad in pads {
            XCTAssertFalse(pad.sampleId.isEmpty)
            XCTAssertTrue(pad.sampleFile.hasSuffix(".wav"))
        }
    }

    func testGetPadByIndex() {
        let pad0 = repository.getPad(at: 0)
        XCTAssertNotNil(pad0)
        XCTAssertEqual(pad0?.name, "Kick Punch")
        XCTAssertEqual(pad0?.group, .drum)

        let invalid = repository.getPad(at: 99)
        XCTAssertNil(invalid)
    }
}
