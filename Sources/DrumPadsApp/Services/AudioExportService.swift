import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit

public enum AudioExportService {
    @MainActor
    public static func share(fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)
    }
}
#endif

