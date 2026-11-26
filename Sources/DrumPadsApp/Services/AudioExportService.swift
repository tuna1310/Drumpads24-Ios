import Foundation
import AVFoundation
import CoreMedia
import CoreVideo
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public final class AudioExportService: @unchecked Sendable {
    public static let shared = AudioExportService()
    private init() {}

    public func shareFile(at url: URL) {
        #if os(iOS)
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(activityVC, animated: true)
            }
        }
        #endif
    }

    public func exportRecording(_ item: RecordingItem) {
        guard let url = item.fileURL, FileManager.default.fileExists(atPath: url.path) else {
            shareText("Check out my beat '\(item.title)' (\(item.packName) • \(item.bpm) BPM) made on Drum Pads 24!")
            return
        }
        shareFile(at: url)
    }

    public func shareText(_ text: String) {
        #if os(iOS)
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        }
        #endif
    }

    public func exportPerformanceVideo(
        recording: RecordingItem,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        #if os(iOS)
        guard let wavURL = recording.fileURL, FileManager.default.fileExists(atPath: wavURL.path) else {
            completion(.failure(NSError(domain: "DrumPadsExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "WAV file missing"])))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let exportsDir = docs.appendingPathComponent("Exports", isDirectory: true)
                try? FileManager.default.createDirectory(at: exportsDir, withIntermediateDirectories: true)
                let outURL = exportsDir.appendingPathComponent("DrumPads_Video_\(Int(Date().timeIntervalSince1970)).mp4")
                if FileManager.default.fileExists(atPath: outURL.path) {
                    try? FileManager.default.removeItem(at: outURL)
                }

                let width = 720
                let height = 1280
                let fps: Int32 = 30
                let audioAsset = AVURLAsset(url: wavURL)
                let durationSec = max(1.0, min(60.0, CMTimeGetSeconds(audioAsset.duration)))
                let totalFrames = Int(durationSec * Double(fps))

                let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: width,
                    AVVideoHeightKey: height
                ]
                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                videoInput.expectsMediaDataInRealTime = false

                let sourceAttrs: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourceAttrs)
                if writer.canAdd(videoInput) { writer.add(videoInput) }

                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]
                let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                audioInput.expectsMediaDataInRealTime = false
                if writer.canAdd(audioInput) { writer.add(audioInput) }

                var assetReader: AVAssetReader?
                var readerOutput: AVAssetReaderTrackOutput?
                if let audioTrack = audioAsset.tracks(withMediaType: .audio).first {
                    let reader = try AVAssetReader(asset: audioAsset)
                    let out = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsFloatKey: false,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsNonInterleaved: false
                    ])
                    if reader.canAdd(out) {
                        reader.add(out)
                        reader.startReading()
                        assetReader = reader
                        readerOutput = out
                    }
                }

                writer.startWriting()
                writer.startSession(atSourceTime: .zero)

                let group = DispatchGroup()
                group.enter()
                let videoQueue = DispatchQueue(label: "drumpads.video.export")
                var frameIndex = 0

                videoInput.requestMediaDataWhenReady(on: videoQueue) {
                    while videoInput.isReadyForMoreMediaData {
                        if frameIndex >= totalFrames {
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }
                        if let pool = adaptor.pixelBufferPool {
                            var pb: CVPixelBuffer?
                            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb)
                            if let pixelBuffer = pb {
                                Self.renderFrame(
                                    into: pixelBuffer,
                                    width: width,
                                    height: height,
                                    frameIndex: frameIndex,
                                    fps: Int(fps),
                                    recording: recording
                                )
                                let pts = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                                adaptor.append(pixelBuffer, withPresentationTime: pts)
                            }
                        }
                        frameIndex += 1
                    }
                }

                group.enter()
                let audioQueue = DispatchQueue(label: "drumpads.audio.export")
                audioInput.requestMediaDataWhenReady(on: audioQueue) {
                    while audioInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerOutput?.copyNextSampleBuffer() {
                            audioInput.append(sampleBuffer)
                        } else {
                            audioInput.markAsFinished()
                            group.leave()
                            return
                        }
                    }
                }

                group.wait()
                assetReader?.cancelReading()
                let finishSem = DispatchSemaphore(value: 0)
                writer.finishWriting { finishSem.signal() }
                finishSem.wait()

                if writer.status == .completed {
                    DispatchQueue.main.async { completion(.success(outURL)) }
                } else {
                    let err = writer.error ?? NSError(domain: "DrumPadsExport", code: -2, userInfo: [NSLocalizedDescriptionKey: "Video export incomplete"])
                    DispatchQueue.main.async { completion(.failure(err)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        #else
        completion(.failure(NSError(domain: "DrumPadsExport", code: -3, userInfo: nil)))
        #endif
    }

    #if os(iOS)
    private static func renderFrame(
        into pixelBuffer: CVPixelBuffer,
        width: Int,
        height: Int,
        frameIndex: Int,
        fps: Int,
        recording: RecordingItem
    ) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return }

        let w = CGFloat(width)
        let h = CGFloat(height)
        context.setFillColor(CGColor(red: 0.05, green: 0.055, blue: 0.11, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: w, height: h))

        let tMs = Int64((Double(frameIndex) / Double(fps)) * 1000.0)
        let litPads = Set(recording.padEvents.filter { abs($0.timestampMs - tMs) <= 220 }.map { $0.padIndex % 12 })

        // Render 3x4 Neon Pad Matrix in center
        let cols = 3
        let rows = 4
        let padW: CGFloat = 180
        let padH: CGFloat = 175
        let gap: CGFloat = 20
        let totalW = CGFloat(cols) * padW + CGFloat(cols - 1) * gap
        let startX = (w - totalW) * 0.5
        let startY: CGFloat = 290

        for idx in 0..<12 {
            let r = idx / cols
            let c = idx % cols
            let x = startX + CGFloat(c) * (padW + gap)
            let y = startY + CGFloat(3 - r) * (padH + gap)
            let isLit = litPads.contains(idx)

            let color: CGColor
            switch idx {
            case 0, 1, 3, 4:
                color = CGColor(red: 0.22, green: 0.90, blue: 0.30, alpha: isLit ? 1.0 : 0.25)
            case 2, 5:
                color = CGColor(red: 1.0, green: 0.48, blue: 0.0, alpha: isLit ? 1.0 : 0.25)
            case 6, 7, 9, 10:
                color = CGColor(red: 0.88, green: 0.25, blue: 0.98, alpha: isLit ? 1.0 : 0.25)
            default:
                color = CGColor(red: 0.0, green: 0.69, blue: 1.0, alpha: isLit ? 1.0 : 0.25)
            }
            context.setFillColor(color)
            let rect = CGRect(x: x, y: y, width: padW, height: padH)
            let path = CGPath(roundedRect: rect, cornerWidth: 24, cornerHeight: 24, transform: nil)
            context.addPath(path)
            context.fillPath()
        }

        // Bottom waveform bar visualizer
        let barCount = 28
        let barW: CGFloat = 16
        let barGap: CGFloat = 8
        let barsStartX = (w - CGFloat(barCount) * (barW + barGap)) * 0.5
        for b in 0..<barCount {
            let wave = abs(sin(Double(frameIndex) * 0.18 + Double(b) * 0.45)) * (litPads.isEmpty ? 40.0 : 120.0)
            let barH = CGFloat(24.0 + wave)
            context.setFillColor(CGColor(red: 0.0, green: 0.90, blue: 1.0, alpha: 0.85))
            context.fill(CGRect(x: barsStartX + CGFloat(b) * (barW + barGap), y: 110, width: barW, height: barH))
        }
    }
    #endif
}
