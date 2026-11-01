import SwiftUI

public struct SettingsView: View {
    @Bindable var store: DrumPadsStore
    @Environment(\.dismiss) private var dismiss

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Cài đặt Âm thanh & Phản hồi") {
                    Toggle("Phản hồi rung (Haptic)", isOn: Binding(
                        get: { store.isHapticEnabled },
                        set: { store.setHapticEnabled($0) }
                    ))
                }

                Section("Chế độ Debug & Kiểm thử Áp lực") {
                    Toggle("Stress Test (32 Voice đồng thời)", isOn: Binding(
                        get: { store.isStressTestActive },
                        set: { store.setStressTest($0) }
                    ))

                    if store.isStressTestActive {
                        HStack {
                            Text("Thời gian còn lại:")
                            Spacer()
                            Text("\(store.stressSecondsRemaining)s")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        HStack {
                            Text("Số xrun phát hiện:")
                            Spacer()
                            Text("\(store.xrunCount)")
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Section("Thông tin phiên bản") {
                    HStack {
                        Text("Milestone")
                        Spacer()
                        Text("M1 (24-Pad Native)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Audio Engine")
                        Spacer()
                        Text("AVAudioEngine (32 Voice Limit)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
        }
    }
}
