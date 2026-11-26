import SwiftUI

public struct RecordingsScreen: View {
    public var store: DrumPadsStore
    @State private var renamingItem: RecordingItem? = nil
    @State private var renameText: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { store.navigateTo(.main) }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.navyCard))
                }
                Spacer()
                Text("My Recordings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(store.recordings.count) WAV")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.accentYellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if let msg = store.statusBannerMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.accentCyan)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            if store.recordings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 56))
                        .foregroundColor(AppTheme.textMuted)
                    Text("No live recordings yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Tap REC in Pad Player to capture real WAV stems and export 9:16 performance videos.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    Button(action: { store.openPadPlayer(packName: store.activePackName) }) {
                        Text("Open Pad Player")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                }
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(store.recordings) { rec in
                            let isPlaying = store.playingRecordingId == rec.id
                            let isExporting = store.exportingRecordingId == rec.id
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Button(action: { store.togglePlayRecording(rec) }) {
                                        Circle()
                                            .fill(isPlaying ? AppTheme.accentYellow : AppTheme.accentCyan.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                                    .foregroundColor(isPlaying ? .black : AppTheme.accentCyan)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(rec.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("\(rec.packName) • \(rec.bpm) BPM • \(rec.durationFormatted)")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                }

                                HStack(spacing: 8) {
                                    Button(action: { AudioExportService.shared.exportRecording(rec) }) {
                                        Label("WAV", systemImage: "square.and.arrow.up")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(Capsule().fill(AppTheme.navyCardElevated))
                                    }

                                    Button(action: { store.exportRecordingAsVideo(rec) }) {
                                        Label(isExporting ? "Rendering..." : "MP4 Video", systemImage: "video.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(Capsule().fill(AppTheme.accentCyan))
                                    }
                                    .disabled(isExporting)

                                    Button(action: { store.publishRecordingToFeed(rec) }) {
                                        Label("Publish", systemImage: "paperplane.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(Capsule().fill(AppTheme.accentYellow))
                                    }

                                    Spacer()

                                    Button(action: {
                                        renameText = rec.title
                                        renamingItem = rec
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .padding(6)
                                    }

                                    Button(action: { store.deleteRecording(rec) }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.dangerRed)
                                            .padding(6)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.navyCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isPlaying ? AppTheme.accentYellow : AppTheme.navyBorder, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .alert("Rename Recording", isPresented: Binding(
            get: { renamingItem != nil },
            set: { if !$0 { renamingItem = nil } }
        )) {
            TextField("Track title", text: $renameText)
            Button("Cancel", role: .cancel) { renamingItem = nil }
            Button("Save") {
                if let item = renamingItem {
                    store.renameRecording(item, newTitle: renameText)
                }
                renamingItem = nil
            }
        }
    }
}
