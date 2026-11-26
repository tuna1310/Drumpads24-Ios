import SwiftUI
import UniformTypeIdentifiers

public struct SoundEditorScreen: View {
    public var store: DrumPadsStore
    @State private var showAudioImporter: Bool = false

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        let pad = store.selectedPadForEdit ?? store.pads[0]

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: { store.navigateTo(.padEditor) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.navyCard))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("EDIT SOUND")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(AppTheme.accentYellow)
                        Text("Pad \(pad.index + 1) • \(pad.name)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button(action: { store.navigateTo(.padEditor) }) {
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

                // Interactive Waveform & S/E Trim Box
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.navySurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.navyBorder, lineWidth: 1)
                            )

                        GeometryReader { geo in
                            let peaks = store.editingWaveformPeaks
                            let count = max(1, peaks.count)
                            let startX = CGFloat(pad.trimStart) * geo.size.width
                            let endX = CGFloat(pad.trimEnd) * geo.size.width

                            // Active region highlight
                            Rectangle()
                                .fill(AppTheme.accentCyan.opacity(0.14))
                                .frame(width: max(4, endX - startX), height: geo.size.height)
                                .offset(x: startX)

                            // Waveform Bars
                            HStack(alignment: .center, spacing: 2) {
                                ForEach(0..<count, id: \.self) { idx in
                                    let ratio = Float(idx) / Float(count)
                                    let inRange = ratio >= pad.trimStart && ratio <= pad.trimEnd
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(inRange ? AppTheme.accentCyan : AppTheme.textMuted.opacity(0.4))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: max(8, CGFloat(peaks[idx]) * (geo.size.height - 24)))
                                }
                            }
                            .padding(.horizontal, 6)
                            .frame(maxHeight: .infinity)

                            // S Marker Line
                            Rectangle()
                                .fill(AppTheme.accentCyan)
                                .frame(width: 2.5, height: geo.size.height)
                                .offset(x: startX)
                                .overlay(
                                    Text("S")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(4)
                                        .background(Circle().fill(AppTheme.accentCyan))
                                        .offset(x: startX - 8, y: -geo.size.height * 0.42),
                                    alignment: .leading
                                )

                            // E Marker Line
                            Rectangle()
                                .fill(AppTheme.accentYellow)
                                .frame(width: 2.5, height: geo.size.height)
                                .offset(x: max(0, endX - 2.5))
                                .overlay(
                                    Text("E")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(4)
                                        .background(Circle().fill(AppTheme.accentYellow))
                                        .offset(x: max(0, endX - 18), y: geo.size.height * 0.42),
                                    alignment: .leading
                                )
                        }
                        .padding(8)
                    }
                    .frame(height: 150)

                    // Trim Start / End Sliders
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start (S): \(Int(pad.trimStart * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.accentCyan)
                            Slider(value: Binding(
                                get: { Double(pad.trimStart) },
                                set: { val in
                                    var updated = pad
                                    updated.trimStart = Float(min(val, Double(pad.trimEnd) - 0.05))
                                    store.updatePad(updated)
                                }
                            ), in: 0...0.92)
                            .tint(AppTheme.accentCyan)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("End (E): \(Int(pad.trimEnd * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.accentYellow)
                            Slider(value: Binding(
                                get: { Double(pad.trimEnd) },
                                set: { val in
                                    var updated = pad
                                    updated.trimEnd = Float(max(val, Double(pad.trimStart) + 0.05))
                                    store.updatePad(updated)
                                }
                            ), in: 0.08...1.0)
                            .tint(AppTheme.accentYellow)
                        }
                    }

                    // Fade In / Fade Out Sliders
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fade In: \(Int(pad.fadeInRatio * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Slider(value: Binding(
                                get: { Double(pad.fadeInRatio) },
                                set: { val in
                                    var updated = pad
                                    updated.fadeInRatio = Float(val)
                                    store.updatePad(updated)
                                }
                            ), in: 0...0.5)
                            .tint(AppTheme.accentPink)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fade Out: \(Int(pad.fadeOutRatio * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Slider(value: Binding(
                                get: { Double(pad.fadeOutRatio) },
                                set: { val in
                                    var updated = pad
                                    updated.fadeOutRatio = Float(val)
                                    store.updatePad(updated)
                                }
                            ), in: 0...0.5)
                            .tint(AppTheme.accentPink)
                        }
                    }

                    // Action Buttons Row: Audition, Crop & Bake, Reset
                    HStack(spacing: 10) {
                        Button(action: { store.triggerPad(index: pad.index) }) {
                            Label("PLAY", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(AppTheme.accentCyan))
                        }

                        Button(action: { store.applyCropAndFadeToSelectedPad() }) {
                            Label("CROP", systemImage: "scissors")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(AppTheme.accentYellow))
                        }

                        Button(action: { store.resetSelectedPadSound() }) {
                            Label("RESET", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(AppTheme.navyCardElevated))
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.navyCard))
                .padding(.horizontal, 16)

                // Microphone Capture & File Import Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("CAPTURE OR IMPORT AUDIO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 12) {
                        Button(action: { store.toggleMicSampling() }) {
                            HStack(spacing: 8) {
                                Image(systemName: store.isMicSampling ? "stop.circle.fill" : "mic.fill")
                                Text(store.isMicSampling ? "STOP MIC" : "MIC RECORD")
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(store.isMicSampling ? AppTheme.dangerRed : AppTheme.accentPink))
                        }

                        Button(action: { showAudioImporter = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.badge.plus")
                                Text("IMPORT AUDIO")
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.accentPurple))
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.navyCard))
                .padding(.horizontal, 16)

                // Per-Pad Effects (Pitch, Volume, Pan, Reverb, Distortion)
                VStack(alignment: .leading, spacing: 10) {
                    Text("PER-PAD EFFECTS & MIX")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)

                    sliderRow(label: "Volume", valText: "\(Int(pad.volume * 100))%", value: Double(pad.volume), range: 0...1.5, tint: AppTheme.accentYellow) { v in
                        var u = pad; u.volume = Float(v); store.updatePad(u)
                    }
                    sliderRow(label: "Pitch", valText: "\(pad.pitch > 0 ? "+" : "")\(Int(pad.pitch)) st", value: Double(pad.pitch), range: -12...12, tint: AppTheme.accentCyan) { v in
                        var u = pad; u.pitch = Float(v); store.updatePad(u)
                    }
                    sliderRow(label: "Pan", valText: pad.pan < -0.05 ? "L" : (pad.pan > 0.05 ? "R" : "C"), value: Double(pad.pan), range: -1...1, tint: AppTheme.accentPink) { v in
                        var u = pad; u.pan = Float(v); store.updatePad(u)
                    }
                    sliderRow(label: "Reverb Send", valText: "\(Int(pad.padReverbSend * 100))%", value: Double(pad.padReverbSend), range: 0...1, tint: AppTheme.accentPurple) { v in
                        var u = pad; u.padReverbSend = Float(v); store.updatePad(u)
                    }
                    sliderRow(label: "Distortion", valText: "\(Int(pad.padDistortion * 100))%", value: Double(pad.padDistortion), range: 0...1, tint: AppTheme.dangerRed) { v in
                        var u = pad; u.padDistortion = Float(v); store.updatePad(u)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(AppTheme.navyCard))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 30)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .fileImporter(
            isPresented: $showAudioImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let first = urls.first {
                store.importCustomAudioURL(first, for: pad.index)
            }
        }
    }

    private func sliderRow(
        label: String,
        valText: String,
        value: Double,
        range: ClosedRange<Double>,
        tint: Color,
        onChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(valText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(tint)
            }
            Slider(value: Binding(get: { value }, set: onChange), in: range)
                .tint(tint)
        }
    }
}
