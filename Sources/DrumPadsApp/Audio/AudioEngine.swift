import Foundation
import AVFoundation

public final class AudioEngine: @unchecked Sendable {
    public static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    public let voicePool = VoicePool()
    public let commandQueue = LockFreeQueue<NoteOnEvent>(capacity: 256)

    private var samples: [[Float]] = Array(repeating: [], count: 24)
    private var eventSequence: UInt64 = 0
    private var isRunning: Bool = false

    private var isStressTestActive: Bool = false
    private var stressTestStartNs: UInt64 = 0
    private var stressLastTriggerNs: UInt64 = 0
    private var xrunCount: Int = 0

    public init() {
        generateDefaultSamples()
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let leftPtr = ablPointer[0].mData?.assumingMemoryBound(to: Float.self),
                  let rightPtr = ablPointer[1].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            // Real-time Audio Callback: Zero allocations, zero locks, zero file I/O!
            self.renderAudio(left: leftPtr, right: rightPtr, frames: Int(frameCount))
            return noErr
        }

        self.sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    public func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("[AudioEngine] Error starting AVAudioEngine: \(error.localizedDescription)")
        }
    }

    public func stop() {
        guard isRunning else { return }
        engine.stop()
        voicePool.reset()
        isRunning = false
    }

    @discardableResult
    public func triggerPad(_ padIndex: Int) -> Bool {
        guard padIndex >= 0 && padIndex < 24 else { return false }
        eventSequence += 1
        let event = NoteOnEvent(padIndex: padIndex, timestamp: eventSequence)
        return commandQueue.push(event)
    }

    public func loadSample(padIndex: Int, data: [Float]) {
        guard padIndex >= 0 && padIndex < 24 && !data.isEmpty else { return }
        samples[padIndex] = data
    }

    public func setStressTest(enabled: Bool) {
        isStressTestActive = enabled
        if enabled {
            stressTestStartNs = DispatchTime.now().uptimeNanoseconds
            stressLastTriggerNs = 0
            print("[AudioEngine] Stress Test Mode ENABLED (32 voices for 60s)")
        } else {
            print("[AudioEngine] Stress Test Mode DISABLED")
        }
    }

    public var isStressActive: Bool { isStressTestActive }
    public var currentXRunCount: Int { xrunCount }

    private func renderAudio(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: Int) {
        // 1. Stress test injection
        if isStressTestActive {
            let now = DispatchTime.now().uptimeNanoseconds
            let elapsedSec = (now - stressTestStartNs) / 1_000_000_000
            if elapsedSec < 60 {
                if (now - stressLastTriggerNs) > 200_000_000 {
                    stressLastTriggerNs = now
                    for v in 0..<VoicePool.maxVoices {
                        let pad = v % 24
                        let s = samples[pad]
                        eventSequence += 1
                        voicePool.allocateVoice(padId: pad, sampleData: s, timestamp: eventSequence)
                    }
                }
            } else {
                isStressTestActive = false
            }
        }

        // 2. Consume NoteOn commands from lock-free queue
        while let event = commandQueue.pop() {
            let sample = samples[event.padIndex]
            if !sample.isEmpty {
                voicePool.allocateVoice(padId: event.padIndex, sampleData: sample, timestamp: event.timestamp)
            }
        }

        // 3. Mix voices directly into output pointer buffers
        for i in 0..<frames {
            left[i] = 0.0
            right[i] = 0.0
        }

        for v in 0..<VoicePool.maxVoices {
            guard voicePool.voices[v].isActive else { continue }
            let total = voicePool.voices[v].totalFrames
            let current = voicePool.voices[v].currentFrame
            let remaining = total - current
            let renderFrames = min(frames, remaining)

            for i in 0..<renderFrames {
                let s = voicePool.voices[v].sampleData[current + i]
                left[i] += s
                right[i] += s
            }

            voicePool.voices[v].currentFrame += renderFrames
            if voicePool.voices[v].currentFrame >= total {
                voicePool.voices[v].isActive = false
            }
        }

        // Soft-clip output
        for i in 0..<frames {
            var l = left[i]
            var r = right[i]
            if l > 1.0 { l = 1.0 - exp(-l) } else if l < -1.0 { l = -1.0 + exp(l) }
            if r > 1.0 { r = 1.0 - exp(-r) } else if r < -1.0 { r = -1.0 + exp(r) }
            left[i] = l
            right[i] = r
        }
    }

    private func generateDefaultSamples() {
        let sampleRate = 44100.0
        let length = Int(sampleRate * 0.35)

        for p in 0..<24 {
            var buffer = [Float](repeating: 0, count: length)
            let freq = 100.0 + Double(p) * 20.0
            for i in 0..<length {
                let t = Double(i) / sampleRate
                let wave = sin(2.0 * .pi * freq * t) * exp(-t * 6.0)
                buffer[i] = Float(wave)
            }
            samples[p] = buffer
        }
    }

    public func getSample(at padIndex: Int) -> [Float] {
        guard padIndex >= 0 && padIndex < 24 else { return [] }
        return samples[padIndex]
    }
}
