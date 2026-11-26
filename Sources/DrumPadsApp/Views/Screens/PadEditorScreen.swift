import SwiftUI
import UniformTypeIdentifiers

public struct PadEditorScreen: View {
    public var store: DrumPadsStore
    @State private var isDuplicateMode: Bool = false
    @State private var showAudioPicker: Bool = false

    public init(store: DrumPadsStore) {
        self.store = store
    }

    private let colorSwatches = [
        "#E53935", "#FF7A00", "#FFD233", "#38E54D",
        "#00E5FF", "#00B0FF", "#8E24AA", "#E040FB",
        "#FF2A85", "#00897B"
    ]

    public var body: some View {
        let currentPad = store.selectedPadForEdit ?? store.pads[0]

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Header: Back | EDIT PADS | Done
                HStack {
                    Button(action: {
                        store.swapSourcePadIndex = nil
                        isDuplicateMode = false
                        store.navigateTo(.padPlayer)
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.navyCard))
                    }

                    Spacer()

                    VStack(spacing: 1) {
                        Text("EDIT PADS")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(AppTheme.accentYellow)
                        Text(store.activePackName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button(action: {
                        store.swapSourcePadIndex = nil
                        isDuplicateMode = false
                        store.navigateTo(.padPlayer)
                    }) {
                        Text("DONE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Swap / Duplicate Mode Banner
                if store.swapSourcePadIndex != nil || isDuplicateMode {
                    HStack {
                        Text(isDuplicateMode
                             ? "Tap any target pad below to DUPLICATE Pad \(currentPad.index + 1) into it"
                             : "Tap any target pad below to SWAP positions with Pad \(currentPad.index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.accentCyan)
                        Spacer()
                        Button("Cancel") {
                            store.swapSourcePadIndex = nil
                            isDuplicateMode = false
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.accentPurple.opacity(0.4))
                }

                // Side-by-side Scene A (1..12) and Scene B (13..24) Mini Pad Grids matching Play Store Reference
                HStack(spacing: 12) {
                    miniSceneGrid(title: "SCENE A", range: 0..<12, currentPad: currentPad)
                    miniSceneGrid(title: "SCENE B", range: 12..<24, currentPad: currentPad)
                }
                .padding(.horizontal, 16)

                // Action Row: Sound Waveform Editor | Swap | Duplicate | Import
                HStack(spacing: 8) {
                    Button(action: {
                        store.refreshWaveformPeaks(for: currentPad)
                        store.navigateTo(.soundEditor)
                    }) {
                        Label("WAVE & MIC", systemImage: "waveform")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(AppTheme.accentCyan))
                    }

                    Button(action: {
                        isDuplicateMode = false
                        store.swapSourcePadIndex = (store.swapSourcePadIndex == currentPad.index) ? nil : currentPad.index
                    }) {
                        Label("SWAP", systemImage: "arrow.left.arrow.right")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(store.swapSourcePadIndex != nil ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(store.swapSourcePadIndex != nil ? AppTheme.accentYellow : AppTheme.navyCardElevated))
                    }

                    Button(action: {
                        store.swapSourcePadIndex = nil
                        isDuplicateMode.toggle()
                    }) {
                        Label("COPY", systemImage: "doc.on.doc")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(isDuplicateMode ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(isDuplicateMode ? AppTheme.accentPink : AppTheme.navyCardElevated))
                    }

                    Button(action: { showAudioPicker = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(AppTheme.accentPurple))
                    }
                }
                .padding(.horizontal, 16)

                // Selected Pad Inspector Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("PAD \(currentPad.index + 1) SETTINGS")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(AppTheme.accentYellow)
                        Spacer()
                        Button(action: { store.triggerPad(index: currentPad.index) }) {
                            Label("Test Sound", systemImage: "speaker.wave.2.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.accentCyan)
                        }
                    }

                    // Name field
                    TextField("Pad Label", text: Binding(
                        get: { currentPad.name },
                        set: { val in
                            var updated = currentPad
                            updated.name = String(val.prefix(16))
                            store.updatePad(updated)
                        }
                    ))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.navySurface))

                    // Play Mode Selector (ONE SHOT / LOOP / HOLD)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PLAY MODE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach(PadPlayMode.allCases, id: \.self) { mode in
                                let selected = currentPad.playMode == mode
                                Button(action: {
                                    var updated = currentPad
                                    updated.playMode = mode
                                    store.updatePad(updated)
                                }) {
                                    Text(mode.rawValue)
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(selected ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(selected ? AppTheme.accentYellow : AppTheme.navySurface))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Choke Group Selector (None / Group 1 / Group 2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GROUP CHOKE (MUTE EXCLUSIVE)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        HStack(spacing: 8) {
                            ForEach([0, 1, 2], id: \.self) { grp in
                                let selected = currentPad.chokeGroup == grp
                                Button(action: {
                                    var updated = currentPad
                                    updated.chokeGroup = grp
                                    store.updatePad(updated)
                                }) {
                                    Text(grp == 0 ? "NONE" : "GROUP \(grp)")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(selected ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(selected ? AppTheme.accentCyan : AppTheme.navySurface))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color Swatches
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PAD COLOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(colorSwatches, id: \.self) { hex in
                                    let isSel = currentPad.colorHex.caseInsensitiveCompare(hex) == .orderedSame
                                    Button(action: {
                                        var updated = currentPad
                                        updated.colorHex = hex
                                        store.updatePad(updated)
                                    }) {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: isSel ? 2.5 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Pitch & Volume Quick Sliders
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pitch Shift")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(currentPad.pitch > 0 ? "+" : "")\(Int(currentPad.pitch)) st")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.accentCyan)
                        }
                        Slider(value: Binding(
                            get: { Double(currentPad.pitch) },
                            set: { v in var u = currentPad; u.pitch = Float(v); store.updatePad(u) }
                        ), in: -12...12)
                        .tint(AppTheme.accentCyan)

                        HStack {
                            Text("Pad Volume")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(currentPad.volume * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.accentYellow)
                        }
                        Slider(value: Binding(
                            get: { Double(currentPad.volume) },
                            set: { v in var u = currentPad; u.volume = Float(v); store.updatePad(u) }
                        ), in: 0...1.5)
                        .tint(AppTheme.accentYellow)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.navyCard))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 30)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .fileImporter(
            isPresented: $showAudioPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let first = urls.first {
                store.importCustomAudioURL(first, for: currentPad.index)
            }
        }
    }

    private func miniSceneGrid(title: String, range: Range<Int>, currentPad: Pad) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
        return VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(AppTheme.textSecondary)
            LazyVGrid(columns: cols, spacing: 4) {
                ForEach(Array(range), id: \.self) { idx in
                    if idx < store.pads.count {
                        let p = store.pads[idx]
                        let isSel = p.id == currentPad.id
                        Button(action: {
                            if let srcIdx = store.swapSourcePadIndex {
                                store.swapPads(fromIndex: srcIdx, toIndex: idx)
                            } else if isDuplicateMode {
                                store.duplicatePad(sourceIndex: currentPad.index, targetIndex: idx)
                                isDuplicateMode = false
                            } else {
                                store.selectPadForEdit(p)
                                store.triggerPad(index: idx)
                            }
                        }) {
                            VStack(spacing: 1) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 9, weight: .black))
                                Text(p.name)
                                    .font(.system(size: 7, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: p.colorHex).opacity(isSel ? 0.95 : 0.38))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSel ? AppTheme.accentYellow : .white.opacity(0.25), lineWidth: isSel ? 2 : 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
        }
    }
}

public struct ProjectEditorView: View {
    public var store: DrumPadsStore
    @State private var packTitle: String = "My Custom Kit"
    @State private var selectedGenre: MusicGenre = .trap
    @State private var bpm: Int = 128

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: { store.navigateTo(.main) }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.navyCard))
                }
                Spacer()
                Text("CREATE SOUND PACK")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(AppTheme.accentYellow)
                Spacer()
                Spacer().frame(width: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 14) {
                Text("PACK NAME")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Enter Sound Pack Name", text: $packTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navySurface))

                Text("BASE GENRE TEMPLATE (24 PADS)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MusicGenre.allCases.filter { $0 != .all }, id: \.self) { g in
                            let sel = selectedGenre == g
                            Button(action: { selectedGenre = g }) {
                                Text(g.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(sel ? .black : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(sel ? AppTheme.accentCyan : AppTheme.navySurface))
                            }
                        }
                    }
                }

                HStack {
                    Text("DEFAULT TEMPO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Button(action: { bpm = max(60, bpm - 4) }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.white)
                    }
                    Text("\(bpm) BPM")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(AppTheme.accentYellow)
                        .padding(.horizontal, 8)
                    Button(action: { bpm = min(200, bpm + 4) }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.navyCard))
            .padding(.horizontal, 16)

            Button(action: {
                store.createCustomSoundPack(title: packTitle, genre: selectedGenre, bpm: bpm)
            }) {
                Text("CREATE PACK & OPEN PAD EDITOR")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(AppTheme.accentYellow))
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}
