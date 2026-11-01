import SwiftUI

public struct SettingsScreen: View {
    @Bindable public var store: DrumPadsStore
    @State private var unlockAllSounds: Bool = false

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Top Bar
                HStack(spacing: 12) {
                    Button(action: { store.navigateTo(.main) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Text("Settings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // 2. "Get Premium Access" Card
                Button(action: { store.navigateTo(.paywall) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.vipBannerGradient)
                                .frame(width: 48, height: 48)

                            Image(systemName: "play.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Get Premium Access")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("15 000+ Sounds • All Features")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        Circle()
                            .fill(AppTheme.accentCyan)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            )
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppTheme.navyCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppTheme.navyBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                // 3. Toggles Section
                VStack(spacing: 0) {
                    ToggleRow(title: "Unlock all sounds", isOn: $unlockAllSounds)
                    Divider().background(AppTheme.navyBorder).padding(.horizontal, 16)

                    ToggleRow(title: "Haptic feedback", isOn: Binding(
                        get: { store.isHapticEnabled },
                        set: { store.setHapticEnabled($0) }
                    ))
                    Divider().background(AppTheme.navyBorder).padding(.horizontal, 16)

                    ToggleRow(title: "Light show", isOn: Binding(
                        get: { store.isLightShowEnabled },
                        set: { store.setLightShowEnabled($0) }
                    ))
                    Divider().background(AppTheme.navyBorder).padding(.horizontal, 16)

                    // Stress Test Mode Toggle
                    VStack(alignment: .leading, spacing: 6) {
                        ToggleRow(title: "Stress Test (32 voices for 60s)", isOn: Binding(
                            get: { store.isStressTestActive },
                            set: { store.setStressTest($0) }
                        ))

                        if store.isStressTestActive {
                            HStack {
                                Text("REMAINING: \(store.stressSecondsRemaining)s | BUFFER XRUNS: \(store.xrunCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.dangerRed)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.navyCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppTheme.navyBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)

                // 4. Audio Engine & Architecture Specs
                VStack(alignment: .leading, spacing: 8) {
                    Text("AUDIO SYSTEM SPECIFICATIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        SpecRow(title: "Audio Framework", value: "AVAudioEngine + AVAudioSourceNode")
                        SpecRow(title: "Sample Rate", value: "44.1 kHz, 16-bit PCM Stereo")
                        SpecRow(title: "Max Polyphony", value: "32 Voices (Voice Stealing FIFO)")
                        SpecRow(title: "Touch-to-Sound Latency", value: "< 15 ms (Ultra Low)")
                        SpecRow(title: "Sequencer Resolution", value: "960 PPQ Clock")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppTheme.navyCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppTheme.navyBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                }

                // 5. Version Info
                VStack(spacing: 4) {
                    Text("Drum Pads 24 for iOS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Version 1.0.0 (Build 1) • Native Swift & SwiftUI")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.accentYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct SpecRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.accentCyan)
        }
    }
}

