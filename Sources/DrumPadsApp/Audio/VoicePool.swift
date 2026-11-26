import Foundation

public struct Voice: Sendable {
    public var padId: Int = -1
    public var sampleData: [Float] = []
    public var fractionalPos: Double = 0.0
    public var playbackRate: Double = 1.0
    public var startFrame: Int = 0
    public var endFrame: Int = 0
    public var fadeInFrames: Int = 0
    public var fadeOutFrames: Int = 0
    public var gainLeft: Float = 1.0
    public var gainRight: Float = 1.0
    public var isLoop: Bool = false
    public var isHold: Bool = false
    public var chokeGroup: Int = 0
    public var padDistortion: Float = 0.0
    public var padReverbSend: Float = 0.0
    public var isActive: Bool = false
    public var triggerTimestamp: UInt64 = 0

    public init() {}
}

public final class VoicePool: @unchecked Sendable {
    public static let maxVoices = 32
    public private(set) var voices: [Voice]

    public init() {
        self.voices = Array(repeating: Voice(), count: Self.maxVoices)
    }

    public var activeVoiceCount: Int {
        voices.reduce(0) { $0 + ($1.isActive ? 1 : 0) }
    }

    @discardableResult
    public func allocateVoice(
        padId: Int,
        sampleData: [Float],
        timestamp: UInt64,
        pitchRatio: Double = 1.0,
        volume: Float = 1.0,
        pan: Float = 0.0,
        trimStart: Float = 0.0,
        trimEnd: Float = 1.0,
        fadeInRatio: Float = 0.0,
        fadeOutRatio: Float = 0.0,
        isLoop: Bool = false,
        isHold: Bool = false,
        chokeGroup: Int = 0,
        padDistortion: Float = 0.0,
        padReverbSend: Float = 0.0
    ) -> Int {
        guard !sampleData.isEmpty else { return -1 }

        // Choke group mutually exclusive cutoff
        if chokeGroup > 0 {
            for i in 0..<Self.maxVoices where voices[i].isActive && voices[i].chokeGroup == chokeGroup {
                voices[i].isActive = false
            }
        }

        // Toggle off existing HOLD/LOOP voice if re-triggered on loop toggle
        if isLoop {
            var toggledOff = false
            for i in 0..<Self.maxVoices where voices[i].isActive && voices[i].padId == padId && voices[i].isLoop {
                voices[i].isActive = false
                toggledOff = true
            }
            if toggledOff { return -1 }
        }

        var targetIndex = -1
        var oldestIndex = 0
        var oldestTimestamp = UInt64.max

        for i in 0..<Self.maxVoices {
            if !voices[i].isActive {
                targetIndex = i
                break
            }
            if voices[i].triggerTimestamp < oldestTimestamp {
                oldestTimestamp = voices[i].triggerTimestamp
                oldestIndex = i
            }
        }

        if targetIndex == -1 {
            targetIndex = oldestIndex
        }

        let total = sampleData.count
        let clampedStart = max(0.0, min(0.95, Double(trimStart)))
        let clampedEnd = max(clampedStart + 0.02, min(1.0, Double(trimEnd)))
        let sFrame = max(0, min(total - 1, Int(clampedStart * Double(total))))
        let eFrame = max(sFrame + 1, min(total, Int(clampedEnd * Double(total))))
        let span = max(1, eFrame - sFrame)

        let fIn = Int(max(0.0, min(0.5, Double(fadeInRatio))) * Double(span))
        let fOut = Int(max(0.0, min(0.5, Double(fadeOutRatio))) * Double(span))

        let clampedPan = max(-1.0, min(1.0, pan))
        let angle = (Double(clampedPan) + 1.0) * (.pi / 4.0)
        let gL = volume * Float(cos(angle)) * 1.414
        let gR = volume * Float(sin(angle)) * 1.414

        voices[targetIndex].padId = padId
        voices[targetIndex].sampleData = sampleData
        voices[targetIndex].fractionalPos = Double(sFrame)
        voices[targetIndex].playbackRate = max(0.25, min(4.0, pitchRatio))
        voices[targetIndex].startFrame = sFrame
        voices[targetIndex].endFrame = eFrame
        voices[targetIndex].fadeInFrames = fIn
        voices[targetIndex].fadeOutFrames = fOut
        voices[targetIndex].gainLeft = gL
        voices[targetIndex].gainRight = gR
        voices[targetIndex].isLoop = isLoop
        voices[targetIndex].isHold = isHold
        voices[targetIndex].chokeGroup = chokeGroup
        voices[targetIndex].padDistortion = padDistortion
        voices[targetIndex].padReverbSend = padReverbSend
        voices[targetIndex].isActive = true
        voices[targetIndex].triggerTimestamp = timestamp

        return targetIndex
    }

    public func releasePad(padId: Int) {
        for i in 0..<Self.maxVoices {
            if voices[i].isActive && voices[i].padId == padId && (voices[i].isHold || voices[i].isLoop) {
                voices[i].isActive = false
            }
        }
    }

    public func renderMixed(
        output: inout [Float],
        numFrames: Int,
        numChannels: Int,
        masterPitchRatio: Double = 1.0,
        reverbSendOut: inout [Float]
    ) {
        let totalSamples = numFrames * numChannels
        if output.count < totalSamples {
            output = Array(repeating: 0.0, count: totalSamples)
        } else {
            for i in 0..<totalSamples { output[i] = 0.0 }
        }
        if reverbSendOut.count < numFrames {
            reverbSendOut = Array(repeating: 0.0, count: numFrames)
        } else {
            for i in 0..<numFrames { reverbSendOut[i] = 0.0 }
        }

        for v in 0..<Self.maxVoices {
            if !voices[v].isActive { continue }
            let rate = voices[v].playbackRate * masterPitchRatio
            let sFrame = voices[v].startFrame
            let eFrame = voices[v].endFrame
            let fIn = voices[v].fadeInFrames
            let fOut = voices[v].fadeOutFrames
            let padDist = voices[v].padDistortion
            let padRev = voices[v].padReverbSend

            for f in 0..<numFrames {
                let pos = voices[v].fractionalPos
                let idx0 = Int(pos)
                if idx0 >= eFrame {
                    if voices[v].isLoop || voices[v].isHold {
                        voices[v].fractionalPos = Double(sFrame)
                    } else {
                        voices[v].isActive = false
                        break
                    }
                }

                let curIdx = Int(voices[v].fractionalPos)
                if curIdx < sFrame || curIdx >= eFrame {
                    if voices[v].isLoop || voices[v].isHold {
                        voices[v].fractionalPos = Double(sFrame)
                        continue
                    } else {
                        voices[v].isActive = false
                        break
                    }
                }
                let nextIdx = min(eFrame - 1, curIdx + 1)
                let frac = Float(voices[v].fractionalPos - Double(curIdx))
                let s0 = voices[v].sampleData[curIdx]
                let s1 = voices[v].sampleData[nextIdx]
                var sample = s0 + (s1 - s0) * frac

                // Trim Fade In / Out envelope
                let relPos = curIdx - sFrame
                let remPos = eFrame - curIdx
                if fIn > 0 && relPos < fIn {
                    sample *= Float(relPos) / Float(fIn)
                }
                if fOut > 0 && remPos < fOut {
                    sample *= Float(remPos) / Float(fOut)
                }

                // Per-pad overdrive distortion
                if padDist > 0.01 {
                    let drive = 1.0 + padDist * 10.0
                    sample = tanh(sample * drive) / tanh(drive)
                }

                let outL = sample * voices[v].gainLeft
                let outR = sample * voices[v].gainRight

                if numChannels >= 2 {
                    output[f * numChannels] += outL
                    output[f * numChannels + 1] += outR
                } else {
                    output[f] += (outL + outR) * 0.5
                }

                if padRev > 0.001 {
                    reverbSendOut[f] += sample * padRev
                }

                voices[v].fractionalPos += rate
                if Int(voices[v].fractionalPos) >= eFrame {
                    if voices[v].isLoop || voices[v].isHold {
                        voices[v].fractionalPos = Double(sFrame)
                    } else {
                        voices[v].isActive = false
                        break
                    }
                }
            }
        }
    }

    public func renderMixed(output: inout [Float], numFrames: Int, numChannels: Int) {
        var dummyRev: [Float] = []
        renderMixed(output: &output, numFrames: numFrames, numChannels: numChannels, masterPitchRatio: 1.0, reverbSendOut: &dummyRev)
    }

    public func reset() {
        for i in 0..<Self.maxVoices {
            voices[i].isActive = false
            voices[i].fractionalPos = 0.0
            voices[i].padId = -1
        }
    }
}
