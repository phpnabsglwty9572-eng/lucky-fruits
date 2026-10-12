import SwiftUI
import UIKit

@main
struct LuckyFruitsApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PadFullScreenHook())
        }
        .defaultSize(width: 834, height: 1194)
    }
}

private struct PadFullScreenHook: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PadFullScreenController {
        PadFullScreenController()
    }

    func updateUIViewController(_ uiViewController: PadFullScreenController, context: Context) {
        uiViewController.fillPadDisplay()
    }
}

private final class PadFullScreenController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fillPadDisplay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fillPadDisplay()
    }

    func fillPadDisplay() {
        guard UIDevice.current.userInterfaceIdiom == .pad,
              let scene = view.window?.windowScene else { return }
        scene.sizeRestrictions?.minimumSize = CGSize(width: 320, height: 320)
        scene.sizeRestrictions?.maximumSize = CGSize(width: 10000, height: 10000)
        scene.sizeRestrictions?.allowsFullScreen = true
    }
}
