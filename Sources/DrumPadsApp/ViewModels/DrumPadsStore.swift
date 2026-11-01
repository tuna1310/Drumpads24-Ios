import Foundation
import Observation
import SwiftUI
import AVFoundation

public enum NavTab: String, CaseIterable, Identifiable, Sendable {
    case sounds = "Sounds"
    case feed = "Feed"
    case my = "My"
    case account = "Account"

    public var id: String { rawValue }
}

public enum ActiveScreen: String, Sendable {
    case main
    case padPlayer
    case settings
    case editProfile
    case recentlyUsed
    case paywall
    case padEditor
    case projectEditor
}

public enum PadBank: String, CaseIterable, Identifiable, Sendable {
    case bankA = "A"
    case bankB = "B"
    case full24 = "24"

    public var id: String { rawValue }
}

public enum RecordingMode: String, CaseIterable, Identifiable, Sendable {
    case free = "Free Mode"
    case loop = "Loop Mode"

    public var id: String { rawValue }
}

@Observable
public final class DrumPadsStore: @unchecked Sendable {
    public static let shared = DrumPadsStore()

    // Pads & Navigation
    public var pads: [Pad] = []
    public var activePads: Set<Int> = []
    public var selectedBank: PadBank = .bankA
    public var selectedPackName: String = "Neon Pulse 24"
    public var activeScreen: ActiveScreen = .main
    public var selectedTab: NavTab = .sounds

    // Playback & Sequencer Mode
    public var bpm: Int = 120
    public var isClipsMode: Bool = false
    public var isPadLocked: Bool = false
    public var activeClips: Set<Int> = [0]
    public var selectedClipIndex: Int = 0

    // Performance Toggles
    public var isHapticEnabled: Bool = true
    public var isLightShowEnabled: Bool = true

    // Quick FX & Tray
    public var isSoundFxOpen: Bool = false
    public var activeQuickFx: String? = nil

    // Audio DSP Fader Levels
    public var volumeLevel: Float = 0.85
    public var echo116Level: Float = 0.30
    public var echo18Level: Float = 0.0
    public var reverbLevel: Float = 0.45
    public var distortionLevel: Float = 0.0
    public var filterCutoff: Float = 1.0
    public var lofiLevel: Float = 0.0

    // Recording
    public var isRecording: Bool = false
    public var recordingMode: RecordingMode = .free
    public var recordingDurationSeconds: Int = 0
    public var recordings: [RecordingItem] = []

    // Mini Player
    public var miniPlayerTrack: String? = "21 savage x baby keem x drake type beat"
    public var miniPlayerDuration: String = "03:25"
    public var isMiniPlayerPlaying: Bool = false

    // Social Feed & Catalogs
    public var feedPosts: [FeedPost] = FeedCatalog.initialPosts
    public var soundPacks: [SoundPackItem] = SoundPackCatalog.newReleases
    public var stories: [SoundPackItem] = SoundPackCatalog.featuredStories
    public var recentlyUsedPacks: [SoundPackItem] = [
        SoundPackItem(title: "Hyphy", subtitle: "Drum Pads 24", genre: "Trap", bpm: 138, gradientHexes: ["#E94057", "#F27121"]),
        SoundPackItem(title: "Neon Pulse 24", subtitle: "Drum Pads 24", genre: "EDM", bpm: 120, gradientHexes: ["#00C9FF", "#92FE9D"]),
        SoundPackItem(title: "Cyber Trap", subtitle: "Drum Pads 24", genre: "Trap", bpm: 140, gradientHexes: ["#8A2387", "#E94057"]),
        SoundPackItem(title: "Dark Electro", subtitle: "Drum Pads 24", genre: "EDM", bpm: 132, gradientHexes: ["#11998E", "#38EF7D"]),
        SoundPackItem(title: "Lo-Fi Sunset", subtitle: "Drum Pads 24", genre: "Lo-Fi", bpm: 82, gradientHexes: ["#F12711", "#F5AF19"])
    ]

    // Pad Editor & Custom Pack
    public var selectedPadForEditing: Int = 0

    // Profile & Settings
    public var userProfile: UserProfile = UserProfile()
    public var isSettingsPresented: Bool = false
    public var isStressTestActive: Bool = false
    public var stressSecondsRemaining: Int = 0
    public var xrunCount: Int = 0

    // Private Subsystems
    private let audioEngine: AudioEngine
    private let hapticService: HapticService
    private let audioRecorder: AudioRecorder
    private var stressTimer: Timer?
    private var clipLoopTimer: Timer?
    private var recordingTimer: Timer?
    private var clipStep: Int = 0

    public init(
        padRepository: PadRepositoryProtocol = DefaultPadRepository.shared,
        audioEngine: AudioEngine = AudioEngine.shared,
        hapticService: HapticService = HapticService.shared,
        audioRecorder: AudioRecorder = AudioRecorder.shared
    ) {
        self.pads = padRepository.getPads()
        self.audioEngine = audioEngine
        self.hapticService = hapticService
        self.audioRecorder = audioRecorder

        audioEngine.start()
        applyDspSettings()
        loadStarterWavs()
        loadQuickFxWavs()
    }

    // -------------------------------------------------------------
    // Pad Playback & Live Performance
    // -------------------------------------------------------------
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

    public func triggerQuickFx(_ fxName: String) {
        if isHapticEnabled {
            hapticService.playPadHaptic()
        }
        activeQuickFx = fxName

        let fxIndex: Int
        switch fxName.lowercased() {
        case "horn": fxIndex = 24
        case "elphnt": fxIndex = 25
        case "reload": fxIndex = 26
        case "scrtch": fxIndex = 27
        case "vinyl": fxIndex = 28
        case "watch": fxIndex = 29
        default: fxIndex = 24
        }

        audioEngine.triggerPad(fxIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            if self?.activeQuickFx == fxName {
                self?.activeQuickFx = nil
            }
        }
    }

    // -------------------------------------------------------------
    // Navigation
    // -------------------------------------------------------------
    public func selectTab(_ tab: NavTab) {
        self.selectedTab = tab
        self.activeScreen = .main
    }

    public func navigateTo(_ screen: ActiveScreen) {
        self.activeScreen = screen
    }

    public func openPadPlayer(packName: String = "Neon Pulse 24") {
        self.selectedPackName = packName
        self.activeScreen = .padPlayer
    }

    public func selectBank(_ bank: PadBank) {
        self.selectedBank = bank
    }

    // -------------------------------------------------------------
    // Clips & Sequencer Mode
    // -------------------------------------------------------------
    public func toggleClipsMode() {
        setClipsMode(!isClipsMode)
    }

    public func setClipsMode(_ isClips: Bool) {
        self.isClipsMode = isClips
        if isClips && !activeClips.isEmpty {
            startClipLoop()
        } else if !isClips {
            stopPlayback()
        }
    }

    public func setPadLocked(_ locked: Bool) {
        self.isPadLocked = locked
    }

    public func toggleClip(_ clipIndex: Int) {
        if activeClips.contains(clipIndex) {
            activeClips.remove(clipIndex)
        } else {
            activeClips.insert(clipIndex)
        }
        selectedClipIndex = clipIndex

        if !activeClips.isEmpty {
            startClipLoop()
        } else {
            stopPlayback()
        }
    }

    public func selectClip(_ index: Int) {
        self.selectedClipIndex = index
    }

    public func duplicateSelectedClip() {
        let nextSlot = (selectedClipIndex + 1) % 12
        activeClips.insert(nextSlot)
        selectedClipIndex = nextSlot
        startClipLoop()
    }

    public func deleteSelectedClip() {
        activeClips.remove(selectedClipIndex)
        if activeClips.isEmpty {
            stopPlayback()
        }
    }

    public func adjustBpm(delta: Int) {
        let newBpm = max(60, min(200, bpm + delta))
        self.bpm = newBpm
        if clipLoopTimer != nil {
            startClipLoop()
        }
    }

    public func stopPlayback() {
        clipLoopTimer?.invalidate()
        clipLoopTimer = nil
        activeClips.removeAll()
        clipStep = 0
    }

    private func startClipLoop() {
        clipLoopTimer?.invalidate()
        clipStep = 0

        let stepInterval = (60.0 / Double(bpm)) / 4.0 // 16th note interval
        clipLoopTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] _ in
            guard let self = self, !self.activeClips.isEmpty else { return }

            let step = self.clipStep
            let active = self.activeClips

            // Clip 0: Kick Punch (Syncopated 808 Kick pattern)
            if active.contains(0) && (step % 16 == 0 || step % 16 == 6 || step % 16 == 10 || step % 16 == 14) {
                self.audioEngine.triggerPad(0)
            }
            // Clip 1: Snare / Clap on beat 3 (step 8 & step 24)
            if active.contains(1) && (step % 16 == 8) {
                self.audioEngine.triggerPad(2)
            }
            // Clip 2: 16th Hi-Hat Groove with roll
            if active.contains(2) && (step % 2 == 0 || (step % 16 >= 14 && step % 16 <= 15)) {
                self.audioEngine.triggerPad(4)
            }
            // Clip 3: Melodic Lead Hook
            if active.contains(3) && (step % 4 == 0) {
                let noteIndex = 12 + ((step / 4) % 6)
                self.audioEngine.triggerPad(noteIndex)
            }
            // Clip 4: 808 Sub Bass (Deep bassline following kick)
            if active.contains(4) && (step % 16 == 0 || step % 16 == 6 || step % 16 == 10) {
                self.audioEngine.triggerPad(6)
            }
            // Clip 5: Percussion Tom & Open Hat
            if active.contains(5) && (step % 16 == 4 || step % 16 == 12) {
                self.audioEngine.triggerPad(18)
            }
            // Clip 6: Vocal Chant ("Hey!" accent)
            if active.contains(6) && (step % 32 == 28) {
                self.audioEngine.triggerPad(22)
            }
            // Clip 7: Crash & Impact on downbeat
            if active.contains(7) && (step % 32 == 0) {
                self.audioEngine.triggerPad(20)
            }

            self.clipStep = (step + 1) % 32
        }
    }

    // -------------------------------------------------------------
    // Audio DSP Faders & Performance FX
    // -------------------------------------------------------------
    public func toggleSoundFxTray() {
        self.isSoundFxOpen.toggle()
    }

    public func setFaderLevel(type: String, level: Float) {
        let clamped = max(0.0, min(1.0, level))
        switch type {
        case "Volume": self.volumeLevel = clamped
        case "Echo 1/16": self.echo116Level = clamped
        case "Echo 1/8": self.echo18Level = clamped
        case "Reverb": self.reverbLevel = clamped
        case "Distortion": self.distortionLevel = clamped
        case "Filter": self.filterCutoff = clamped
        case "Lo-Fi": self.lofiLevel = clamped
        default: break
        }
        applyDspSettings()
    }

    public func triggerFill() {
        if isHapticEnabled { hapticService.playPadHaptic() }
        audioEngine.triggerFill()
    }

    public func triggerClean() {
        if isHapticEnabled { hapticService.playPadHaptic() }
        audioEngine.triggerClean()
        self.echo116Level = 0.0
        self.echo18Level = 0.0
        self.distortionLevel = 0.0
        self.reverbLevel = 0.0
        self.lofiLevel = 0.0
        self.filterCutoff = 1.0
    }

    private func applyDspSettings() {
        audioEngine.masterVolume = volumeLevel
        audioEngine.echo116Level = echo116Level
        audioEngine.echo18Level = echo18Level
        audioEngine.reverbLevel = reverbLevel
        audioEngine.distortionLevel = distortionLevel
        audioEngine.filterCutoff = filterCutoff
        audioEngine.lofiLevel = lofiLevel
    }

    // -------------------------------------------------------------
    // Recording & Export
    // -------------------------------------------------------------
    public func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    public func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recordingDurationSeconds = 0
        audioRecorder.startRecording(with: audioEngine)

        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingDurationSeconds += 1
        }
    }

    public func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        let title = "\(selectedPackName) Beat #\(recordings.count + 1)"
        if let item = audioRecorder.stopRecording(with: audioEngine, title: title) {
            recordings.insert(item, at: 0)
        }
    }

    public func shareRecording(_ recording: RecordingItem) {
        if let url = recording.fileURL {
            AudioExportService.share(fileURL: url)
        }
    }

    public func deleteRecording(_ id: String) {
        recordings.removeAll { $0.id == id }
    }

    // -------------------------------------------------------------
    // Mini Player
    // -------------------------------------------------------------
    public func toggleMiniPlayer() {
        self.isMiniPlayerPlaying.toggle()
        if isMiniPlayerPlaying {
            // Quick preview beat loop
            audioEngine.triggerPad(0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.audioEngine.triggerPad(2)
            }
        }
    }

    // -------------------------------------------------------------
    // Community Feed & Profile
    // -------------------------------------------------------------
    public func likePost(_ postId: String) {
        if let idx = feedPosts.firstIndex(where: { $0.id == postId }) {
            feedPosts[idx].isLiked.toggle()
            feedPosts[idx].likesCount += feedPosts[idx].isLiked ? 1 : -1
        }
    }

    public func updateProfile(name: String, bio: String, link: String) {
        self.userProfile.userName = name
        self.userProfile.userBio = bio
        self.userProfile.userLink = link
    }

    // -------------------------------------------------------------
    // Pad Editor & Audio Import
    // -------------------------------------------------------------
    public func openPadEditor(padIndex: Int) {
        self.selectedPadForEditing = padIndex
        self.activeScreen = .padEditor
    }

    public func importAudio(for padIndex: Int, url: URL) {
        guard padIndex >= 0 && padIndex < pads.count else { return }
        if let pcm = loadWavFloatBuffer(from: url) {
            audioEngine.loadSample(padIndex: padIndex, data: pcm)
            pads[padIndex].customSampleURL = url
            pads[padIndex].name = url.deletingPathExtension().lastPathComponent
        }
    }

    public func updatePadProperties(index: Int, name: String, volume: Float, pitch: Float, pan: Float) {
        guard index >= 0 && index < pads.count else { return }
        pads[index].name = name
        pads[index].volume = volume
        pads[index].pitch = pitch
        pads[index].pan = pan
    }

    public func swapPads(index1: Int, index2: Int) {
        guard index1 >= 0 && index1 < pads.count && index2 >= 0 && index2 < pads.count else { return }
        let temp = pads[index1]
        pads[index1] = pads[index2]
        pads[index2] = temp

        // Swap loaded sample buffers in audio engine
        let s1 = audioEngine.getSample(at: index1)
        let s2 = audioEngine.getSample(at: index2)
        audioEngine.loadSample(padIndex: index1, data: s2)
        audioEngine.loadSample(padIndex: index2, data: s1)
    }

    // -------------------------------------------------------------
    // Settings & Stress Test
    // -------------------------------------------------------------
    public func setHapticEnabled(_ enabled: Bool) {
        self.isHapticEnabled = enabled
    }

    public func setLightShowEnabled(_ enabled: Bool) {
        self.isLightShowEnabled = enabled
    }

    public func toggleSettings(_ show: Bool) {
        self.isSettingsPresented = show
        if show {
            self.activeScreen = .settings
        } else {
            self.activeScreen = .main
        }
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

    // -------------------------------------------------------------
    // Sample Loading Helpers
    // -------------------------------------------------------------
    private func loadStarterWavs() {
        for pad in pads {
            if let url = findResourceURL(for: pad.sampleFile) {
                if let pcm = loadWavFloatBuffer(from: url) {
                    audioEngine.loadSample(padIndex: pad.index, data: pcm)
                }
            }
        }
    }

    private func loadQuickFxWavs() {
        let quickFxMap: [(Int, String)] = [
            (24, "starter/samples/fx_horn.wav"),
            (25, "starter/samples/fx_elephant.wav"),
            (26, "starter/samples/fx_reload.wav"),
            (27, "starter/samples/fx_scratch.wav"),
            (28, "starter/samples/fx_vinyl.wav"),
            (29, "starter/samples/fx_watch.wav")
        ]

        for (idx, path) in quickFxMap {
            if let url = findResourceURL(for: path) {
                if let pcm = loadWavFloatBuffer(from: url) {
                    audioEngine.loadSample(padIndex: idx, data: pcm)
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
        clipLoopTimer?.invalidate()
        recordingTimer?.invalidate()
        audioEngine.stop()
    }
}
