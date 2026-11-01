import Foundation
import AVFoundation

public final class AudioEngine: @unchecked Sendable {
    public static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    public let voicePool = VoicePool()
    public let commandQueue = LockFreeQueue<NoteOnEvent>(capacity: 512)

    // Supports 32 audio slots (0..23 pads, 24..29 quick FX, 30..31 custom audition)
    public static let maxSamples = 32
    private var samples: [[Float]] = Array(repeating: [], count: maxSamples)
    private var eventSequence: UInt64 = 0
    private var isRunning: Bool = false

    // Real-time DSP FX Settings
    public var masterVolume: Float = 0.85
    public var echo116Level: Float = 0.0
    public var echo18Level: Float = 0.0
    public var reverbLevel: Float = 0.0
    public var distortionLevel: Float = 0.0
    public var filterCutoff: Float = 1.0 // 1.0 = wide open, < 1.0 = low pass
    public var lofiLevel: Float = 0.0

    // Delay circular buffer (44100 frames = 1 second)
    private var delayBufferL: [Float] = Array(repeating: 0, count: 44100)
    private var delayBufferR: [Float] = Array(repeating: 0, count: 44100)
    private var delayWriteIndex: Int = 0

    // Low pass filter state
    private var filterStateL: Float = 0
    private var filterStateR: Float = 0

    // Stress Test Mode
    private var isStressTestActive: Bool = false
    private var stressTestStartNs: UInt64 = 0
    private var stressLastTriggerNs: UInt64 = 0
    private var xrunCount: Int = 0

    // Audio Tap Callback for Recording
    public var audioTapHandler: (([Float], Int) -> Void)?

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
        guard padIndex >= 0 && padIndex < AudioEngine.maxSamples else { return false }
        eventSequence &+= 1
        let event = NoteOnEvent(padIndex: padIndex, timestamp: eventSequence)
        return commandQueue.push(event)
    }

    public func loadSample(padIndex: Int, data: [Float]) {
        guard padIndex >= 0 && padIndex < AudioEngine.maxSamples && !data.isEmpty else { return }
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

    public func triggerFill() {
        // Generates rapid rhythmic drum rolls on snare (2) and toms (18, 19)
        for i in 0..<4 {
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                self?.triggerPad(i % 2 == 0 ? 2 : 19)
            }
        }
    }

    public func triggerClean() {
        // Instantly dry the DSP chain
        echo116Level = 0.0
        echo18Level = 0.0
        distortionLevel = 0.0
        reverbLevel = 0.0
        lofiLevel = 0.0
        filterCutoff = 1.0
    }

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
                        eventSequence &+= 1
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

        // 3. Clear output pointers
        for i in 0..<frames {
            left[i] = 0.0
            right[i] = 0.0
        }

        // 4. Mix active voices
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

        // 5. Apply DSP Effects (Delay, Distortion, Filter, Lo-Fi, Reverb)
        let delay116Frames = 5512  // ~1/16 note at 120 BPM
        let delay18Frames  = 11025 // ~1/8 note at 120 BPM
        let delayBufSize = delayBufferL.count

        let dist = distortionLevel
        let cutoff = max(0.05, min(1.0, filterCutoff))
        let filterAlpha = 1.0 - exp(-2.0 * .pi * (cutoff * 16000.0) / 44100.0)
        let lofi = lofiLevel
        let echo116 = echo116Level
        let echo18 = echo18Level
        let reverb = reverbLevel
        let vol = masterVolume

        var tapBuffer: [Float]? = audioTapHandler != nil ? [Float](repeating: 0, count: frames * 2) : nil

        for i in 0..<frames {
            var l = left[i]
            var r = right[i]

            // Delay / Echo
            let writePos = (delayWriteIndex + i) % delayBufSize
            if echo116 > 0 || echo18 > 0 || reverb > 0 {
                let read116 = (writePos - delay116Frames + delayBufSize) % delayBufSize
                let read18  = (writePos - delay18Frames + delayBufSize) % delayBufSize

                let echoSignalL = delayBufferL[read116] * echo116 + delayBufferL[read18] * echo18
                let echoSignalR = delayBufferR[read116] * echo116 + delayBufferR[read18] * echo18

                l += echoSignalL
                r += echoSignalR

                // Reverb diffusion feedback
                let reverbFeedback = min(0.65, reverb * 0.6)
                delayBufferL[writePos] = left[i] + echoSignalL * 0.35 + delayBufferL[read18] * reverbFeedback
                delayBufferR[writePos] = right[i] + echoSignalR * 0.35 + delayBufferR[read18] * reverbFeedback
            } else {
                delayBufferL[writePos] = left[i]
                delayBufferR[writePos] = right[i]
            }

            // Distortion (Soft cubic overdrive)
            if dist > 0 {
                let drive = 1.0 + dist * 3.5
                l = tanh(l * drive)
                r = tanh(r * drive)
            }

            // Lo-Fi (Bit reduction & cassette warmth)
            if lofi > 0 {
                let steps = max(4.0, 32.0 * (1.0 - lofi * 0.85))
                l = round(l * Float(steps)) / Float(steps)
                r = round(r * Float(steps)) / Float(steps)
            }

            // Low-Pass Filter
            if cutoff < 0.98 {
                filterStateL += Float(filterAlpha) * (l - filterStateL)
                filterStateR += Float(filterAlpha) * (r - filterStateR)
                l = filterStateL
                r = filterStateR
            }

            // Master Volume
            l *= vol
            r *= vol

            // Soft Limiter / Anti-clipping
            if l > 1.0 { l = 1.0 - exp(-l) } else if l < -1.0 { l = -1.0 + exp(l) }
            if r > 1.0 { r = 1.0 - exp(-r) } else if r < -1.0 { r = -1.0 + exp(r) }

            left[i] = l
            right[i] = r

            if tapBuffer != nil {
                tapBuffer![i * 2] = l
                tapBuffer![i * 2 + 1] = r
            }
        }

        delayWriteIndex = (delayWriteIndex + frames) % delayBufSize

        if let tap = tapBuffer {
            audioTapHandler?(tap, frames)
        }
    }

    private func generateDefaultSamples() {
        let sampleRate = 44100.0
        let length = Int(sampleRate * 0.35)

        for p in 0..<AudioEngine.maxSamples {
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
        guard padIndex >= 0 && padIndex < AudioEngine.maxSamples else { return [] }
        return samples[padIndex]
    }
}
