import SwiftUI

public struct PadPlayerScreen: View {
    public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            AppTheme.padPlayerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Top Utility Header
                topHeaderBar

                // Optional Beat Maker Crew Tutorial Banner
                if let tut = store.activeTutorialPost {
                    tutorialBanner(tut)
                } else if let status = store.statusBannerMessage {
                    HStack {
                        Text(status)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.accentCyan)
                        Spacer()
                        Button("Dismiss") { store.statusBannerMessage = nil }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppTheme.navyCard.opacity(0.85))
                }

                // 2. FX Bar & Status Pill
                fxActionBar

                // 3. Expandable 10-FX DSP Fader Rack
                if store.isEffectDrawerOpen {
                    effectDrawerRack
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 4. Center Matrix: Clips Mode (12 clips) OR Live Pads (Scene A / B / 24-Pad)
                if store.isClipsMode {
                    clipsMatrixView
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                } else {
                    padMatrixView
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                }

                // 5. Scene Selector (A / B / 24) + HOLD + REC + Clips
                bottomControlBar
            }
        }
    }

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 8) {
            Button(action: {
                store.stopSequencerPlayback()
                store.navigateTo(.main)
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppTheme.navyCard.opacity(0.8)))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(store.activePackName)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(store.activeGenre.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accentYellow)
                    Text("• \(store.bpm) BPM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accentCyan)
                }
            }

            Spacer()

            // Metronome Toggle
            Button(action: { store.toggleMetronome() }) {
                Image(systemName: "metronome.fill")
                    .font(.system(size: 14))
                    .foregroundColor(store.isMetronomePlaying ? .black : .white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(store.isMetronomePlaying ? AppTheme.accentYellow : AppTheme.navyCard.opacity(0.8)))
            }

            // Pad Lock
            Button(action: { store.isPadLockEnabled.toggle() }) {
                Image(systemName: store.isPadLockEnabled ? "lock.fill" : "lock.open")
                    .font(.system(size: 14))
                    .foregroundColor(store.isPadLockEnabled ? AppTheme.accentCyan : .white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppTheme.navyCard.opacity(0.8)))
            }

            // Edit Mode Button
            Button(action: {
                store.selectedPadForEdit = store.pads.first
                if let p = store.selectedPadForEdit { store.refreshWaveformPeaks(for: p) }
                store.navigateTo(.padEditor)
            }) {
                Text("EDIT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppTheme.accentYellow))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func tutorialBanner(_ tut: FeedPost) -> some View {
        let current = tut.tutorialSteps.indices.contains(store.tutorialStepIndex) ? tut.tutorialSteps[store.tutorialStepIndex] : nil
        return HStack(spacing: 10) {
            Image(systemName: "graduationcap.fill")
                .foregroundColor(AppTheme.accentYellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("CREW LESSON: \(tut.trackTitle)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(AppTheme.accentYellow)
                    .lineLimit(1)
                if let step = current {
                    Text("Step \(store.tutorialStepIndex + 1)/\(tut.tutorialSteps.count) — Tap highlighted pad \(step.padIndex + 1) (\(step.label))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            Spacer()
            Button(action: { store.stopTutorial() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.accentPurple.opacity(0.45))
    }

    // MARK: - FX Action Bar
    private var fxActionBar: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.isEffectDrawerOpen.toggle()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "slider.vertical.3")
                        .font(.system(size: 12, weight: .bold))
                    Text("10 FX")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundColor(store.isEffectDrawerOpen ? .black : AppTheme.accentCyan)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(store.isEffectDrawerOpen ? AppTheme.accentCyan : AppTheme.navyCard.opacity(0.9))
                )
            }

            Button(action: { store.triggerFill() }) {
                Text("FILL")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppTheme.accentPurple.opacity(0.8)))
            }

            Button(action: { store.triggerClean() }) {
                Text("CLEAN")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppTheme.navyCardElevated))
            }

            Spacer()

            // BPM Steppers
            HStack(spacing: 4) {
                Button(action: { store.adjustBpm(-2) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(AppTheme.navyCardElevated))
                }
                Text("\(store.bpm)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AppTheme.accentYellow)
                Button(action: { store.adjustBpm(2) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(AppTheme.navyCardElevated))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    // MARK: - 10 Real-Time Unlocked Fader Rack
    private var effectDrawerRack: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                DspFaderCapsule(title: "VOL", value: store.masterVolume, color: AppTheme.accentYellow) { store.setMasterVolume($0) }
                DspFaderCapsule(title: "LO-FI", value: store.lofiLevel, color: AppTheme.padNeonMagenta) { store.setLofiLevel($0) }
                DspFaderCapsule(title: "FILTER", value: store.filterCutoff, color: AppTheme.accentCyan) { store.setFilterCutoff($0) }
                DspFaderCapsule(title: "PITCH", value: (store.masterPitchSemitones + 12.0) / 24.0, color: AppTheme.padLimeGreen) {
                    store.setMasterPitch(($0 * 24.0) - 12.0)
                }
                DspFaderCapsule(title: "REVERB", value: store.reverbLevel, color: AppTheme.accentPurple) { store.setReverbLevel($0) }
                DspFaderCapsule(title: "DLY 1/16", value: store.echo116Level, color: AppTheme.accentCyan) { store.setEcho116Level($0) }
                DspFaderCapsule(title: "DLY 1/8", value: store.echo18Level, color: AppTheme.padElectricSkyBlue) { store.setEcho18Level($0) }
                DspFaderCapsule(title: "DIST", value: store.distortionLevel, color: AppTheme.dangerRed) { store.setDistortionLevel($0) }
                DspFaderCapsule(title: "GATE", value: store.gateLevel, color: AppTheme.padVividOrange) { store.setGateLevel($0) }
                DspFaderCapsule(title: "WOBBLE", value: store.wobbleLevel, color: AppTheme.accentPink) { store.setWobbleLevel($0) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(AppTheme.navySurface.opacity(0.95))
    }

    // MARK: - Pad Matrix View (Scene A, Scene B, or Full 24 Grid)
    private var padMatrixView: some View {
        let showAll24 = (store.activeScene == 2)
        let displayedPads: [Pad] = showAll24
            ? store.pads
            : Array(store.pads.dropFirst(store.activeScene == 0 ? 0 : 12).prefix(12))
        let colCount = showAll24 ? 4 : 3
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: colCount)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(displayedPads) { pad in
                NeonPadCell(
                    pad: pad,
                    isActive: store.activePadIndices.contains(pad.index),
                    isTutorialTarget: store.highlightedTutorialPadIndex == pad.index,
                    compact: showAll24,
                    onPressDown: { store.triggerPad(index: pad.index) },
                    onRelease: { store.releasePad(index: pad.index) }
                )
                .aspectRatio(showAll24 ? 1.1 : 1.0, contentMode: .fit)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - 12-Slot Clips / Multi-Layer Mode Grid
    private var clipsMatrixView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("CLIP SEQUENCER MODE • Tap to toggle • Gear to edit")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Button(action: { store.toggleSequencerPlayback() }) {
                    Label(store.isSequencerPlaying ? "STOP" : "PLAY", systemImage: store.isSequencerPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(store.isSequencerPlaying ? AppTheme.dangerRed : AppTheme.accentCyan))
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.clipSlots) { clip in
                    let clipColor = Color(hex: clip.colorHex)
                    ZStack(alignment: .topTrailing) {
                        Button(action: { store.toggleClipSlot(clip.id) }) {
                            VStack(spacing: 6) {
                                Text(clip.name)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.white)
                                Text(clip.hasHits ? "\(clip.hits.count) notes" : "Empty")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                if clip.isPlaying {
                                    Text("LOOPING")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(AppTheme.accentYellow))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(clip.isPlaying ? clipColor.opacity(0.85) : clipColor.opacity(0.28))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(clip.isPlaying ? .white : clipColor, lineWidth: clip.isPlaying ? 2.5 : 1.2)
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { store.openClipEditor(slotId: clip.id) }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.45)))
                        }
                        .padding(6)
                    }
                    .aspectRatio(1.05, contentMode: .fit)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom Bar (Scene A / B / 24, HOLD, REC Mode + Button, CLIPS)
    private var bottomControlBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Scene Switcher (A / B / 24)
                HStack(spacing: 4) {
                    scenePill(label: "A", idx: 0)
                    scenePill(label: "B", idx: 1)
                    scenePill(label: "24", idx: 2)
                }
                .padding(3)
                .background(Capsule().fill(AppTheme.navyCard))

                // HOLD Toggle
                Button(action: { store.toggleHoldMode() }) {
                    Text("HOLD")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(store.isHoldMode ? .black : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(store.isHoldMode ? AppTheme.accentCyan : AppTheme.navyCard))
                }

                Spacer()

                // REC Mode Toggle (Free / Loop)
                Button(action: {
                    store.recordingMode = (store.recordingMode == .freeMode) ? .loopMode : .freeMode
                }) {
                    Text(store.recordingMode == .freeMode ? "FREE" : "LOOP")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(AppTheme.accentYellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.navyCard))
                }

                // REC Button
                Button(action: { store.toggleRecording() }) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(store.isRecording ? Color.white : AppTheme.dangerRed)
                            .frame(width: 9, height: 9)
                        Text(store.isRecording ? store.recordingTimeFormatted : "REC")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(store.isRecording ? AppTheme.dangerRed : AppTheme.navyCardElevated))
                }

                // CLIPS Mode Toggle
                Button(action: { store.isClipsMode.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 11))
                        Text("CLIPS")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundColor(store.isClipsMode ? .black : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(store.isClipsMode ? AppTheme.accentPink : AppTheme.navyCard))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }

    private func scenePill(label: String, idx: Int) -> some View {
        let active = store.activeScene == idx && !store.isClipsMode
        return Button(action: {
            if !store.isPadLockEnabled {
                store.isClipsMode = false
                store.activeScene = idx
            }
        }) {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(active ? .black : AppTheme.textSecondary)
                .frame(width: 30, height: 26)
                .background(Capsule().fill(active ? AppTheme.accentYellow : Color.clear))
        }
        .buttonStyle(.plain)
    }
}

private struct NeonPadCell: View {
    let pad: Pad
    let isActive: Bool
    let isTutorialTarget: Bool
    let compact: Bool
    let onPressDown: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        let color = Color(hex: pad.colorHex)
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: compact ? 12 : 16)
                .fill(
                    LinearGradient(
                        colors: (isActive || isPressed)
                            ? [color, color.opacity(0.8)]
                            : [color.opacity(0.32), AppTheme.navyCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 12 : 16)
                        .stroke(
                            isTutorialTarget ? AppTheme.accentYellow : ((isActive || isPressed) ? Color.white : color.opacity(0.85)),
                            lineWidth: isTutorialTarget ? 3.5 : ((isActive || isPressed) ? 2.5 : 1.5)
                        )
                )
                .shadow(color: (isActive || isPressed) ? color.opacity(0.7) : .clear, radius: 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if !compact {
                        Text("\(pad.index + 1)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                    if pad.playMode != .oneShot {
                        Text(pad.playMode == .loop ? "LOOP" : "HOLD")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                }
                Spacer()
                Text(pad.name)
                    .font(.system(size: compact ? 10 : 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(compact ? 7 : 10)
        }
        .scaleEffect((isActive || isPressed) ? 0.94 : 1.0)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onPressDown()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onRelease()
                }
        )
    }
}

private struct DspFaderCapsule: View {
    let title: String
    let value: Float
    let color: Color
    let onChange: (Float) -> Void

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.navyCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.navyBorder, lineWidth: 1)
                        )
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.85))
                        .frame(height: max(6, CGFloat(max(0, min(1, value))) * geo.size.height))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let ratio = Float(1.0 - (g.location.y / max(1, geo.size.height)))
                            onChange(max(0.0, min(1.0, ratio)))
                        }
                )
            }
            .frame(width: 44, height: 96)

            Text(title)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white)
            Text("\(Int(value * 100))%")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
