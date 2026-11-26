import Foundation
import SwiftUI
import Observation

public enum NavTab: String, CaseIterable {
    case sounds = "Sounds"
    case feed = "Feed"
    case my = "My"
    case account = "Account"
}

public enum AppScreen: Equatable {
    case main
    case padPlayer
    case settings
    case editProfile
    case recentlyUsed
    case paywall
    case padEditor
    case soundEditor
    case clipEditor
    case projectEditor
    case recordings
}

@Observable
public final class DrumPadsStore {
    public static let shared = DrumPadsStore()

    // Navigation
    public var selectedTab: NavTab = .sounds
    public var activeScreen: AppScreen = .main
    public var showMiniPlayer: Bool = true
    public var miniPlayerTrack: String? = "FESTIVAL EDM • Preview"
    public var miniPlayerDuration: String = "00:36"
    public var isMiniPlayerPlaying: Bool = false

    // Pad Performance State
    public var activePackId: String = "edm_festival"
    public var activePackName: String = "FESTIVAL EDM"
    public var activeGenre: MusicGenre = .edm
    public var pads: [Pad] = SoundPackCatalog.buildPads(for: .edm)
    public var activeScene: Int = 0 // 0 = Scene A (0..11), 1 = Scene B (12..23), 2 = All 24 Pads
    public var activePadIndices: Set<Int> = []
    public var selectedPadForEdit: Pad? = nil
    public var isHoldMode: Bool = false
    public var isPadLockEnabled: Bool = false

    // Swap / Duplicate editing helpers
    public var swapSourcePadIndex: Int? = nil

    // 10 Live Master DSP Effects
    public var bpm: Int = 128
    public var isMetronomePlaying: Bool = false
    public var isEffectDrawerOpen: Bool = false
    public var masterVolume: Float = 1.0
    public var lofiLevel: Float = 0.0
    public var filterCutoff: Float = 1.0
    public var masterPitchSemitones: Float = 0.0
    public var reverbLevel: Float = 0.0
    public var echo116Level: Float = 0.0
    public var echo18Level: Float = 0.0
    public var distortionLevel: Float = 0.0
    public var gateLevel: Float = 0.0
    public var wobbleLevel: Float = 0.0

    // Recording & Clips
    public var isRecording: Bool = false
    public var recordingMode: RecordingMode = .freeMode
    public var isClipsMode: Bool = false
    public var recordingTimeFormatted: String = "00:00"
    public var recordings: [RecordingItem] = []
    public var playingRecordingId: String? = nil
    public var exportingRecordingId: String? = nil
    public var statusBannerMessage: String? = nil

    public var clipSlots: [ClipSlot] = ClipPatternPresets.defaultClips()
    public var editingClipIndex: Int = 0
    public var activePatternPresetIndex: Int = 0
    public var currentSequencerStep: Int = -1
    public var isSequencerPlaying: Bool = false
    public var selectedSequencerPadIndex: Int = 0

    // Sound Editor Waveform & Mic
    public var editingWaveformPeaks: [Float] = Array(repeating: 0.2, count: 56)
    public var isMicSampling: Bool = false

    // User Data
    public var userProfile: UserProfile = StudioStorage.shared.loadProfile()
    public var customPacks: [SoundPack] = []
    public var favoritePackIds: Set<String> = []
    public var recentPackIds: [String] = []

    // Sounds Filtering & Preview
    public var selectedGenreFilter: MusicGenre = .all
    public var searchQuery: String = ""
    public var previewingPackId: String? = nil

    // Feed State
    public var selectedFeedCategory: FeedPost.FeedCategory = .featured
    public var feedPosts: [FeedPost] = []
    public var playingPostId: String? = nil

    // Crew Tutorial Interactive Lightshow
    public var activeTutorialPost: FeedPost? = nil
    public var tutorialStepIndex: Int = 0
    public var highlightedTutorialPadIndex: Int? = nil

    // Settings & Legacy Compatibility Flags
    public var isAudioFeedbackEnabled: Bool = true
    public var isShowTapEffectEnabled: Bool = true
    public var isAutoRecordEnabled: Bool = false
    public var isHapticFeedbackEnabled: Bool = true
    public var isStressTestActive: Bool = false
    public var stressSecondsRemaining: Int = 60
    public var xrunCount: Int = 0
    private var stressTimer: Timer?

    public var isHapticEnabled: Bool { isHapticFeedbackEnabled }
    public func setHapticEnabled(_ enabled: Bool) { isHapticFeedbackEnabled = enabled }
    public var isLightShowEnabled: Bool { isShowTapEffectEnabled }
    public func setLightShowEnabled(_ enabled: Bool) { isShowTapEffectEnabled = enabled }
    public func setStressTest(_ active: Bool) {
        isStressTestActive = active
        stressTimer?.invalidate()
        if active {
            stressSecondsRemaining = 60
            xrunCount = 0
            stressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] t in
                guard let self = self else { t.invalidate(); return }
                self.engine.triggerPad(padIndex: Int.random(in: 0..<24))
                self.stressSecondsRemaining = max(0, self.stressSecondsRemaining - 1)
                if self.stressSecondsRemaining == 0 {
                    t.invalidate()
                    self.isStressTestActive = false
                }
            }
        }
    }

    // Timers
    private var recordingTimer: Timer?
    private var recordingSeconds: Int = 0
    private var sequencerTimer: Timer?
    private var metronomeTimer: Timer?
    private var metronomeBeatCount: Int = 0
    private var previewTimer: Timer?
    private var tutorialTimer: Timer?
    private var feedPlaybackTimer: Timer?

    private let engine = AudioEngine.shared
    private let storage = StudioStorage.shared

    public init() {
        self.recordings = storage.loadRecordings()
        self.customPacks = storage.loadCustomPacks()
        self.favoritePackIds = storage.loadFavorites()
        self.recentPackIds = storage.loadRecentIds()
        self.feedPosts = storage.loadUserPosts() + FeedCatalog.samplePosts

        self.engine.loadPackSamples(pads: self.pads, genre: self.activeGenre)
        self.engine.bpm = self.bpm
    }

    // MARK: - Computed Properties
    public var allPacks: [SoundPack] {
        customPacks + SoundPackCatalog.allBuiltInPacks
    }

    public var filteredPacks: [SoundPack] {
        allPacks.filter { pack in
            let matchesGenre = selectedGenreFilter == .all || pack.genre == selectedGenreFilter
            let matchesSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                pack.title.localizedCaseInsensitiveContains(searchQuery) ||
                pack.subtitle.localizedCaseInsensitiveContains(searchQuery) ||
                pack.genre.displayName.localizedCaseInsensitiveContains(searchQuery)
            return matchesGenre && matchesSearch
        }
    }

    public var favoritePacks: [SoundPack] {
        allPacks.filter { favoritePackIds.contains($0.id) }
    }

    public var recentlyUsedPacks: [SoundPack] {
        let matched = recentPackIds.compactMap { id in allPacks.first(where: { $0.id == id }) }
        return matched.isEmpty ? Array(SoundPackCatalog.featuredStories.prefix(3)) : matched
    }

    public var filteredFeedPosts: [FeedPost] {
        feedPosts.filter { post in
            switch selectedFeedCategory {
            case .featured:
                return post.category == .featured || post.isCrewTutorial
            case .following:
                return post.isFollowingAuthor || post.category == .following
            case .latest:
                return true
            }
        }
    }

    public var editingClip: ClipSlot {
        get {
            guard editingClipIndex >= 0 && editingClipIndex < clipSlots.count else {
                return clipSlots[0]
            }
            return clipSlots[editingClipIndex]
        }
        set {
            guard editingClipIndex >= 0 && editingClipIndex < clipSlots.count else { return }
            clipSlots[editingClipIndex] = newValue
        }
    }

    // MARK: - Navigation
    public func navigateTo(_ screen: AppScreen) {
        if activeScreen == .soundEditor {
            // Stop previewing sound when leaving
        }
        activeScreen = screen
    }

    public func selectTab(_ tab: NavTab) {
        selectedTab = tab
    }

    public func openPadPlayer(packName: String) {
        if let found = allPacks.first(where: { $0.id == packName || $0.title.caseInsensitiveCompare(packName) == .orderedSame }) {
            loadSoundPack(found)
        } else {
            activePackName = packName
            engine.loadPackSamples(pads: pads, genre: activeGenre)
        }
        activeScreen = .padPlayer
    }

    public func loadSoundPack(_ pack: SoundPack) {
        stopTutorial()
        stopSequencerPlayback()
        previewTimer?.invalidate()
        previewingPackId = nil

        activePackId = pack.id
        activePackName = pack.title
        activeGenre = pack.genre
        bpm = pack.bpm
        engine.bpm = pack.bpm

        if let savedPads = storage.loadCustomPads(for: pack.id) {
            pads = savedPads
        } else {
            pads = SoundPackCatalog.buildPads(for: pack.genre)
        }
        engine.loadPackSamples(pads: pads, genre: pack.genre, packId: pack.id)

        recentPackIds.removeAll { $0 == pack.id }
        recentPackIds.insert(pack.id, at: 0)
        if recentPackIds.count > 12 {
            recentPackIds = Array(recentPackIds.prefix(12))
        }
        storage.saveRecentIds(recentPackIds)
        miniPlayerTrack = "\(pack.title) • \(pack.bpm) BPM"
    }

    public func toggleFavorite(packId: String) {
        if favoritePackIds.contains(packId) {
            favoritePackIds.remove(packId)
        } else {
            favoritePackIds.insert(packId)
        }
        storage.saveFavorites(favoritePackIds)
    }

    public func previewSoundPack(_ pack: SoundPack) {
        if previewingPackId == pack.id {
            previewTimer?.invalidate()
            previewingPackId = nil
            isMiniPlayerPlaying = false
            engine.stopAllVoices()
            return
        }
        previewingPackId = pack.id
        isMiniPlayerPlaying = true
        miniPlayerTrack = "\(pack.title) • \(pack.genre.displayName)"
        miniPlayerDuration = "\(pack.bpm) BPM"
        let previewPads = storage.loadCustomPads(for: pack.id) ?? SoundPackCatalog.buildPads(for: pack.genre)
        engine.loadPackSamples(pads: previewPads, genre: pack.genre, packId: pack.id)
        engine.bpm = pack.bpm

        let variant = abs(pack.id.hashValue) % 4
        let presetHits = ClipPatternPresets.hitsForPreset(variant)

        previewTimer?.invalidate()
        var step = 0
        let interval = 60.0 / Double(max(60, pack.bpm)) / 4.0
        previewTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if step >= 64 || self.previewingPackId != pack.id {
                timer.invalidate()
                self.previewingPackId = nil
                self.isMiniPlayerPlaying = false
                return
            }
            let s = step % 16
            for hit in presetHits where hit.step == s {
                self.engine.triggerPad(padIndex: hit.padIndex)
            }
            if step >= 16 && (s == 0 || s == 6 || s == 10) {
                self.engine.triggerPad(padIndex: 12 + ((variant + s) % 5))
            }
            step += 1
        }
    }

    public func toggleMiniPlayer() {
        if isMiniPlayerPlaying {
            previewTimer?.invalidate()
            previewingPackId = nil
            WavPlaybackController.shared.stop()
            playingRecordingId = nil
            isMiniPlayerPlaying = false
        } else {
            if let first = recordings.first {
                togglePlayRecording(first)
            } else if let cur = allPacks.first(where: { $0.id == previewingPackId }) ?? allPacks.first {
                previewSoundPack(cur)
            }
        }
    }

    public func nextMiniPlayerTrack() {
        let packs = allPacks
        guard !packs.isEmpty else { return }
        let idx = packs.firstIndex(where: { $0.id == previewingPackId || (miniPlayerTrack?.hasPrefix($0.title) == true) }) ?? -1
        let nextPack = packs[(idx + 1) % packs.count]
        previewSoundPack(nextPack)
    }

    // MARK: - Pad Trigger & Release
    public func triggerPad(index: Int) {
        guard index >= 0 && index < pads.count else { return }

        if isShowTapEffectEnabled {
            activePadIndices.insert(index)
        }
        if isHapticFeedbackEnabled {
            HapticService.shared.impactLight()
        }
        if isAudioFeedbackEnabled {
            engine.triggerPad(padIndex: index)
        }
        if isRecording {
            AudioRecorder.shared.recordPadHit(index)
            if isClipsMode && !clipSlots[editingClipIndex].hits.contains(where: { $0.step == max(0, currentSequencerStep) && $0.padIndex == index }) {
                let targetStep = max(0, currentSequencerStep % 16)
                clipSlots[editingClipIndex].hits.append(ClipHit(step: targetStep, padIndex: index))
            }
        }

        // Handle Crew Tutorial step progression
        if let tut = activeTutorialPost,
           tutorialStepIndex < tut.tutorialSteps.count,
           tut.tutorialSteps[tutorialStepIndex].padIndex == index {
            tutorialStepIndex += 1
            if tutorialStepIndex >= tut.tutorialSteps.count {
                statusBannerMessage = "Lesson Completed! Great finger drumming!"
                highlightedTutorialPadIndex = nil
                activeTutorialPost = nil
            } else {
                highlightedTutorialPadIndex = tut.tutorialSteps[tutorialStepIndex].padIndex
                activeScene = highlightedTutorialPadIndex! < 12 ? 0 : 1
            }
        }

        let pad = pads[index]
        if isAutoRecordEnabled && !isRecording {
            toggleRecording()
        }
        if pad.playMode == .oneShot && !isHoldMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                self?.activePadIndices.remove(index)
            }
        }
    }

    public func releasePad(index: Int) {
        guard index >= 0 && index < pads.count else { return }
        let pad = pads[index]
        if isHoldMode || pad.playMode == .hold {
            engine.releasePad(padIndex: index)
            activePadIndices.remove(index)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.activePadIndices.remove(index)
            }
        }
    }

    public func toggleHoldMode() {
        isHoldMode.toggle()
        if !isHoldMode {
            engine.stopAllVoices()
            activePadIndices.removeAll()
        }
    }

    public func triggerFill() {
        engine.triggerFill()
        if isHapticFeedbackEnabled { HapticService.shared.impactMedium() }
    }

    public func triggerClean() {
        engine.triggerClean()
        resetAllEffects()
        activePadIndices.removeAll()
        if isHapticFeedbackEnabled { HapticService.shared.impactLight() }
    }

    // MARK: - 10 Live FX Control Setters
    public func setMasterVolume(_ val: Float) {
        masterVolume = val
        engine.masterVolume = val
    }
    public func setLofiLevel(_ val: Float) {
        lofiLevel = val
        engine.lofiLevel = val
    }
    public func setFilterCutoff(_ val: Float) {
        filterCutoff = val
        engine.filterCutoff = val
    }
    public func setMasterPitch(_ semitones: Float) {
        masterPitchSemitones = semitones
        engine.masterPitchSemitones = semitones
    }
    public func setReverbLevel(_ val: Float) {
        reverbLevel = val
        engine.reverbLevel = val
    }
    public func setEcho116Level(_ val: Float) {
        echo116Level = val
        engine.echo116Level = val
    }
    public func setEcho18Level(_ val: Float) {
        echo18Level = val
        engine.echo18Level = val
    }
    public func setDistortionLevel(_ val: Float) {
        distortionLevel = val
        engine.distortionLevel = val
    }
    public func setGateLevel(_ val: Float) {
        gateLevel = val
        engine.gateLevel = val
    }
    public func setWobbleLevel(_ val: Float) {
        wobbleLevel = val
        engine.wobbleLevel = val
    }

    public func resetAllEffects() {
        masterVolume = 1.0
        lofiLevel = 0.0
        filterCutoff = 1.0
        masterPitchSemitones = 0.0
        reverbLevel = 0.0
        echo116Level = 0.0
        echo18Level = 0.0
        distortionLevel = 0.0
        gateLevel = 0.0
        wobbleLevel = 0.0
        engine.masterVolume = 1.0
        engine.lofiLevel = 0.0
        engine.filterCutoff = 1.0
        engine.masterPitchSemitones = 0.0
        engine.reverbLevel = 0.0
        engine.echo116Level = 0.0
        engine.echo18Level = 0.0
        engine.distortionLevel = 0.0
        engine.gateLevel = 0.0
        engine.wobbleLevel = 0.0
    }

    public func adjustBpm(_ delta: Int) {
        bpm = max(60, min(200, bpm + delta))
        engine.bpm = bpm
        if isSequencerPlaying {
            startSequencerPlayback()
        }
        if isMetronomePlaying {
            startMetronomeTimer()
        }
    }

    public func toggleMetronome() {
        isMetronomePlaying.toggle()
        if isMetronomePlaying {
            metronomeBeatCount = 0
            startMetronomeTimer()
        } else {
            metronomeTimer?.invalidate()
            metronomeTimer = nil
        }
    }

    private func startMetronomeTimer() {
        metronomeTimer?.invalidate()
        let interval = 60.0 / Double(max(40, bpm))
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let accent = (self.metronomeBeatCount % 4) == 0
            self.engine.playMetronomeClick(accent: accent)
            self.metronomeBeatCount += 1
        }
    }

    // MARK: - Recording (Free Mode / Loop Mode Multi-Layer)
    public func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordingSeconds = 0
        recordingTimeFormatted = "00:00"
        AudioRecorder.shared.startRecording(with: engine)

        if recordingMode == .loopMode {
            isClipsMode = true
            startSequencerPlayback()
        }

        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingSeconds += 1
            let m = self.recordingSeconds / 60
            let s = self.recordingSeconds % 60
            self.recordingTimeFormatted = String(format: "%02d:%02d", m, s)
        }
    }

    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        let title = "\(activePackName) Mix #\(recordings.count + 1)"
        if let item = AudioRecorder.shared.stopRecording(with: engine, title: title, packName: activePackName, bpm: bpm) {
            recordings.insert(item, at: 0)
            storage.saveRecordings(recordings)
            userProfile.tracksCount = recordings.count
            storage.saveProfile(userProfile)
            miniPlayerTrack = item.title
            miniPlayerDuration = item.durationFormatted
            statusBannerMessage = "Saved WAV recording: \(item.title)"
        }
    }

    // MARK: - Clip Slots & 16-Step Sequencer
    public func toggleClipSlot(_ slotId: Int) {
        guard slotId >= 0 && slotId < clipSlots.count else { return }
        clipSlots[slotId].isPlaying.toggle()
        if clipSlots.contains(where: { $0.isPlaying }) {
            if !isSequencerPlaying { startSequencerPlayback() }
        } else if activeScreen != .clipEditor {
            stopSequencerPlayback()
        }
    }

    public func openClipEditor(slotId: Int) {
        editingClipIndex = max(0, min(clipSlots.count - 1, slotId))
        if selectedSequencerPadIndex >= pads.count { selectedSequencerPadIndex = 0 }
        activeScreen = .clipEditor
    }

    public func toggleSequencerStep(_ step: Int) {
        guard editingClipIndex >= 0 && editingClipIndex < clipSlots.count else { return }
        var hits = clipSlots[editingClipIndex].hits
        if let idx = hits.firstIndex(where: { $0.step == step && $0.padIndex == selectedSequencerPadIndex }) {
            hits.remove(at: idx)
        } else {
            hits.append(ClipHit(step: step, padIndex: selectedSequencerPadIndex))
        }
        clipSlots[editingClipIndex].hits = hits
    }

    public func stepHasPadHit(step: Int, padIndex: Int) -> Bool {
        editingClip.hits.contains(where: { $0.step == step && $0.padIndex == padIndex })
    }

    public func stepHasAnyHit(_ step: Int) -> Bool {
        editingClip.hits.contains(where: { $0.step == step })
    }

    public func cyclePatternPreset(_ delta: Int) {
        let count = ClipPatternPresets.presetNames.count
        activePatternPresetIndex = (activePatternPresetIndex + delta + count) % count
        clipSlots[editingClipIndex].hits = ClipPatternPresets.hitsForPreset(activePatternPresetIndex)
    }

    public func toggleSequencerPlayback() {
        if isSequencerPlaying {
            stopSequencerPlayback()
        } else {
            startSequencerPlayback()
        }
    }

    public func startSequencerPlayback() {
        sequencerTimer?.invalidate()
        isSequencerPlaying = true
        currentSequencerStep = -1
        let stepInterval = 60.0 / Double(max(40, bpm)) / 4.0 // 16th note
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let nextStep = (self.currentSequencerStep + 1) % 16
            self.currentSequencerStep = nextStep

            var triggered: Set<Int> = []
            if self.activeScreen == .clipEditor {
                for hit in self.editingClip.hits where hit.step == nextStep {
                    triggered.insert(hit.padIndex)
                }
            } else {
                for clip in self.clipSlots where clip.isPlaying {
                    for hit in clip.hits where hit.step == nextStep {
                        triggered.insert(hit.padIndex)
                    }
                }
            }
            for pIdx in triggered {
                self.engine.triggerPad(padIndex: pIdx)
                if self.isShowTapEffectEnabled {
                    self.activePadIndices.insert(pIdx)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                        self?.activePadIndices.remove(pIdx)
                    }
                }
            }
        }
    }

    public func stopSequencerPlayback() {
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        isSequencerPlaying = false
        currentSequencerStep = -1
    }

    // MARK: - Pad & Sound Editor Operations
    public func selectPadForEdit(_ pad: Pad) {
        selectedPadForEdit = pad
        refreshWaveformPeaks(for: pad)
    }

    public func refreshWaveformPeaks(for pad: Pad) {
        if let buf = engine.getSampleBuffer(padIndex: pad.index) {
            editingWaveformPeaks = AudioEngine.computeWaveformPeaks(samples: buf, bins: 56)
        }
    }

    public func updatePad(_ pad: Pad) {
        if let index = pads.firstIndex(where: { $0.id == pad.id }) {
            pads[index] = pad
            selectedPadForEdit = pad
            engine.updatePad(pad)
            storage.saveCustomPads(pads, for: activePackId)
        }
    }

    public func swapPads(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0 && fromIndex < pads.count && toIndex >= 0 && toIndex < pads.count && fromIndex != toIndex else { return }
        let src = pads[fromIndex]
        let dst = pads[toIndex]

        let newSrc = Pad(
            index: toIndex, name: src.name, group: dst.group, sampleId: src.sampleId,
            sampleFile: src.sampleFile, colorHex: src.colorHex, volume: src.volume,
            pitch: src.pitch, pan: src.pan, customSampleURL: src.customSampleURL,
            playMode: src.playMode, trimStart: src.trimStart, trimEnd: src.trimEnd,
            fadeInRatio: src.fadeInRatio, fadeOutRatio: src.fadeOutRatio,
            chokeGroup: src.chokeGroup, padReverbSend: src.padReverbSend, padDistortion: src.padDistortion
        )
        let newDst = Pad(
            index: fromIndex, name: dst.name, group: src.group, sampleId: dst.sampleId,
            sampleFile: dst.sampleFile, colorHex: dst.colorHex, volume: dst.volume,
            pitch: dst.pitch, pan: dst.pan, customSampleURL: dst.customSampleURL,
            playMode: dst.playMode, trimStart: dst.trimStart, trimEnd: dst.trimEnd,
            fadeInRatio: dst.fadeInRatio, fadeOutRatio: dst.fadeOutRatio,
            chokeGroup: dst.chokeGroup, padReverbSend: dst.padReverbSend, padDistortion: dst.padDistortion
        )

        let srcBuf = engine.getSampleBuffer(padIndex: fromIndex)
        let dstBuf = engine.getSampleBuffer(padIndex: toIndex)
        if let dstBuf = dstBuf { engine.setSampleBuffer(padIndex: fromIndex, buffer: dstBuf) }
        if let srcBuf = srcBuf { engine.setSampleBuffer(padIndex: toIndex, buffer: srcBuf) }

        pads[fromIndex] = newDst
        pads[toIndex] = newSrc
        engine.updatePad(newDst)
        engine.updatePad(newSrc)
        selectedPadForEdit = pads[toIndex]
        swapSourcePadIndex = nil
        storage.saveCustomPads(pads, for: activePackId)
        statusBannerMessage = "Swapped Pad \(fromIndex + 1) ↔ Pad \(toIndex + 1)"
    }

    public func duplicatePad(sourceIndex: Int, targetIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < pads.count && targetIndex >= 0 && targetIndex < pads.count && sourceIndex != targetIndex else { return }
        let src = pads[sourceIndex]
        let cloned = Pad(
            index: targetIndex, name: src.name, group: pads[targetIndex].group,
            sampleId: src.sampleId + "_copy", sampleFile: src.sampleFile,
            colorHex: src.colorHex, volume: src.volume, pitch: src.pitch,
            pan: src.pan, customSampleURL: src.customSampleURL, playMode: src.playMode,
            trimStart: src.trimStart, trimEnd: src.trimEnd,
            fadeInRatio: src.fadeInRatio, fadeOutRatio: src.fadeOutRatio,
            chokeGroup: src.chokeGroup, padReverbSend: src.padReverbSend, padDistortion: src.padDistortion
        )
        if let srcBuf = engine.getSampleBuffer(padIndex: sourceIndex) {
            engine.setSampleBuffer(padIndex: targetIndex, buffer: srcBuf)
        }
        pads[targetIndex] = cloned
        engine.updatePad(cloned)
        selectedPadForEdit = cloned
        storage.saveCustomPads(pads, for: activePackId)
        statusBannerMessage = "Duplicated to Pad \(targetIndex + 1)"
    }

    public func applyCropAndFadeToSelectedPad() {
        guard var pad = selectedPadForEdit,
              let buf = engine.getSampleBuffer(padIndex: pad.index) else { return }
        let processed = AudioEngine.cropAndFade(
            samples: buf,
            trimStart: pad.trimStart,
            trimEnd: pad.trimEnd,
            fadeInRatio: pad.fadeInRatio,
            fadeOutRatio: pad.fadeOutRatio
        )
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let customDir = docs.appendingPathComponent("CustomSamples", isDirectory: true)
        try? FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true)
        let outURL = customDir.appendingPathComponent("crop_\(pad.index)_\(Int(Date().timeIntervalSince1970)).wav")
        _ = AudioRecorder.writeMonoFloatWav(to: outURL, samples: processed)

        pad.customSampleURL = outURL
        pad.trimStart = 0.0
        pad.trimEnd = 1.0
        pad.fadeInRatio = 0.0
        pad.fadeOutRatio = 0.0
        engine.setSampleBuffer(padIndex: pad.index, buffer: processed)
        updatePad(pad)
        refreshWaveformPeaks(for: pad)
        statusBannerMessage = "Cropped & baked sample for \(pad.name)"
    }

    public func resetSelectedPadSound() {
        guard var pad = selectedPadForEdit else { return }
        let fresh = GenreSampleSynthesizer.synthesizePadSample(padIndex: pad.index, genre: activeGenre)
        pad.customSampleURL = nil
        pad.trimStart = 0.0
        pad.trimEnd = 1.0
        pad.fadeInRatio = 0.0
        pad.fadeOutRatio = 0.0
        pad.pitch = 0.0
        pad.volume = 1.0
        pad.pan = 0.0
        pad.padReverbSend = 0.0
        pad.padDistortion = 0.0
        engine.setSampleBuffer(padIndex: pad.index, buffer: fresh)
        updatePad(pad)
        refreshWaveformPeaks(for: pad)
        statusBannerMessage = "Reset \(pad.name) to studio default"
    }

    public func importCustomAudioURL(_ url: URL, for padIndex: Int) {
        guard padIndex >= 0 && padIndex < pads.count else { return }
        guard let decoded = engine.decodeAudioFile(url: url) else {
            statusBannerMessage = "Could not decode selected audio file"
            return
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let customDir = docs.appendingPathComponent("CustomSamples", isDirectory: true)
        try? FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true)
        let dest = customDir.appendingPathComponent("import_\(padIndex)_\(Int(Date().timeIntervalSince1970)).wav")
        _ = AudioRecorder.writeMonoFloatWav(to: dest, samples: decoded)

        var pad = pads[padIndex]
        pad.customSampleURL = dest
        pad.name = String(url.deletingPathExtension().lastPathComponent.prefix(12))
        pad.trimStart = 0.0
        pad.trimEnd = 1.0
        engine.setSampleBuffer(padIndex: padIndex, buffer: decoded)
        updatePad(pad)
        refreshWaveformPeaks(for: pad)
        statusBannerMessage = "Imported \(pad.name)!"
    }

    public func toggleMicSampling() {
        if isMicSampling {
            isMicSampling = false
            if let micURL = AudioRecorder.shared.stopMicCapture(),
               let pad = selectedPadForEdit {
                importCustomAudioURL(micURL, for: pad.index)
            }
        } else {
            isMicSampling = AudioRecorder.shared.startMicCapture()
            if !isMicSampling {
                statusBannerMessage = "Microphone permission required for sampling"
            }
        }
    }

    public func createCustomSoundPack(title: String, genre: MusicGenre, bpm: Int) {
        let packId = "custom_\(Int(Date().timeIntervalSince1970))"
        let newPack = SoundPack(
            id: packId,
            title: title.isEmpty ? "My Custom Pack" : title,
            subtitle: "Custom Sound Pack • \(genre.displayName)",
            genre: genre,
            author: userProfile.userName,
            bpm: bpm,
            gradientHexes: ["#FF2A85", "#7B2CBF", "#00E5FF"],
            isNew: true,
            isCustom: true,
            descriptionText: "User created custom sound pack"
        )
        customPacks.insert(newPack, at: 0)
        storage.saveCustomPacks(customPacks)
        loadSoundPack(newPack)
        selectedPadForEdit = pads.first
        activeScreen = .padEditor
    }

    // MARK: - Recordings Management & MP4 Export
    public func togglePlayRecording(_ item: RecordingItem) {
        if playingRecordingId == item.id {
            WavPlaybackController.shared.stop()
            playingRecordingId = nil
            isMiniPlayerPlaying = false
            return
        }
        guard let url = item.fileURL, FileManager.default.fileExists(atPath: url.path) else {
            statusBannerMessage = "Audio file missing"
            return
        }
        WavPlaybackController.shared.onCompletion = { [weak self] in
            DispatchQueue.main.async {
                self?.playingRecordingId = nil
                self?.isMiniPlayerPlaying = false
            }
        }
        if WavPlaybackController.shared.play(url: url) {
            playingRecordingId = item.id
            miniPlayerTrack = item.title
            miniPlayerDuration = item.durationFormatted
            isMiniPlayerPlaying = true
        }
    }

    public func renameRecording(_ item: RecordingItem, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = recordings.firstIndex(where: { $0.id == item.id }) else { return }
        recordings[idx].title = trimmed
        storage.saveRecordings(recordings)
    }

    public func deleteRecording(_ item: RecordingItem) {
        if playingRecordingId == item.id {
            WavPlaybackController.shared.stop()
            playingRecordingId = nil
        }
        if let url = item.fileURL { try? FileManager.default.removeItem(at: url) }
        recordings.removeAll { $0.id == item.id }
        storage.saveRecordings(recordings)
    }

    public func exportRecordingAsVideo(_ item: RecordingItem) {
        exportingRecordingId = item.id
        statusBannerMessage = "Rendering 9:16 H.264 Performance Video..."
        AudioExportService.shared.exportPerformanceVideo(recording: item) { [weak self] result in
            guard let self = self else { return }
            self.exportingRecordingId = nil
            switch result {
            case .success(let mp4URL):
                self.statusBannerMessage = "Video ready! Opening share sheet..."
                AudioExportService.shared.shareFile(at: mp4URL)
            case .failure(let err):
                self.statusBannerMessage = "Video export error: \(err.localizedDescription)"
            }
        }
    }

    public func publishRecordingToFeed(_ item: RecordingItem) {
        let newPost = FeedPost(
            id: "user_\(item.id)",
            authorName: userProfile.userName,
            authorHandle: "@\(userProfile.userName.lowercased().replacingOccurrences(of: " ", with: ""))",
            avatarColorHex: "#FFD233",
            trackTitle: item.title,
            packUsed: item.packName,
            packId: activePackId,
            genreTag: activeGenre.displayName.uppercased(),
            likesCount: 1,
            commentsCount: 0,
            isFollowingAuthor: true,
            durationString: item.durationFormatted,
            timeAgo: "Just now",
            category: .latest,
            recordingFilePath: item.fileURL?.path
        )
        feedPosts.insert(newPost, at: 0)
        storage.saveUserPosts(feedPosts.filter { $0.id.hasPrefix("user_") })
        statusBannerMessage = "Published '\(item.title)' to Community Feed!"
        selectedTab = .feed
        activeScreen = .main
    }

    // MARK: - Feed Interactions & Crew Lessons
    public func toggleLike(postId: String) {
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            feedPosts[index].isLiked.toggle()
            feedPosts[index].likesCount += feedPosts[index].isLiked ? 1 : -1
        }
    }

    public func toggleFollowAuthor(postId: String) {
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            feedPosts[index].isFollowingAuthor.toggle()
        }
    }

    public func addComment(postId: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = feedPosts.firstIndex(where: { $0.id == postId }) else { return }
        feedPosts[index].comments.append(FeedComment(author: userProfile.userName, text: trimmed))
        feedPosts[index].commentsCount += 1
    }

    public func togglePlayPost(_ post: FeedPost) {
        if playingPostId == post.id {
            playingPostId = nil
            feedPlaybackTimer?.invalidate()
            WavPlaybackController.shared.stop()
            return
        }
        playingPostId = post.id
        if let path = post.recordingFilePath {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                _ = WavPlaybackController.shared.play(url: url)
                return
            }
        }
        if let pack = allPacks.first(where: { $0.id == post.packId || $0.title == post.packUsed }) {
            let pPads = SoundPackCatalog.buildPads(for: pack.genre)
            engine.loadPackSamples(pads: pPads, genre: pack.genre)
        }
        var step = 0
        feedPlaybackTimer?.invalidate()
        feedPlaybackTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            if step >= 12 || self.playingPostId != post.id {
                t.invalidate()
                self.playingPostId = nil
                return
            }
            let steps = post.tutorialSteps
            let padIdx = steps.isEmpty ? [0, 4, 12, 2, 6, 13][step % 6] : steps[step % steps.count].padIndex
            self.engine.triggerPad(padIndex: padIdx)
            step += 1
        }
    }

    public func startCrewTutorial(_ post: FeedPost) {
        if let pack = allPacks.first(where: { $0.id == post.packId || $0.title == post.packUsed }) {
            loadSoundPack(pack)
        }
        activeTutorialPost = post
        tutorialStepIndex = 0
        if let first = post.tutorialSteps.first {
            highlightedTutorialPadIndex = first.padIndex
            activeScene = first.padIndex < 12 ? 0 : 1
        }
        activeScreen = .padPlayer
    }

    public func stopTutorial() {
        tutorialTimer?.invalidate()
        activeTutorialPost = nil
        highlightedTutorialPadIndex = nil
        tutorialStepIndex = 0
    }

    public func updateUserProfile(name: String, bio: String, link: String) {
        userProfile.userName = name
        userProfile.userBio = bio
        userProfile.userLink = link
        storage.saveProfile(userProfile)
    }

    public func showPaywall() {
        activeScreen = .paywall
    }
}
