import SwiftUI
import UniformTypeIdentifiers

public struct PadEditorScreen: View {
    public var store: DrumPadsStore
    @State private var selectedIndex: Int
    @State private var padName: String = ""
    @State private var volume: Float = 1.0
    @State private var pitch: Float = 0.0
    @State private var pan: Float = 0.0
    @State private var isShowingFileImporter: Bool = false
    @State private var isShowingSwapPicker: Bool = false
    @State private var targetSwapIndex: Int = 0

    public init(store: DrumPadsStore) {
        self.store = store
        _selectedIndex = State(initialValue: store.selectedPadForEditing)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button(action: { store.navigateTo(.padPlayer) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Text("Pad Editor (Pad #\(selectedIndex + 1))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {
                        savePadChanges()
                        store.navigateTo(.padPlayer)
                    }) {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.accentCyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // 1. Interactive Pad Picker Carousel (0..23)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<store.pads.count, id: \.self) { idx in
                            let isSel = selectedIndex == idx
                            Button(action: {
                                selectedIndex = idx
                                loadPadData(at: idx)
                            }) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isSel ? .black : .white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSel ? Color.white : Color(hex: store.pads[idx].colorHex))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 2. Waveform Visualizer & Audition
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#16152B"))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.navyBorder, lineWidth: 1))
                            .frame(height: 110)

                        // Waveform Bars
                        HStack(spacing: 3) {
                            ForEach(0..<40, id: \.self) { bar in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(AppTheme.accentCyan.opacity(0.8))
                                    .frame(width: 4, height: CGFloat(15 + ((bar * 17) % 75)))
                            }
                        }

                        // Play/Test Button Overlay
                        Button(action: {
                            store.onPadDown(selectedIndex)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                store.onPadUp(selectedIndex)
                            }
                        }) {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.white)
                                )
                        }
                    }

                    HStack {
                        Text("Sample: \(padName)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("16-bit 44.1kHz")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 16)

                // 3. Import Audio Button
                Button(action: { isShowingFileImporter = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(AppTheme.accentYellow)
                        Text("Import Audio Sample (Files / iCloud)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.navyCard)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.navyBorder, lineWidth: 1))
                    )
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                // 4. Sample Properties & Sliders
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pad Name")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Name", text: $padName)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.navyCardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.navyBorder, lineWidth: 1))
                            )
                            .foregroundColor(.white)
                    }

                    // Volume
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Volume")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("\(Int(volume * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.accentCyan)
                        }
                        Slider(value: $volume, in: 0...1.5)
                            .tint(AppTheme.accentCyan)
                    }

                    // Pitch
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Pitch Transpose")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%+.1f st", pitch))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.accentYellow)
                        }
                        Slider(value: $pitch, in: -12...12, step: 1)
                            .tint(AppTheme.accentYellow)
                    }

                    // Pan
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Stereo Pan")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(pan < -0.1 ? "L \(Int(abs(pan) * 100))" : (pan > 0.1 ? "R \(Int(pan * 100))" : "Center"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Slider(value: $pan, in: -1...1)
                            .tint(Color(hex: "#8B5CF6"))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.navyCard)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.navyBorder, lineWidth: 1))
                )
                .padding(.horizontal, 16)

                // 5. Swap Pad & Duplicate Pad Actions
                HStack(spacing: 12) {
                    Button(action: { isShowingSwapPicker = true }) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Swap Pad")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#382A72")))
                    }

                    Button(action: {
                        duplicatePad()
                    }) {
                        HStack {
                            Image(systemName: "plus.square.on.square")
                            Text("Duplicate")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#281C48")))
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .onAppear {
            loadPadData(at: selectedIndex)
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    _ = url.startAccessingSecurityScopedResource()
                    store.importAudio(for: selectedIndex, url: url)
                    padName = url.deletingPathExtension().lastPathComponent
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let err):
                print("[FileImporter] Error: \(err)")
            }
        }
        .confirmationDialog("Swap Pad #\(selectedIndex + 1) With...", isPresented: $isShowingSwapPicker, titleVisibility: .visible) {
            ForEach(0..<store.pads.count, id: \.self) { otherIdx in
                if otherIdx != selectedIndex {
                    Button("Pad #\(otherIdx + 1): \(store.pads[otherIdx].name)") {
                        store.swapPads(index1: selectedIndex, index2: otherIdx)
                        loadPadData(at: selectedIndex)
                    }
                }
            }
        }
    }

    private func loadPadData(at index: Int) {
        guard index >= 0 && index < store.pads.count else { return }
        let pad = store.pads[index]
        self.padName = pad.name
        self.volume = pad.volume
        self.pitch = pad.pitch
        self.pan = pad.pan
    }

    private func savePadChanges() {
        store.updatePadProperties(
            index: selectedIndex,
            name: padName,
            volume: volume,
            pitch: pitch,
            pan: pan
        )
    }

    private func duplicatePad() {
        let nextIndex = (selectedIndex + 1) % store.pads.count
        store.updatePadProperties(
            index: nextIndex,
            name: "\(padName) (Copy)",
            volume: volume,
            pitch: pitch,
            pan: pan
        )
        selectedIndex = nextIndex
        loadPadData(at: nextIndex)
    }
}

// -------------------------------------------------------------
// PROJECT EDITOR SCREEN (Custom Sound Packs)
// -------------------------------------------------------------
public struct ProjectEditorView: View {
    public var store: DrumPadsStore
    @State private var projectName: String = "My Custom Pack"
    @State private var selectedGenre: Genre = .edm
    @State private var bpm: Int = 120

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button(action: { store.navigateTo(.main) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Text("Custom Sound Pack Editor")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {
                        let newPack = SoundPackItem(
                            title: projectName,
                            subtitle: "Custom User Kit",
                            genre: selectedGenre.rawValue,
                            bpm: bpm,
                            gradientHexes: ["#FF2A85", "#00DFD8"],
                            author: store.userProfile.userName
                        )
                        store.soundPacks.insert(newPack, at: 0)
                        store.openPadPlayer(packName: projectName)
                    }) {
                        Text("Create")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.accentCyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Project Details
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sound Pack Name")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Pack Title", text: $projectName)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.navyCardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.navyBorder, lineWidth: 1))
                            )
                            .foregroundColor(.white)
                    }

                    // Genre Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Musical Genre")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        Picker("Genre", selection: $selectedGenre) {
                            ForEach(Genre.allCases.filter { $0 != .all }) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // BPM
                    HStack {
                        Text("Default BPM: \(bpm)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Stepper("", value: $bpm, in: 60...200)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.navyCard)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.navyBorder, lineWidth: 1))
                )
                .padding(.horizontal, 16)

                // Quick Pad Assignment Guide
                VStack(alignment: .leading, spacing: 10) {
                    Text("PAD MAPPING PREVIEW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        ForEach(store.pads.prefix(6)) { pad in
                            HStack {
                                Text("\(pad.index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: pad.colorHex)))

                                Text(pad.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)

                                Spacer()

                                Text(pad.group.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppTheme.accentYellow)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.navyCardElevated))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

