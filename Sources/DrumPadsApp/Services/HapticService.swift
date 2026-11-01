import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class HapticService: @unchecked Sendable {
    public static let shared = HapticService()

#if canImport(UIKit)
    private var generator: UIImpactFeedbackGenerator?

    public init() {
        DispatchQueue.main.async {
            self.generator = UIImpactFeedbackGenerator(style: .medium)
            self.generator?.prepare()
        }
    }

    public func playPadHaptic() {
        DispatchQueue.main.async {
            self.generator?.impactOccurred()
            self.generator?.prepare()
        }
    }
#else
    public init() {}
    public func playPadHaptic() {}
#endif
}
