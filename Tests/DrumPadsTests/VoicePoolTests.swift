import XCTest
@testable import DrumPadsApp

final class VoicePoolTests: XCTestCase {

    var pool: VoicePool!
    let dummySample: [Float] = Array(repeating: 0.5, count: 1000)

    override func setUp() {
        super.setUp()
        pool = VoicePool()
    }

    func testVoicePoolAllocation() {
        XCTAssertEqual(pool.activeVoiceCount, 0)

        let idx = pool.allocateVoice(padId: 0, sampleData: dummySample, timestamp: 100)
        XCTAssertTrue(idx >= 0 && idx < 32)
        XCTAssertEqual(pool.activeVoiceCount, 1)
        XCTAssertEqual(pool.voices[idx].padId, 0)
        XCTAssertTrue(pool.voices[idx].isActive)
    }

    func testVoicePoolAllocationUpTo32() {
        for i in 0..<32 {
            let idx = pool.allocateVoice(padId: i % 24, sampleData: dummySample, timestamp: 100 + UInt64(i))
            XCTAssertTrue(idx >= 0 && idx < 32)
        }
        XCTAssertEqual(pool.activeVoiceCount, 32, "Voice pool must cap strictly at 32 active voices")
    }

    func testVoiceStealingWhenFullAt32() {
        for i in 0..<32 {
            pool.allocateVoice(padId: i, sampleData: dummySample, timestamp: 1000 + UInt64(i))
        }
        XCTAssertEqual(pool.activeVoiceCount, 32)

        // Oldest voice has timestamp 1000 at index 0
        let oldestIndex = 0
        XCTAssertEqual(pool.voices[oldestIndex].triggerTimestamp, 1000)

        // Allocate 33rd voice
        let reusedIndex = pool.allocateVoice(padId: 99, sampleData: dummySample, timestamp: 2000)

        XCTAssertEqual(reusedIndex, oldestIndex, "Oldest voice must be stolen and reused")
        XCTAssertEqual(pool.activeVoiceCount, 32)
        XCTAssertEqual(pool.voices[reusedIndex].padId, 99)
        XCTAssertEqual(pool.voices[reusedIndex].triggerTimestamp, 2000)
    }

    func testVoiceDeactivationAfterRender() {
        let shortSample: [Float] = Array(repeating: 0.2, count: 128)
        let idx = pool.allocateVoice(padId: 3, sampleData: shortSample, timestamp: 10)
        XCTAssertEqual(pool.activeVoiceCount, 1)

        var output: [Float] = []
        pool.renderMixed(output: &output, numFrames: 256, numChannels: 2)

        XCTAssertEqual(pool.activeVoiceCount, 0, "Voice should deactivate once sample completes")
        XCTAssertFalse(pool.voices[idx].isActive)
    }

    func testVoicePoolReset() {
        for i in 0..<10 {
            pool.allocateVoice(padId: i, sampleData: dummySample, timestamp: UInt64(i))
        }
        XCTAssertEqual(pool.activeVoiceCount, 10)

        pool.reset()
        XCTAssertEqual(pool.activeVoiceCount, 0)
    }
}
