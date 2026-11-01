import Foundation
import Observation

@Observable
public final class DrumPadsStore {
    public let pads: [Pad]
    public var activePads: Set<Int> = []
    public var isHapticEnabled: Bool = true
    public var isStressTestActive: Bool = false
    public var stressSecondsRemaining: Int = 0
    public var xrunCount: Int = 0
    public var isSettingsPresented: Bool = false

    private let audioEngine: AudioEngine
    private let hapticService: HapticService
    private var stressTimer: Timer?

    public init(
        padRepository: PadRepositoryProtocol = DefaultPadRepository.shared,
        audioEngine: AudioEngine = AudioEngine.shared,
        hapticService: HapticService = HapticService.shared
    ) {
        self.pads = padRepository.getPads()
        self.audioEngine = audioEngine
        self.hapticService = hapticService

        audioEngine.start()
        loadStarterWavs()
    }

    public func onPadDown(_ padIndex: Int) {
        audioEngine.triggerPad(padIndex)
        if isHapticEnabled {
            hapticService.playPadHaptic()
        }
        activePads.insert(padIndex)
    }

    public func onPadUp(_ padIndex: Int) {
        activePads.remove(padIndex)
    }

    public func setHapticEnabled(_ enabled: Bool) {
        self.isHapticEnabled = enabled
    }

    public func toggleSettings(_ show: Bool) {
        self.isSettingsPresented = show
    }

    public func setStressTest(_ enabled: Bool) {
        stressTimer?.invalidate()
        audioEngine.setStressTest(enabled: enabled)
        isStressTestActive = enabled

        if enabled {
            stressSecondsRemaining = 60
            stressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if self.stressSecondsRemaining > 0 {
                    self.stressSecondsRemaining -= 1
                    self.xrunCount = self.audioEngine.currentXRunCount
                } else {
                    timer.invalidate()
                    self.audioEngine.setStressTest(enabled: false)
                    self.isStressTestActive = false
                }
            }
        } else {
            stressSecondsRemaining = 0
        }
    }

    private func loadStarterWavs() {
        for pad in pads {
            if let url = findResourceURL(for: pad.sampleFile) {
                if let pcm = loadWavFloatBuffer(from: url) {
                    audioEngine.loadSample(padIndex: pad.index, data: pcm)
                }
            }
        }
    }

    private func findResourceURL(for path: String) -> URL? {
        if let url = Bundle.main.url(forResource: path, withExtension: nil) {
            return url
        }
        let filename = (path as NSString).lastPathComponent
        if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
            return url
        }
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: path, withExtension: nil) {
            return url
        }
        if let url = Bundle.module.url(forResource: filename, withExtension: nil) {
            return url
        }
        #endif
        return nil
    }

    private func loadWavFloatBuffer(from url: URL) -> [Float]? {
        guard let data = try? Data(contentsOf: url), data.count >= 44 else { return nil }
        // Basic RIFF WAV data parser
        var offset = 12
        while offset + 8 <= data.count {
            let chunkId = String(data: data.subdata(in: offset..<offset+4), encoding: .ascii) ?? ""
            let chunkSize = data.subdata(in: offset+4..<offset+8).withUnsafeBytes { $0.load(as: UInt32.self) }
            if chunkId == "data" {
                let dataStart = offset + 8
                let numSamples = Int(min(chunkSize, UInt32(data.count - dataStart))) / 2
                var floatSamples = [Float](repeating: 0, count: numSamples)
                data.subdata(in: dataStart..<dataStart + numSamples * 2).withUnsafeBytes { rawPtr in
                    let shorts = rawPtr.bindMemory(to: Int16.self)
                    for i in 0..<numSamples {
                        floatSamples[i] = Float(shorts[i]) / 32768.0
                    }
                }
                return floatSamples
            }
            offset += 8 + Int(chunkSize)
        }
        return nil
    }

    deinit {
        stressTimer?.invalidate()
        audioEngine.stop()
    }
}
