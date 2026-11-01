import Foundation

public struct Voice: Sendable {
    public var padId: Int = -1
    public var sampleData: [Float] = []
    public var totalFrames: Int = 0
    public var currentFrame: Int = 0
    public var isActive: Bool = false
    public var triggerTimestamp: UInt64 = 0

    public init() {}
}

public final class VoicePool: @unchecked Sendable {
    public static let maxVoices = 32
    public var voices: [Voice]

    public init() {
        self.voices = Array(repeating: Voice(), count: VoicePool.maxVoices)
    }

    /// Real-time safe voice allocation: zero heap allocations, zero locks, O(32) scan.
    @discardableResult
    public func allocateVoice(padId: Int, sampleData: [Float], timestamp: UInt64) -> Int {
        guard !sampleData.isEmpty else { return -1 }

        // 1. Search for first inactive voice
        var candidateIndex = -1
        for i in 0..<VoicePool.maxVoices {
            if !voices[i].isActive {
                candidateIndex = i
                break
            }
        }

        // 2. If all 32 are active: Voice Stealing policy (reuse the oldest voice)
        if candidateIndex == -1 {
            var oldestTimestamp = UInt64.max
            for i in 0..<VoicePool.maxVoices {
                if voices[i].triggerTimestamp < oldestTimestamp {
                    oldestTimestamp = voices[i].triggerTimestamp
                    candidateIndex = i
                }
            }
        }

        // 3. Initialize the voice slot
        if candidateIndex >= 0 && candidateIndex < VoicePool.maxVoices {
            voices[candidateIndex].padId = padId
            voices[candidateIndex].sampleData = sampleData
            voices[candidateIndex].totalFrames = sampleData.count
            voices[candidateIndex].currentFrame = 0
            voices[candidateIndex].isActive = true
            voices[candidateIndex].triggerTimestamp = timestamp
            return candidateIndex
        }

        return -1
    }

    /// Real-time safe audio mixing: mixes active voices into output buffer with soft-clipping.
    public func renderMixed(output: inout [Float], numFrames: Int, numChannels: Int = 2) {
        let totalSamples = numFrames * numChannels
        if output.count < totalSamples {
            output = Array(repeating: 0.0, count: totalSamples)
        } else {
            for i in 0..<totalSamples {
                output[i] = 0.0
            }
        }

        for v in 0..<VoicePool.maxVoices {
            guard voices[v].isActive else { continue }

            let total = voices[v].totalFrames
            let current = voices[v].currentFrame
            let remaining = total - current
            let framesToRender = min(numFrames, remaining)

            for i in 0..<framesToRender {
                let sample = voices[v].sampleData[current + i]
                if numChannels == 2 {
                    output[i * 2] += sample
                    output[i * 2 + 1] += sample
                } else {
                    output[i] += sample
                }
            }

            voices[v].currentFrame += framesToRender
            if voices[v].currentFrame >= total {
                voices[v].isActive = false
            }
        }

        // Soft-clip master output
        for i in 0..<totalSamples {
            let s = output[i]
            if s > 1.0 {
                output[i] = 1.0 - exp(-s)
            } else if s < -1.0 {
                output[i] = -1.0 + exp(s)
            }
        }
    }

    public var activeVoiceCount: Int {
        var count = 0
        for i in 0..<VoicePool.maxVoices {
            if voices[i].isActive { count += 1 }
        }
        return count
    }

    public func reset() {
        for i in 0..<VoicePool.maxVoices {
            voices[i].isActive = false
            voices[i].currentFrame = 0
            voices[i].padId = -1
        }
    }
}
