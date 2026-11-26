import SwiftUI

public struct MyStudioScreen: View {
    public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("My Studio")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { store.navigateTo(.projectEditor) }) {
                        Label("New Kit", systemImage: "plus")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Quick Navigation Cards: Recordings & Recently Used
                HStack(spacing: 12) {
                    Button(action: { store.navigateTo(.recordings) }) {
                        studioStatCard(
                            icon: "waveform.badge.mic",
                            title: "Recordings",
                            subtitle: "\(store.recordings.count) WAV tracks",
                            accent: AppTheme.accentCyan
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: { store.navigateTo(.recentlyUsed) }) {
                        studioStatCard(
                            icon: "clock.arrow.circlepath",
                            title: "Recently Used",
                            subtitle: "\(store.recentlyUsedPacks.count) kits",
                            accent: AppTheme.accentYellow
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // Custom Sound Packs
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("CUSTOM SOUND PACKS (\(store.customPacks.count))")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Button("Create +") { store.navigateTo(.projectEditor) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.accentYellow)
                    }
                    .padding(.horizontal, 16)

                    if store.customPacks.isEmpty {
                        Button(action: { store.navigateTo(.projectEditor) }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.accentYellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Build Your First Custom Pack")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Import audio or sample from mic on all 24 pads")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.navyCard))
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ForEach(store.customPacks) { pack in
                            packListRow(pack)
                        }
                    }
                }

                // Favorite Sound Packs
                VStack(alignment: .leading, spacing: 10) {
                    Text("FAVORITES (\(store.favoritePacks.count))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 16)

                    if store.favoritePacks.isEmpty {
                        Text("Tap the heart icon on any Sound Pack to save it here.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, 16)
                    } else {
                        ForEach(store.favoritePacks) { pack in
                            packListRow(pack)
                        }
                    }
                }

                // Recent Recordings Preview
                if !store.recordings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("RECENT RECORDINGS")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Button("See All") { store.navigateTo(.recordings) }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.accentCyan)
                        }
                        .padding(.horizontal, 16)

                        ForEach(store.recordings.prefix(3)) { rec in
                            HStack(spacing: 12) {
                                Button(action: { store.togglePlayRecording(rec) }) {
                                    Circle()
                                        .fill(store.playingRecordingId == rec.id ? AppTheme.accentYellow : AppTheme.accentCyan.opacity(0.2))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: store.playingRecordingId == rec.id ? "stop.fill" : "play.fill")
                                                .foregroundColor(store.playingRecordingId == rec.id ? .black : AppTheme.accentCyan)
                                        )
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rec.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("\(rec.packName) • \(rec.durationFormatted)")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                Button(action: { store.exportRecordingAsVideo(rec) }) {
                                    Image(systemName: "video.badge.plus")
                                        .foregroundColor(AppTheme.accentCyan)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.navyCard))
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }

    private func studioStatCard(icon: String, title: String, subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(accent)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.navyCard)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.navyBorder, lineWidth: 1))
        )
    }

    private func packListRow(_ pack: SoundPack) -> some View {
        Button(action: {
            store.loadSoundPack(pack)
            store.navigateTo(.padPlayer)
        }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: pack.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "play.fill").foregroundColor(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(pack.genre.displayName) • \(pack.bpm) BPM")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Button(action: {
                    store.loadSoundPack(pack)
                    store.selectedPadForEdit = store.pads.first
                    store.navigateTo(.padEditor)
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(AppTheme.accentYellow)
                        .padding(8)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.navyCard))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}
