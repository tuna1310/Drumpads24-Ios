import Foundation
import AVFoundation

public final class AudioRecorder: @unchecked Sendable {
    public static let shared = AudioRecorder()

    private var recordedPcmData: [Int16] = []
    private let lock = NSLock()
    private var isRecordingInternal: Bool = false
    private var recordingStartTime: Date?

    public init() {}

    public func startRecording(with audioEngine: AudioEngine) {
        lock.lock()
        recordedPcmData.removeAll(keepingCapacity: true)
        isRecordingInternal = true
        recordingStartTime = Date()
        lock.unlock()

        audioEngine.audioTapHandler = { [weak self] interleavedStereo, frameCount in
            guard let self = self, self.isRecordingInternal else { return }
            self.lock.lock()
            for sample in interleavedStereo {
                let clamped = max(-1.0, min(1.0, sample))
                let int16Sample = Int16(clamped * 32767.0)
                self.recordedPcmData.append(int16Sample)
            }
            self.lock.unlock()
        }
    }

    public func stopRecording(with audioEngine: AudioEngine, title: String = "Beat Session") -> RecordingItem? {
        lock.lock()
        isRecordingInternal = false
        audioEngine.audioTapHandler = nil
        let pcmCopy = recordedPcmData
        let durationSec = max(1, pcmCopy.count / (44100 * 2))
        lock.unlock()

        guard !pcmCopy.isEmpty else { return nil }

        // Write WAV file to Documents directory
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = docs.appendingPathComponent("Recordings", isDirectory: true)

        try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let filename = "DrumPads_\(Int(Date().timeIntervalSince1970)).wav"
        let fileURL = recordingsDir.appendingPathComponent(filename)

        if writeWavFile(to: fileURL, pcm: pcmCopy, sampleRate: 44100, channels: 2) {
            let minutes = durationSec / 60
            let seconds = durationSec % 60
            let formatted = String(format: "%02d:%02d", minutes, seconds)
            return RecordingItem(title: title, date: Date(), durationFormatted: formatted, fileURL: fileURL)
        }

        return nil
    }

    private func writeWavFile(to url: URL, pcm: [Int16], sampleRate: Int32, channels: Int16) -> Bool {
        var data = Data()

        let byteRate = sampleRate * Int32(channels) * 2
        let blockAlign = channels * 2
        let subchunk2Size = Int32(pcm.count * 2)
        let chunkSize = 36 + subchunk2Size

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        var cSize = chunkSize
        data.append(Data(bytes: &cSize, count: 4))
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        var subchunk1Size: Int32 = 16
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1 // PCM
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

        // data chunk
        data.append(contentsOf: "data".utf8)
        var s2Size = subchunk2Size
        data.append(Data(bytes: &s2Size, count: 4))

        // PCM bytes
        pcm.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                let bytePtr = UnsafeRawPointer(baseAddress).assumingMemoryBound(to: UInt8.self)
                data.append(bytePtr, count: pcm.count * 2)
            }
        }

        do {
            try data.write(to: url)
            return true
        } catch {
            print("[AudioRecorder] Failed to write WAV file: \(error)")
            return false
        }
    }
}

