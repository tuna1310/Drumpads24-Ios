import SwiftUI

public struct SettingsView: View {
    @Bindable public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        SettingsScreen(store: store)
    }
}
