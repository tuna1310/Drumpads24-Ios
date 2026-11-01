import XCTest
@testable import DrumPadsApp

final class EmptyFixtureTests: XCTestCase {

    struct EmptyFixture: Codable {
        let schemaVersion: Int
        let description: String
        let ppq: Int
        let testCases: [String]
    }

    func testParseEmptyFixtureWithoutError() throws {
        let candidatePaths = [
            "fixtures/test-vectors/sequencer-test-vectors.empty.json",
            "Tests/DrumPadsTests/fixtures/test-vectors/sequencer-test-vectors.empty.json",
            "../shared-specs/fixtures/test-vectors/sequencer-test-vectors.empty.json",
            "../../shared-specs/fixtures/test-vectors/sequencer-test-vectors.empty.json",
            "shared-specs/fixtures/test-vectors/sequencer-test-vectors.empty.json"
        ]

        var data: Data?
        #if SWIFT_PACKAGE
        if let moduleUrl = Bundle.module.url(forResource: "sequencer-test-vectors.empty", withExtension: "json") {
            data = try? Data(contentsOf: moduleUrl)
        }
        #endif

        if data == nil {
            for path in candidatePaths {
                if let d = FileManager.default.contents(atPath: path) {
                    data = d
                    break
                }
            }
        }

        XCTAssertNotNil(data, "Fixture file sequencer-test-vectors.empty.json must be readable")
        guard let validData = data else { return }

        let decoder = JSONDecoder()
        let fixture = try decoder.decode(EmptyFixture.self, from: validData)

        XCTAssertEqual(fixture.schemaVersion, 1)
        XCTAssertEqual(fixture.ppq, 960)
        XCTAssertTrue(fixture.testCases.isEmpty)
    }
}
