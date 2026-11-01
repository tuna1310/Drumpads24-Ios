import SwiftUI

public struct DrumPadsView: View {
    @State private var store = DrumPadsStore()
    @State private var isShowingSettings = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#121212")
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    if store.isStressTestActive {
                        HStack {
                            Text("STRESS TEST ACTIVE: \(store.stressSecondsRemaining)s | XRUNS: \(store.xrunCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.pads) { pad in
                            let isPressed = store.activePads.contains(pad.index)
                            PadCellView(
                                pad: pad,
                                isPressed: isPressed,
                                onTouchDown: { store.onPadDown(pad.index) },
                                onTouchUp: { store.onPadUp(pad.index) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("24-PAD BEAT MAKER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(store: store)
            }
        }
    }
}

public struct PadCellView: View {
    public let pad: Pad
    public let isPressed: BooleanLiteralType
    public let onTouchDown: () -> Void
    public let onTouchUp: () -> Void

    public var body: some View {
        GeometryReader { geo in
            let baseColor = Color(hex: pad.colorHex)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.white : baseColor)
                    .opacity(isPressed ? 0.95 : 0.85)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pad.index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isPressed ? .black.opacity(0.6) : .white.opacity(0.7))
                    Text(pad.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isPressed ? .black : .white)
                        .lineLimit(1)
                }
                .padding(8)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            // Multi-touch drag gesture capturing touch down and up simultaneously
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            onTouchDown()
                        }
                    }
                    .onEnded { _ in
                        onTouchUp()
                    }
            )
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 229, 57, 53)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
