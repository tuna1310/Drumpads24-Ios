import SwiftUI

public struct DrumPadsView: View {
    @State private var store = DrumPadsStore.shared

    public init() {}

    public var body: some View {
        MainAppContainer()
    }
}

public struct PadCellView: View {
    public let pad: Pad
    public let isPressed: Bool
    public let onTouchDown: () -> Void
    public let onTouchUp: () -> Void

    public init(pad: Pad, isPressed: Bool, onTouchDown: @escaping () -> Void, onTouchUp: @escaping () -> Void) {
        self.pad = pad
        self.isPressed = isPressed
        self.onTouchDown = onTouchDown
        self.onTouchUp = onTouchUp
    }

    public var body: some View {
        GeometryReader { _ in
            let baseColor = Color(hex: pad.colorHex)
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.white : baseColor)
                    .opacity(isPressed ? 0.98 : 0.88)

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
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { onTouchDown() }
                    }
                    .onEnded { _ in
                        onTouchUp()
                    }
            )
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}
