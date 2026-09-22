import SwiftUI

@main
struct LuckyFruitsApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
