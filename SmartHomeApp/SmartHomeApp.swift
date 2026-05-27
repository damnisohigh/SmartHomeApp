import SwiftUI
import FirebaseCore

@main
struct SmartHomeApp: App {
    @StateObject private var store: SmartHomeStore

    init() {
        FirebaseApp.configure()
        _store = StateObject(wrappedValue: SmartHomeStore(cloudService: FirebaseCloudService()))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
