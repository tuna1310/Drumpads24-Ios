# Test Vectors Fixture Specification (M4 Preparation)

Tài liệu này đặc tả cấu trúc của bộ test vector JSON dùng chung giữa Android (`drumpads-android`) và iOS (`drumpads-ios`).

Theo quyết định đã duyệt trong **ADR-001** và **ADR-006**, Sequencer sẽ được viết độc lập bằng Kotlin và Swift trong Milestone M4, nhưng cả hai nền tảng bắt buộc cùng nạp fixture JSON trong thư mục này để assert kiểm thử đơn vị.

---

## Cấu trúc Test Case Schema

Mỗi test case trong mảng `testCases` sẽ bao gồm:
- `id`: Định danh test case (chuỗi)
- `description`: Mô tả kịch bản test
- `ppq`: Độ phân giải PPQ (cố định là 960 theo ADR-003)
- `bpm`: Tốc độ tempo (nhịp/phút)
- `quantizeGrid`: Lưới lượng tử hóa (`"OFF"`, `"1/16"`, `"1/32"`, `"1/16T"`, `"1/32T"`)
- `swingPercentage`: Tỷ lệ swing (50% = no swing, 50% đến 75%)
- `loopLengthBars`: Độ dài vòng lặp tính theo ô nhịp (ví dụ: 1, 2, 4)
- `inputEvents`: Mảng các sự kiện đầu vào với `rawTick` và `padIndex`
- `expectedOutputEvents`: Mảng kết quả kỳ vọng sau khi quantize, swing và modulo wrap-around (`scheduledTick`, `scheduledSampleTime`, `padIndex`)
