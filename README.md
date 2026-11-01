# DrumPads 24 for iOS 🥁📱

Phiên bản độc lập dành riêng cho iOS của ứng dụng **DrumPads 24** (24-Pad Beat Maker) viết hoàn toàn bằng **SwiftUI** và **AVFoundation**.

---

## 🌟 Tính năng chính
* **24 Drum Pads** chuẩn phòng thu chia làm 4 nhóm màu neon (Drums, Bass, Melody, FX).
* **Audio Engine thời gian thực**: Sử dụng `AVAudioEngine` và `AVAudioSourceNode` đạt độ trễ cực thấp (< 20ms).
* **Polyphony 32 Voices**: Thuật toán Voice Stealing mượt mà, không giật lag.
* **Haptic Feedback**: Rung phản hồi chân thực khi bấm pad qua `UIImpactFeedbackGenerator`.
* **Dark Mode & Giao diện hiện đại**: Tối ưu cho mọi kích thước iPhone và iPad (iOS 17+).

---

## 📁 Cấu trúc thư mục
```
DrumPads 24AppIOS/
├── .github/
│   └── workflows/
│       └── build-ios.yml      # CI/CD tự động build file .ipa trên macOS Cloud
├── Sources/
│   └── DrumPadsApp/
│       ├── DrumPadsApp.swift  # Entry point (@main)
│       ├── Audio/             # AudioEngine, VoicePool, LockFreeQueue
│       ├── Models/            # Pad, PadGroup, PadRepository
│       ├── Resources/starter/ # kit.json & 24 file âm thanh .wav
│       ├── Services/          # HapticService
│       ├── ViewModels/        # DrumPadsStore (Observation framework)
│       └── Views/             # DrumPadsView, PadCellView, SettingsView
├── Tests/
│   └── DrumPadsTests/         # Unit tests (PadMapping, VoicePool, Fixture)
├── Info.plist                 # Cấu hình bundle, quyền âm thanh nền
├── project.yml                # File cấu hình sinh Xcode project (xcodegen)
└── Package.swift              # Swift Package Manager manifest
```

---

## 🚀 Tự động build file `.ipa` miễn phí qua GitHub Actions

1. Tạo một repository mới trên GitHub: [github.com/new](https://github.com/new) (chọn **Public**).
2. Đẩy code lên GitHub:
   ```bash
   git remote add origin https://github.com/<tên-bạn>/<tên-repo>.git
   git branch -M main
   git push -u origin main
   ```
3. Vào tab **Actions** trên GitHub -> Đợi máy chủ macOS của GitHub build khoảng 2-3 phút.
4. Tải file **`DrumPadsApp-ipa`** trong mục **Artifacts**.

---

## 📲 Cài đặt vào iPhone qua Sideloadly
1. Cắm iPhone vào máy tính qua cáp USB và bấm **Tin cậy (Trust)**.
2. Mở phần mềm **Sideloadly**.
3. Kéo thả file `DrumPadsApp.ipa` vào Sideloadly.
4. Nhập tài khoản Apple ID của bạn và bấm **Start**.
5. Sau khi cài xong, trên iPhone vào:
   * **Cài đặt (Settings) > Cài đặt chung (General) > Quản lý VPN & Thiết bị (VPN & Device Management)**.
   * Bấm vào email Apple ID của bạn và chọn **Tin cậy (Trust)**.
6. Mở app **Drum Pads 24** và trải nghiệm!

