import SwiftUI

@main
public struct DrumPadsApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            DrumPadsView()
                .preferredColorScheme(.dark)
        }
    }
}
