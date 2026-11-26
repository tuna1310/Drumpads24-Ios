import Foundation
import AVFoundation

public final class AudioEngine: @unchecked Sendable {
    public static let shared = AudioEngine()

    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let voicePool = VoicePool()
    private var sampleBuffers: [Int: [Float]] = [:]
    private var padConfigs: [Int: Pad] = [:]
    private let lock = NSLock()
    private var triggerSeq: UInt64 = 0

    public var isRunning: Bool = false
    public var currentPeakLevel: Float = 0.0

    // 10 Real-Time Master DSP Effect Parameters
    public var masterVolume: Float = 1.0
    public var lofiLevel: Float = 0.0         // Bitcrush / Sample Rate Decimation
    public var filterCutoff: Float = 1.0      // Resonant Low-Pass SVF Filter (0..1)
    public var masterPitchSemitones: Float = 0.0 // -12..+12
    public var reverbLevel: Float = 0.0       // 4-comb Schroeder Reverb
    public var echo116Level: Float = 0.0      // BPM-synced 1/16 Delay
    public var echo18Level: Float = 0.0       // BPM-synced 1/8 Delay
    public var distortionLevel: Float = 0.0   // Waveshaper Overdrive
    public var gateLevel: Float = 0.0         // Rhythmic Trance Gate
    public var wobbleLevel: Float = 0.0       // LFO Filter Modulation

    public var bpm: Int = 128

    // Delay & Schroeder Reverb DSP State (44100 Hz)
    private let sampleRate: Double = 44100.0
    private var delayBufferL = [Float](repeating: 0.0, count: 44100 * 2)
    private var delayBufferR = [Float](repeating: 0.0, count: 44100 * 2)
    private var delayWritePos = 0

    // 4 Parallel Comb Filters for rich studio Reverb
    private let combLengths = [1116, 1188, 1277, 1356]
    private var combBuffersL: [[Float]]
    private var combBuffersR: [[Float]]
    private var combPositions = [0, 0, 0, 0]

    // State Variable Filter (SVF) & LFO
    private var filterLpfL: Float = 0.0
    private var filterBpfL: Float = 0.0
    private var filterLpfR: Float = 0.0
    private var filterBpfR: Float = 0.0
    private var lfoPhase: Double = 0.0
    private var gatePhase: Double = 0.0

    // Bitcrusher / Lo-Fi state
    private var lofiHoldL: Float = 0.0
    private var lofiHoldR: Float = 0.0
    private var lofiCounter: Int = 0

    // Reusable mixing scratch buffers
    private var renderBuffer = [Float](repeating: 0.0, count: 4096)
    private var reverbSendBuffer = [Float](repeating: 0.0, count: 2048)

    public var audioTapHandler: (([Float], Int) -> Void)?

    public init() {
        self.combBuffersL = combLengths.map { [Float](repeating: 0.0, count: $0) }
        self.combBuffersR = combLengths.map { [Float](repeating: 0.0, count: $0 + 23) }
        generateDefaultSamples()
    }

    public func generateDefaultSamples(genre: MusicGenre = .edm, packId: String = "") {
        lock.lock()
        let generated = GenreSampleSynthesizer.generatePackSamples(genre: genre, packId: packId, sampleRate: sampleRate)
        for (idx, buf) in generated {
            sampleBuffers[idx] = buf
        }
        lock.unlock()
    }

    public func loadPackSamples(pads: [Pad], genre: MusicGenre, packId: String = "") {
        let generated = GenreSampleSynthesizer.generatePackSamples(genre: genre, packId: packId, sampleRate: sampleRate)
        lock.lock()
        for pad in pads {
            padConfigs[pad.index] = pad
            if let customURL = pad.customSampleURL, let loaded = decodeAudioFile(url: customURL) {
                sampleBuffers[pad.index] = loaded
            } else if let buf = generated[pad.index] {
                sampleBuffers[pad.index] = buf
            }
        }
        lock.unlock()
    }

    public func updatePad(_ pad: Pad) {
        lock.lock()
        padConfigs[pad.index] = pad
        if let customURL = pad.customSampleURL, let loaded = decodeAudioFile(url: customURL) {
            sampleBuffers[pad.index] = loaded
        }
        lock.unlock()
    }

    public func setSampleBuffer(padIndex: Int, buffer: [Float]) {
        lock.lock()
        sampleBuffers[padIndex] = buffer
        lock.unlock()
    }

    public func getSampleBuffer(padIndex: Int) -> [Float]? {
        lock.lock()
        let buf = sampleBuffers[padIndex]
        lock.unlock()
        return buf
    }

    public func start() {
        guard !isRunning else { return }

        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005)
            try session.setPreferredSampleRate(sampleRate)
            try session.setActive(true)
        } catch {
            print("[AudioEngine] Failed to configure AVAudioSession: \(error)")
        }
        #endif

        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 2, interleaved: false)!

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let frames = Int(frameCount)
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let outL = ablPointer[0].mData?.assumingMemoryBound(to: Float.self)
            let outR = ablPointer.count > 1 ? ablPointer[1].mData?.assumingMemoryBound(to: Float.self) : outL

            self.lock.lock()
            let needed = frames * 2
            if self.renderBuffer.count < needed {
                self.renderBuffer = [Float](repeating: 0.0, count: needed)
            }
            if self.reverbSendBuffer.count < frames {
                self.reverbSendBuffer = [Float](repeating: 0.0, count: frames)
            }

            let pitchRatio = pow(2.0, Double(self.masterPitchSemitones) / 12.0)
            self.voicePool.renderMixed(
                output: &self.renderBuffer,
                numFrames: frames,
                numChannels: 2,
                masterPitchRatio: pitchRatio,
                reverbSendOut: &self.reverbSendBuffer
            )

            let delayFrames116 = max(256, min(self.delayBufferL.count - 1, Int((60.0 / Double(max(40, self.bpm)) / 4.0) * self.sampleRate)))
            let delayFrames18 = max(256, min(self.delayBufferL.count - 1, Int((60.0 / Double(max(40, self.bpm)) / 2.0) * self.sampleRate)))

            var blockPeak: Float = 0.0
            let gateStepFreq = Double(max(40, self.bpm)) / 60.0 * 4.0

            for f in 0..<frames {
                var l = self.renderBuffer[f * 2]
                var r = self.renderBuffer[f * 2 + 1]

                // 1. Distortion
                if self.distortionLevel > 0.01 {
                    let drive = 1.0 + self.distortionLevel * 14.0
                    let norm = tanh(drive)
                    l = tanh(l * drive) / norm
                    r = tanh(r * drive) / norm
                }

                // 2. Lo-Fi Bitcrusher + Sample Rate Hold
                if self.lofiLevel > 0.01 {
                    let decimate = max(1, Int(1 + self.lofiLevel * 12))
                    if self.lofiCounter % decimate == 0 {
                        let levels = max(4.0, 64.0 * (1.0 - self.lofiLevel * 0.88))
                        self.lofiHoldL = round(l * levels) / levels
                        self.lofiHoldR = round(r * levels) / levels
                    }
                    self.lofiCounter += 1
                    l = l * (1.0 - self.lofiLevel) + self.lofiHoldL * self.lofiLevel
                    r = r * (1.0 - self.lofiLevel) + self.lofiHoldR * self.lofiLevel
                }

                // 3. Resonant Low-Pass SVF Filter + Wobble LFO
                self.lfoPhase += 2.0 * .pi * (Double(max(40, self.bpm)) / 60.0 * 2.0) / self.sampleRate
                if self.lfoPhase > 2.0 * .pi { self.lfoPhase -= 2.0 * .pi }
                let wobbleMod = self.wobbleLevel > 0.01 ? Float(0.5 + 0.5 * sin(self.lfoPhase)) * self.wobbleLevel * 0.65 : 0.0
                let effectiveCutoff = max(0.05, min(1.0, self.filterCutoff - wobbleMod))

                if effectiveCutoff < 0.98 || self.wobbleLevel > 0.01 {
                    let fCoeff = min(0.85, 0.03 + pow(effectiveCutoff, 2.0) * 0.78)
                    let qRes: Float = 0.55 - (self.wobbleLevel * 0.25)

                    let hpL = l - self.filterLpfL - qRes * self.filterBpfL
                    self.filterBpfL += fCoeff * hpL
                    self.filterLpfL += fCoeff * self.filterBpfL
                    l = self.filterLpfL

                    let hpR = r - self.filterLpfR - qRes * self.filterBpfR
                    self.filterBpfR += fCoeff * hpR
                    self.filterLpfR += fCoeff * self.filterBpfR
                    r = self.filterLpfR
                }

                // 4. Rhythmic Gate
                if self.gateLevel > 0.01 {
                    self.gatePhase += gateStepFreq / self.sampleRate
                    if self.gatePhase >= 1.0 { self.gatePhase -= 1.0 }
                    let gateGain: Float = (self.gatePhase < (1.0 - Double(self.gateLevel) * 0.55)) ? 1.0 : 0.08
                    l *= gateGain
                    r *= gateGain
                }

                // 5. BPM-Synced Delay (1/16 & 1/8)
                let bufLen = self.delayBufferL.count
                let read116 = (self.delayWritePos - delayFrames116 + bufLen) % bufLen
                let read18 = (self.delayWritePos - delayFrames18 + bufLen) % bufLen

                let d116L = self.delayBufferL[read116] * self.echo116Level * 0.55
                let d116R = self.delayBufferR[read116] * self.echo116Level * 0.55
                let d18L = self.delayBufferL[read18] * self.echo18Level * 0.55
                let d18R = self.delayBufferR[read18] * self.echo18Level * 0.55

                self.delayBufferL[self.delayWritePos] = max(-1.5, min(1.5, l + (d116R + d18R) * 0.42))
                self.delayBufferR[self.delayWritePos] = max(-1.5, min(1.5, r + (d116L + d18L) * 0.42))
                self.delayWritePos = (self.delayWritePos + 1) % bufLen

                l += d116L + d18L
                r += d116R + d18R

                // 6. 4-Comb Schroeder Reverb (Master + Per-pad send)
                let revInL = l * self.reverbLevel + self.reverbSendBuffer[f]
                let revInR = r * self.reverbLevel + self.reverbSendBuffer[f]
                if self.reverbLevel > 0.01 || abs(self.reverbSendBuffer[f]) > 0.001 {
                    var wetL: Float = 0.0
                    var wetR: Float = 0.0
                    for c in 0..<4 {
                        let cIdxL = self.combPositions[c] % self.combBuffersL[c].count
                        let cIdxR = self.combPositions[c] % self.combBuffersR[c].count
                        let outCL = self.combBuffersL[c][cIdxL]
                        let outCR = self.combBuffersR[c][cIdxR]
                        wetL += outCL
                        wetR += outCR
                        self.combBuffersL[c][cIdxL] = revInL * 0.32 + outCL * 0.72
                        self.combBuffersR[c][cIdxR] = revInR * 0.32 + outCR * 0.72
                        self.combPositions[c] += 1
                    }
                    l += wetL * 0.25
                    r += wetR * 0.25
                }

                // 7. Master Volume & Soft Limiter
                l = tanh(l * self.masterVolume)
                r = tanh(r * self.masterVolume)

                self.renderBuffer[f * 2] = l
                self.renderBuffer[f * 2 + 1] = r
                blockPeak = max(blockPeak, max(abs(l), abs(r)))

                outL?[f] = l
                outR?[f] = r
            }

            self.currentPeakLevel = self.currentPeakLevel * 0.75 + blockPeak * 0.25
            let tap = self.audioTapHandler
            let slice = tap != nil ? Array(self.renderBuffer.prefix(needed)) : []
            self.lock.unlock()

            if let tap = tap {
                tap(slice, frames)
            }

            return noErr
        }

        self.sourceNode = node
        engine.attach(node)
        engine.connect(node, to: mainMixer, format: format)

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("[AudioEngine] Failed to start AVAudioEngine: \(error)")
        }
    }

    public func stop() {
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        engine.stop()
        isRunning = false
    }

    public func triggerPad(padIndex: Int) {
        if !isRunning { start() }
        lock.lock()
        guard let buffer = sampleBuffers[padIndex] else {
            lock.unlock()
            return
        }
        let cfg = padConfigs[padIndex]
        triggerSeq += 1
        let rate = pow(2.0, Double(cfg?.pitch ?? 0.0) / 12.0)
        voicePool.allocateVoice(
            padId: padIndex,
            sampleData: buffer,
            timestamp: triggerSeq,
            pitchRatio: rate,
            volume: cfg?.volume ?? 1.0,
            pan: cfg?.pan ?? 0.0,
            trimStart: cfg?.trimStart ?? 0.0,
            trimEnd: cfg?.trimEnd ?? 1.0,
            fadeInRatio: cfg?.fadeInRatio ?? 0.0,
            fadeOutRatio: cfg?.fadeOutRatio ?? 0.0,
            isLoop: cfg?.playMode == .loop,
            isHold: cfg?.playMode == .hold,
            chokeGroup: cfg?.chokeGroup ?? 0,
            padDistortion: cfg?.padDistortion ?? 0.0,
            padReverbSend: cfg?.padReverbSend ?? 0.0
        )
        lock.unlock()
    }

    public func releasePad(padIndex: Int) {
        lock.lock()
        voicePool.releasePad(padId: padIndex)
        lock.unlock()
    }

    public func stopAllVoices() {
        lock.lock()
        voicePool.reset()
        lock.unlock()
    }

    public func playMetronomeClick(accent: Bool) {
        if !isRunning { start() }
        let len = Int(sampleRate * 0.045)
        var click = [Float](repeating: 0.0, count: len)
        let freq = accent ? 1600.0 : 1000.0
        for i in 0..<len {
            let t = Double(i) / sampleRate
            click[i] = Float(sin(2.0 * .pi * freq * t) * exp(-t * 95.0) * (accent ? 0.65 : 0.4))
        }
        lock.lock()
        triggerSeq += 1
        voicePool.allocateVoice(padId: -99, sampleData: click, timestamp: triggerSeq)
        lock.unlock()
    }

    public func triggerFill() {
        let sequence = [0, 4, 2, 4, 0, 2, 3, 5]
        for (idx, pad) in sequence.enumerated() {
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + Double(idx) * 0.09) { [weak self] in
                self?.triggerPad(padIndex: pad)
            }
        }
    }

    public func triggerClean() {
        lock.lock()
        voicePool.reset()
        lofiLevel = 0.0
        filterCutoff = 1.0
        masterPitchSemitones = 0.0
        reverbLevel = 0.0
        echo116Level = 0.0
        echo18Level = 0.0
        distortionLevel = 0.0
        gateLevel = 0.0
        wobbleLevel = 0.0
        lock.unlock()
    }

    // MARK: - Audio File Import & Waveform Processing
    public func decodeAudioFile(url: URL) -> [Float]? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let srcFormat = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0 else { return nil }
        guard let pcm = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: frameCount) else { return nil }
        do {
            try file.read(into: pcm)
        } catch {
            return nil
        }
        guard let chData = pcm.floatChannelData else { return nil }
        let len = Int(pcm.frameLength)
        var mono = [Float](repeating: 0.0, count: len)
        let channels = Int(srcFormat.channelCount)
        for i in 0..<len {
            var sum: Float = 0.0
            for c in 0..<channels {
                sum += chData[c][i]
            }
            mono[i] = sum / Float(max(1, channels))
        }
        // Simple linear resample if source sampleRate != 44100
        let ratio = srcFormat.sampleRate / sampleRate
        if abs(ratio - 1.0) > 0.01 {
            let outLen = max(1, Int(Double(len) / ratio))
            var resampled = [Float](repeating: 0.0, count: outLen)
            for i in 0..<outLen {
                let srcPos = Double(i) * ratio
                let idx0 = min(len - 1, Int(srcPos))
                let idx1 = min(len - 1, idx0 + 1)
                let frac = Float(srcPos - Double(idx0))
                resampled[i] = mono[idx0] + (mono[idx1] - mono[idx0]) * frac
            }
            return resampled
        }
        return mono
    }

    public static func computeWaveformPeaks(samples: [Float], bins: Int = 56) -> [Float] {
        guard !samples.isEmpty, bins > 0 else { return Array(repeating: 0.1, count: max(1, bins)) }
        let chunk = max(1, samples.count / bins)
        var peaks = [Float](repeating: 0.08, count: bins)
        for b in 0..<bins {
            let start = b * chunk
            let end = min(samples.count, start + chunk)
            if start >= samples.count { break }
            var mx: Float = 0.0
            for i in start..<end {
                mx = max(mx, abs(samples[i]))
            }
            peaks[b] = max(0.08, min(1.0, mx))
        }
        return peaks
    }

    public static func cropAndFade(
        samples: [Float],
        trimStart: Float,
        trimEnd: Float,
        fadeInRatio: Float,
        fadeOutRatio: Float
    ) -> [Float] {
        guard !samples.isEmpty else { return samples }
        let total = samples.count
        let s = max(0, min(total - 1, Int(Double(trimStart) * Double(total))))
        let e = max(s + 1, min(total, Int(Double(trimEnd) * Double(total))))
        var sliced = Array(samples[s..<e])
        let len = sliced.count
        let fIn = Int(Double(max(0, min(0.5, fadeInRatio))) * Double(len))
        let fOut = Int(Double(max(0, min(0.5, fadeOutRatio))) * Double(len))
        if fIn > 0 {
            for i in 0..<min(fIn, len) {
                sliced[i] *= Float(i) / Float(fIn)
            }
        }
        if fOut > 0 {
            for i in 0..<min(fOut, len) {
                let idx = len - 1 - i
                sliced[idx] *= Float(i) / Float(fOut)
            }
        }
        return sliced
    }
}
