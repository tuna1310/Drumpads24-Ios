import SwiftUI

public struct MyStudioScreen: View {
    public var store: DrumPadsStore
    @State private var isShowingRecordingsSheet: Bool = false

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // 1. Header
                HStack {
                    Spacer()
                    Text("My")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding(.top, 12)

                // 2. Quick Action Studio Tools Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        StudioToolCard(
                            title: "Extract vocals with Unmix",
                            systemIcon: "star.fill",
                            iconColor: Color(hex: "#4361EE")
                        ) {
                            store.navigateTo(.paywall)
                        }

                        StudioToolCard(
                            title: "Create sound pack",
                            systemIcon: "plus",
                            iconColor: Color(hex: "#F77F00")
                        ) {
                            store.navigateTo(.projectEditor)
                        }

                        StudioToolCard(
                            title: "Edit sounds with Audio Editor",
                            systemIcon: "waveform.path.badge.plus",
                            iconColor: Color(hex: "#D62246")
                        ) {
                            store.openPadEditor(padIndex: 0)
                        }

                        StudioToolCard(
                            title: "Open sequencer",
                            systemIcon: "slider.horizontal.below.rectangle",
                            iconColor: Color(hex: "#06D6A0")
                        ) {
                            store.setClipsMode(true)
                            store.openPadPlayer(packName: "Sequencer Session")
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 3. Library List Items
                VStack(spacing: 0) {
                    LibraryMenuRow(
                        title: "Recordings (\(store.recordings.count))",
                        systemIcon: "record.circle"
                    ) {
                        isShowingRecordingsSheet = true
                    }

                    Divider().background(AppTheme.navyBorder).padding(.leading, 54)

                    LibraryMenuRow(
                        title: "Projects",
                        systemIcon: "folder.fill"
                    ) {
                        store.navigateTo(.projectEditor)
                    }

                    Divider().background(AppTheme.navyBorder).padding(.leading, 54)

                    LibraryMenuRow(
                        title: "Favorite sound packs",
                        systemIcon: "heart.fill"
                    ) {
                        store.navigateTo(.paywall)
                    }

                    Divider().background(AppTheme.navyBorder).padding(.leading, 54)

                    LibraryMenuRow(
                        title: "Downloaded sound packs",
                        systemIcon: "arrow.down.circle.fill"
                    ) {
                        store.navigateTo(.recentlyUsed)
                    }

                    Divider().background(AppTheme.navyBorder).padding(.leading, 54)

                    LibraryMenuRow(
                        title: "Recently used",
                        systemIcon: "clock.fill"
                    ) {
                        store.navigateTo(.recentlyUsed)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.navyCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.navyBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 100)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .sheet(isPresented: $isShowingRecordingsSheet) {
            RecordingsSheetView(store: store)
        }
    }
}

private struct StudioToolCard: View {
    let title: String
    let systemIcon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: systemIcon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(width: 130, height: 130)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.navyCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.navyBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryMenuRow: View {
    let title: String
    let systemIcon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemIcon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.accentYellow)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

// -------------------------------------------------------------
// RECORDINGS SHEET VIEW
// -------------------------------------------------------------
public struct RecordingsSheetView: View {
    public var store: DrumPadsStore
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.navyBackground.ignoresSafeArea()

                if store.recordings.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "waveform.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textMuted)
                        Text("No recordings yet")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Open the Pad Player and tap Record to capture your beat performance!")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List {
                        ForEach(store.recordings) { rec in
                            HStack(spacing: 14) {
                                Button(action: {
                                    // Trigger quick preview
                                    store.onPadDown(0)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        store.onPadUp(0)
                                    }
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppTheme.accentCyan)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(rec.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("\(rec.durationFormatted) • \(rec.packName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Button(action: { store.shareRecording(rec) }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.accentYellow)
                                        .padding(8)
                                        .background(Circle().fill(AppTheme.navyCardElevated))
                                }
                                .buttonStyle(.plain)
                            }
                            .listRowBackground(AppTheme.navyCard)
                        }
                        .onDelete { indices in
                            for i in indices {
                                store.deleteRecording(store.recordings[i].id)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accentCyan)
                }
            }
        }
    }
}

