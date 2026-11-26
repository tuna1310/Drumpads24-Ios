import SwiftUI

public struct ClipEditorScreen: View {
    public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        let clip = store.editingClip
        let selectedPad = store.pads.indices.contains(store.selectedSequencerPadIndex)
            ? store.pads[store.selectedSequencerPadIndex]
            : store.pads.first

        VStack(spacing: 0) {
            // Top Bar matching Play Store reference: Close | Clip Name | DONE
            HStack {
                Button(action: {
                    store.stopSequencerPlayback()
                    store.navigateTo(.padPlayer)
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.navyCard))
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(clip.name)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                    Text("CREATE BEATS • 16-STEP SEQUENCER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accentYellow)
                }

                Spacer()

                Button(action: {
                    store.stopSequencerPlayback()
                    store.navigateTo(.padPlayer)
                }) {
                    Text("DONE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppTheme.accentYellow))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Active Pattern & BPM Row
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Button(action: { store.adjustBpm(-4) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(AppTheme.navyCardElevated))
                    }
                    Text("\(store.bpm) BPM")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(AppTheme.accentCyan)
                    Button(action: { store.adjustBpm(4) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(AppTheme.navyCardElevated))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))

                HStack(spacing: 6) {
                    Button(action: { store.cyclePatternPreset(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(ClipPatternPresets.presetNames[store.activePatternPresetIndex])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Button(action: { store.cyclePatternPreset(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // 4x4 16-Step Sequencer Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<16, id: \.self) { step in
                    let isSelectedPadActive = store.stepHasPadHit(step: step, padIndex: store.selectedSequencerPadIndex)
                    let hasOtherHit = store.stepHasAnyHit(step)
                    let isCurrentStep = store.isSequencerPlaying && store.currentSequencerStep == step
                    let stepColor = isSelectedPadActive
                        ? AppTheme.accentPink
                        : (hasOtherHit ? AppTheme.accentPurple.opacity(0.6) : AppTheme.navyCardElevated)

                    Button(action: {
                        store.toggleSequencerStep(step)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(stepColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            isCurrentStep ? AppTheme.accentCyan : (isSelectedPadActive ? .white.opacity(0.6) : AppTheme.navyBorder),
                                            lineWidth: isCurrentStep ? 2.5 : 1.2
                                        )
                                )
                                .shadow(color: isSelectedPadActive ? AppTheme.accentPink.opacity(0.5) : .clear, radius: 6)

                            VStack(spacing: 4) {
                                Text("\(step + 1)")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(.white)
                                if isSelectedPadActive {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 6, height: 6)
                                } else if hasOtherHit {
                                    Circle()
                                        .fill(AppTheme.accentCyan)
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                        .aspectRatio(1.15, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Play / Stop / Clear Controls
            HStack(spacing: 12) {
                Button(action: { store.toggleSequencerPlayback() }) {
                    HStack(spacing: 8) {
                        Image(systemName: store.isSequencerPlaying ? "stop.fill" : "play.fill")
                        Text(store.isSequencerPlaying ? "STOP PATTERN" : "PLAY PATTERN")
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(store.isSequencerPlaying ? AppTheme.dangerRed : AppTheme.accentCyan))
                }

                Button(action: {
                    store.clipSlots[store.editingClipIndex].hits.removeAll()
                }) {
                    Text("CLEAR")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(AppTheme.navyCard))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Pad Selector Strip for Assigning Steps
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("EDITING TRACK FOR PAD:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(selectedPad?.name ?? "Pad 1")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(AppTheme.accentYellow)
                    Spacer()
                }
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.pads) { pad in
                            let isSel = pad.index == store.selectedSequencerPadIndex
                            Button(action: {
                                store.selectedSequencerPadIndex = pad.index
                                store.triggerPad(index: pad.index)
                            }) {
                                VStack(spacing: 3) {
                                    Text("P\(pad.index + 1)")
                                        .font(.system(size: 10, weight: .black))
                                    Text(pad.name)
                                        .font(.system(size: 10, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundColor(isSel ? .black : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(minWidth: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSel ? AppTheme.accentYellow : Color(hex: pad.colorHex).opacity(0.35))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(hex: pad.colorHex), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}
