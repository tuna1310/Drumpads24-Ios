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

            VStack(spacing: 8) {
                // 1. Top Bar
                TopNavigationBar(
                    isClipsMode: store.isClipsMode,
                    isPadLocked: store.isPadLocked,
                    onBackClick: { store.navigateTo(.main) },
                    onCrownClick: { store.navigateTo(.paywall) },
                    onModeChange: { isClips in store.setClipsMode(isClips) },
                    onLockToggle: { store.setPadLocked(!store.isPadLocked) },
                    onSettingsClick: { store.navigateTo(.settings) }
                )

                // 2. Mode Sub-Bar
                if store.isClipsMode {
                    ClipsTransportBar(
                        bpm: store.bpm,
                        isRecording: store.isRecording,
                        onStopClick: { store.stopPlayback() },
                        onRecordClick: { store.toggleRecording() },
                        onBpmDecrease: { store.adjustBpm(delta: -5) },
                        onBpmIncrease: { store.adjustBpm(delta: 5) }
                    )
                } else {
                    PadsToolbar(
                        selectedBank: store.selectedBank,
                        isRecording: store.isRecording,
                        onSoundFxClick: { store.toggleSoundFxTray() },
                        onRecordClick: { store.toggleRecording() },
                        onSceneSelect: { bank in store.selectBank(bank) }
                    )

                    // 6 Quick FX Buttons: [Horn] [Elphnt] [Reload] [Scrtch] [Vinyl] [Watch]
                    QuickFxBar(
                        activeFx: store.activeQuickFx,
                        onFxClick: { fxName in store.triggerQuickFx(fxName) }
                    )
                }

                // 3. Middle Section: Clips Matrix or 12/24 Pads Grid
                Spacer(minLength: 4)

                if store.isClipsMode {
                    ClipsMatrixView(
                        activeClips: store.activeClips,
                        selectedClipIndex: store.selectedClipIndex,
                        bpm: store.bpm,
                        onClipClick: { index in store.toggleClip(index) }
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    GlowingPadsGridView(
                        store: store,
                        selectedBank: store.selectedBank
                    )
                    .frame(maxHeight: .infinity)
                }

                Spacer(minLength: 4)

                // 4. Bottom Controls Section
                if store.isClipsMode {
                    ClipActionBar(
                        onEdit: { store.openPadEditor(padIndex: store.selectedClipIndex) },
                        onDuplicate: { store.duplicateSelectedClip() },
                        onDelete: { store.deleteSelectedClip() }
                    )

                    AudioFadersStrip(
                        volume: store.volumeLevel,
                        echo116: store.echo116Level,
                        echo18: store.echo18Level,
                        reverb: store.reverbLevel,
                        distortion: store.distortionLevel,
                        onFaderChange: { type, level in store.setFaderLevel(type: type, level: level) },
                        onVipClick: { store.navigateTo(.paywall) },
                        onFillClick: { store.triggerFill() },
                        onCleanClick: { store.triggerClean() }
                    )
                } else if store.isSoundFxOpen {
                    AudioFadersStrip(
                        volume: store.volumeLevel,
                        echo116: store.echo116Level,
                        echo18: store.echo18Level,
                        reverb: store.reverbLevel,
                        distortion: store.distortionLevel,
                        onFaderChange: { type, level in store.setFaderLevel(type: type, level: level) },
                        onVipClick: { store.navigateTo(.paywall) },
                        onFillClick: { store.triggerFill() },
                        onCleanClick: { store.triggerClean() }
                    )
                }

                // Neon App Branding
                NeonAppBranding()
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }
}

// -------------------------------------------------------------
// 1. TOP NAVIGATION BAR
// -------------------------------------------------------------
private struct TopNavigationBar: View {
    let isClipsMode: Bool
    let isPadLocked: Bool
    let onBackClick: () -> Void
    let onCrownClick: () -> Void
    let onModeChange: (Bool) -> Void
    let onLockToggle: () -> Void
    let onSettingsClick: () -> Void

    var body: some View {
        HStack {
            Button(action: onBackClick) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
            }

            Button(action: onCrownClick) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#FF2A85"))
                    .frame(width: 38, height: 38)
            }

            Spacer()

            // Segmented Mode Toggle: [Clips] [Pads]
            HStack(spacing: 2) {
                Button(action: { onModeChange(true) }) {
                    Text("Clips")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isClipsMode ? .black : .white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isClipsMode ? Color.white : Color.clear)
                        )
                }

                Button(action: { onModeChange(false) }) {
                    Text("Pads")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(!isClipsMode ? .black : .white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(!isClipsMode ? Color.white : Color.clear)
                        )
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#281C48").opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

            Spacer()

            // Lock Toggle Pill
            Button(action: onLockToggle) {
                Image(systemName: isPadLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isPadLocked ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isPadLocked ? Color(hex: "#6C3CE9") : Color(hex: "#322359"))
                    )
            }

            Button(action: onSettingsClick) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 38, height: 38)
            }
        }
    }
}

// -------------------------------------------------------------
// 2A. CLIPS TRANSPORT BAR
// -------------------------------------------------------------
private struct ClipsTransportBar: View {
    let bpm: Int
    let isRecording: Bool
    let onStopClick: () -> Void
    let onRecordClick: () -> Void
    let onBpmDecrease: () -> Void
    let onBpmIncrease: () -> Void

    var body: some View {
        HStack {
            Button(action: onStopClick) {
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                    Text("Stop")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            Spacer()

            Button(action: onRecordClick) {
                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .stroke(isRecording ? AppTheme.dangerRed : Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isRecording {
                            Circle()
                                .fill(AppTheme.dangerRed)
                                .frame(width: 10, height: 10)
                        }
                    }
                    Text("Record")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isRecording ? AppTheme.dangerRed : .white.opacity(0.75))
                }
            }

            Spacer()

            // BPM Capsule: [-] 120 BPM [+]
            HStack(spacing: 8) {
                Button(action: onBpmDecrease) {
                    Text("—")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 0) {
                    Text("\(bpm)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("BPM")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Button(action: onBpmIncrease) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#2C1F52"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 8)
    }
}

// -------------------------------------------------------------
// 2B. PADS TOOLBAR
// -------------------------------------------------------------
private struct PadsToolbar: View {
    let selectedBank: PadBank
    let isRecording: Bool
    let onSoundFxClick: () -> Void
    let onRecordClick: () -> Void
    let onSceneSelect: (PadBank) -> Void

    var body: some View {
        HStack {
            Button(action: onSoundFxClick) {
                VStack(spacing: 2) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Sound FX")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            Button(action: onRecordClick) {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(isRecording ? AppTheme.dangerRed : Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isRecording {
                            Circle()
                                .fill(AppTheme.dangerRed)
                                .frame(width: 10, height: 10)
                        }
                    }
                    Text("Record")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isRecording ? AppTheme.dangerRed : .white.opacity(0.8))
                }
            }

            Spacer()

            // Scene A / B Toggle
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Button(action: { onSceneSelect(.bankA) }) {
                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedBank == .bankA ? .black : .white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedBank == .bankA ? Color.white : Color.clear)
                            )
                    }

                    Button(action: { onSceneSelect(.bankB) }) {
                        Text("B")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedBank == .bankB ? .black : .white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedBank == .bankB ? Color.white : Color.clear)
                            )
                    }

                    Button(action: { onSceneSelect(.full24) }) {
                        Text("24")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedBank == .full24 ? .black : .white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedBank == .full24 ? Color.white : Color.clear)
                            )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#352562"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )

                Text("Scene")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
    }
}

// -------------------------------------------------------------
// 3. QUICK FX BAR
// -------------------------------------------------------------
private struct QuickFxBar: View {
    let activeFx: String?
    let onFxClick: (String) -> Void
    let fxList = ["Horn", "Elphnt", "Reload", "Scrtch", "Vinyl", "Watch"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(fxList, id: \.self) { name in
                let isActive = activeFx == name
                Button(action: { onFxClick(name) }) {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isActive ? .white : .white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isActive ? Color(hex: "#6C3CE9") : Color.clear)
                }
                .buttonStyle(.plain)

                if name != fxList.last {
                    Divider()
                        .frame(height: 24)
                        .background(Color.white.opacity(0.12))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#1E1738"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// -------------------------------------------------------------
// 4. MAIN GLOWING NEON PADS GRID
// -------------------------------------------------------------
private struct GlowingPadsGridView: View {
    var store: DrumPadsStore
    let selectedBank: PadBank

    var body: some View {
        if selectedBank == .full24 {
            // Full 24 pads grid (4 columns x 6 rows)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(store.pads) { pad in
                    let isPressed = store.activePads.contains(pad.index)
                    PadCellButton(
                        name: pad.name,
                        index: pad.index,
                        baseColor: Color(hex: pad.colorHex),
                        isPressed: isPressed,
                        onDown: { store.onPadDown(pad.index) },
                        onUp: { store.onPadUp(pad.index) },
                        onLongPress: { store.openPadEditor(padIndex: pad.index) }
                    )
                }
            }
        } else {
            // Scene A (0..11) or Scene B (12..23): 3 columns x 4 rows
            let startIndex = selectedBank == .bankB ? 12 : 0
            let padColors: [Color] = selectedBank == .bankA ? [
                // Scene A: Signature Drum Pads 24 Kit
                AppTheme.padLimeGreen, AppTheme.padLimeGreen, AppTheme.padLimeGreen,
                AppTheme.padLimeGreen, AppTheme.padVividOrange, AppTheme.padNeonMagenta,
                AppTheme.padVividOrange, AppTheme.padVividOrange, AppTheme.padVividOrange,
                AppTheme.padElectricSkyBlue, AppTheme.padElectricSkyBlue, AppTheme.padElectricSkyBlue
            ] : [
                // Scene B: Alternative Electronic Kit
                AppTheme.padHotPink, AppTheme.padHotPink, AppTheme.padHotPink,
                AppTheme.padElectricViolet, AppTheme.padElectricViolet, AppTheme.padElectricViolet,
                AppTheme.padNeonAmber, AppTheme.padNeonAmber, AppTheme.padNeonAmber,
                AppTheme.padNeonAqua, AppTheme.padNeonAqua, AppTheme.padNeonAqua
            ]

            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { col in
                            let localIndex = row * 3 + col
                            let padIndex = startIndex + localIndex
                            let baseColor = padColors[localIndex]
                            let padName = padIndex < store.pads.count ? store.pads[padIndex].name : ""
                            let isPressed = store.activePads.contains(padIndex)

                            PadCellButton(
                                name: padName,
                                index: padIndex,
                                baseColor: baseColor,
                                isPressed: isPressed,
                                onDown: { store.onPadDown(padIndex) },
                                onUp: { store.onPadUp(padIndex) },
                                onLongPress: { store.openPadEditor(padIndex: padIndex) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct PadCellButton: View {
    let name: String
    let index: Int
    let baseColor: Color
    let isPressed: Bool
    let onDown: () -> Void
    let onUp: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Background surface
                RoundedRectangle(cornerRadius: 14)
                    .fill(isPressed ? Color.white : baseColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isPressed ? Color.white : Color.white.opacity(0.22), lineWidth: isPressed ? 2.5 : 1)
                    )
                    .shadow(color: isPressed ? Color.white.opacity(0.6) : baseColor.opacity(0.3), radius: isPressed ? 8 : 4)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPressed ? .black.opacity(0.5) : .white.opacity(0.7))
                    Text(name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isPressed ? .black : .white)
                        .lineLimit(1)
                }
                .padding(8)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.1, dampingFraction: 0.8), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            onDown()
                        }
                    }
                    .onEnded { _ in
                        onUp()
                    }
            )
            .contextMenu {
                Button(action: onLongPress) {
                    Label("Edit Pad Sample", systemImage: "slider.horizontal.3")
                }
            }
        }
    }
}

// -------------------------------------------------------------
// 5. CLIPS MATRIX VIEW (4 cols x 3 rows = 12 clips)
// -------------------------------------------------------------
private struct ClipsMatrixView: View {
    let activeClips: Set<Int>
    let selectedClipIndex: Int
    let bpm: Int
    let onClipClick: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(0..<12, id: \.self) { index in
                let isPlaying = activeClips.contains(index)
                let isSelected = selectedClipIndex == index
                let isEmptySlot = index >= 8

                ClipTileView(
                    index: index,
                    isPlaying: isPlaying,
                    isSelected: isSelected,
                    isEmptySlot: isEmptySlot,
                    onClick: { onClipClick(index) }
                )
            }
        }
    }
}

private struct ClipTileView: View {
    let index: Int
    let isPlaying: Bool
    let isSelected: Bool
    let isEmptySlot: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPlaying ? Color(hex: "#281E60") : Color(hex: "#1B1A32"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.white : (isPlaying ? Color(hex: "#8B5CF6") : Color.white.opacity(0.08)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                if isEmptySlot {
                    Text("+")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    // Mini MIDI Dot Matrix Pattern
                    VStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { r in
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { c in
                                    let show = ((index * 7 + r * 3 + c) % 3) == 0
                                    Circle()
                                        .fill(show ? dotColor(index + r + c) : Color.clear)
                                        .frame(width: 3.5, height: 3.5)
                                }
                            }
                        }
                    }

                    // Sweeping playhead border when playing
                    if isPlaying {
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    private func dotColor(_ seed: Int) -> Color {
        let colors = [
            Color(hex: "#FFD166"),
            Color(hex: "#06D6A0"),
            Color(hex: "#118AB2"),
            Color(hex: "#EF476F")
        ]
        return colors[seed % colors.count]
    }
}

// -------------------------------------------------------------
// 6. CLIP ACTION BAR
// -------------------------------------------------------------
private struct ClipActionBar: View {
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onEdit) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider().frame(height: 24).background(Color.white.opacity(0.15))

            Button(action: onDuplicate) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.square.on.square")
                    Text("Duplicate")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider().frame(height: 24).background(Color.white.opacity(0.15))

            Button(action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#382A72"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// -------------------------------------------------------------
// 7. AUDIO FX FADERS & FILL / CLEAN BUTTONS
// -------------------------------------------------------------
private struct AudioFadersStrip: View {
    let volume: Float
    let echo116: Float
    let echo18: Float
    let reverb: Float
    let distortion: Float
    let onFaderChange: (String, Float) -> Void
    let onVipClick: () -> Void
    let onFillClick: () -> Void
    let onCleanClick: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            // Fill and Clean instant buttons
            HStack(spacing: 12) {
                Button(action: onFillClick) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("FILL")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.accentYellow))
                }

                Button(action: onCleanClick) {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                        Text("CLEAN")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#281C48")))
                }
            }

            // Fader sliders
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    FaderCapsule(title: "Volume", value: volume, isVip: false) { val in
                        onFaderChange("Volume", val)
                    } onVip: { onVipClick() }

                    FaderCapsule(title: "Echo 1/16", value: echo116, isVip: true) { val in
                        onFaderChange("Echo 1/16", val)
                    } onVip: { onVipClick() }

                    FaderCapsule(title: "Echo 1/8", value: echo18, isVip: true) { val in
                        onFaderChange("Echo 1/8", val)
                    } onVip: { onVipClick() }

                    FaderCapsule(title: "Reverb", value: reverb, isVip: true) { val in
                        onFaderChange("Reverb", val)
                    } onVip: { onVipClick() }

                    FaderCapsule(title: "Distortion", value: distortion, isVip: true) { val in
                        onFaderChange("Distortion", val)
                    } onVip: { onVipClick() }
                }
                .padding(.horizontal, 6)
            }
        }
    }
}

private struct FaderCapsule: View {
    let title: String
    let value: Float
    let isVip: Bool
    let onChange: (Float) -> Void
    let onVip: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Background Track
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#221A3E"))
                    .frame(width: 40, height: 74)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                // Filled level
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#4C1D95")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: max(10, 74 * CGFloat(value)))

                // Center indicator groove
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 50)

                // VIP Star Badge
                if isVip {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(hex: "#8B5CF6"))
                                .frame(width: 15, height: 15)
                                .overlay(
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                )
                                .padding(3)
                        }
                        Spacer()
                    }
                    .frame(width: 40, height: 74)
                }
            }
            .onTapGesture {
                if isVip {
                    onVip()
                } else {
                    let next: Float = value > 0.5 ? 0.2 : 0.85
                    onChange(next)
                }
            }

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }
}

// -------------------------------------------------------------
// 8. NEON APP BRANDING
// -------------------------------------------------------------
private struct NeonAppBranding: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Drum Pads ")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color(hex: "#FF2A85"))
            Text("24")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color(hex: "#00E5FF"))
        }
    }
}

