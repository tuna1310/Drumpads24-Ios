import Foundation
import AVFoundation

public final class AudioRecorder: @unchecked Sendable {
    public static let shared = AudioRecorder()

    private var recordedPcmData: [Int16] = []
    private var recordedEvents: [RecordedPadEvent] = []
    private let lock = NSLock()
    private var isRecordingInternal: Bool = false
    private var recordingStartTime: Date?
    private var micRecorder: AVAudioRecorder?
    private var micURL: URL?

    public init() {}

    public func startRecording(with audioEngine: AudioEngine) {
        lock.lock()
        recordedPcmData.removeAll(keepingCapacity: true)
        recordedEvents.removeAll(keepingCapacity: true)
        isRecordingInternal = true
        recordingStartTime = Date()
        lock.unlock()

        audioEngine.audioTapHandler = { [weak self] interleavedStereo, _ in
            guard let self = self, self.isRecordingInternal else { return }
            self.lock.lock()
            for sample in interleavedStereo {
                let clamped = max(-1.0, min(1.0, sample))
                self.recordedPcmData.append(Int16(clamped * 32767.0))
            }
            self.lock.unlock()
        }
    }

    public func recordPadHit(_ padIndex: Int) {
        lock.lock()
        defer { lock.unlock() }
        guard isRecordingInternal, let start = recordingStartTime else { return }
        let ms = Int64(Date().timeIntervalSince(start) * 1000.0)
        recordedEvents.append(RecordedPadEvent(padIndex: padIndex, timestampMs: ms))
    }

    public func stopRecording(
        with audioEngine: AudioEngine,
        title: String = "Beat Session",
        packName: String = "FESTIVAL EDM",
        bpm: Int = 128
    ) -> RecordingItem? {
        lock.lock()
        isRecordingInternal = false
        audioEngine.audioTapHandler = nil
        let pcmCopy = recordedPcmData
        let eventsCopy = recordedEvents
        let durationMs = Int64((Double(pcmCopy.count / 2) / 44100.0) * 1000.0)
        let durationSec = max(1, Int(durationMs / 1000))
        lock.unlock()

        guard !pcmCopy.isEmpty else { return nil }

        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let filename = "DrumPads_\(Int(Date().timeIntervalSince1970)).wav"
        let fileURL = recordingsDir.appendingPathComponent(filename)

        if Self.writeWavFile(to: fileURL, pcm: pcmCopy, sampleRate: 44100, channels: 2) {
            let minutes = durationSec / 60
            let seconds = durationSec % 60
            let formatted = String(format: "%02d:%02d", minutes, seconds)
            return RecordingItem(
                title: title,
                date: Date(),
                durationFormatted: formatted,
                durationMs: durationMs,
                packName: packName,
                bpm: bpm,
                fileURL: fileURL,
                padEvents: eventsCopy
            )
        }
        return nil
    }

    public func startMicCapture() -> Bool {
        #if os(iOS)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let samplesDir = docs.appendingPathComponent("CustomSamples", isDirectory: true)
        try? FileManager.default.createDirectory(at: samplesDir, withIntermediateDirectories: true)
        let url = samplesDir.appendingPathComponent("mic_\(Int(Date().timeIntervalSince1970)).wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record()
            self.micRecorder = recorder
            self.micURL = url
            return true
        } catch {
            print("[AudioRecorder] Mic capture failed: \(error)")
            return false
        }
        #else
        return false
        #endif
    }

    public func stopMicCapture() -> URL? {
        micRecorder?.stop()
        micRecorder = nil
        return micURL
    }

    public static func writeMonoFloatWav(to url: URL, samples: [Float], sampleRate: Int32 = 44100) -> Bool {
        let int16 = samples.map { Int16(max(-1.0, min(1.0, $0)) * 32767.0) }
        return writeWavFile(to: url, pcm: int16, sampleRate: sampleRate, channels: 1)
    }

    public static func writeWavFile(to url: URL, pcm: [Int16], sampleRate: Int32, channels: Int16) -> Bool {
        var data = Data()
        let byteRate = sampleRate * Int32(channels) * 2
        let blockAlign = channels * 2
        let subchunk2Size = Int32(pcm.count * 2)
        let chunkSize = 36 + subchunk2Size

        data.append(contentsOf: [UInt8]("RIFF".utf8))
        var cSize = chunkSize
        data.append(Data(bytes: &cSize, count: 4))
        data.append(contentsOf: [UInt8]("WAVE".utf8))
        data.append(contentsOf: [UInt8]("fmt ".utf8))

        var subchunk1Size: Int32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = channels
        data.append(Data(bytes: &numChannels, count: 2))
        var sRate = sampleRate
        data.append(Data(bytes: &sRate, count: 4))
        var bRate = byteRate
        data.append(Data(bytes: &bRate, count: 4))
        var bAlign = blockAlign
        data.append(Data(bytes: &bAlign, count: 2))
        var bitsPerSample: Int16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))

        data.append(contentsOf: [UInt8]("data".utf8))
        var s2Size = subchunk2Size
        data.append(Data(bytes: &s2Size, count: 4))

        pcm.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                data.append(UnsafeBufferPointer(start: UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self), count: pcm.count * 2))
            }
        }

        do {
            try data.write(to: url)
            return true
        } catch {
            print("[AudioRecorder] Failed to write WAV: \(error)")
            return false
        }
    }
}

public final class WavPlaybackController: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = WavPlaybackController()
    private var player: AVAudioPlayer?
    public var onCompletion: (() -> Void)?

    public func play(url: URL) -> Bool {
        stop()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            p.play()
            player = p
            return true
        } catch {
            return false
        }
    }

    public func stop() {
        player?.stop()
        player = nil
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onCompletion?()
    }
}
