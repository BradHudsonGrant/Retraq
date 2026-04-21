import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var blurEffectView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    guard let window = self.window else { return }
    // Use systemUltraThinMaterial for a strong privacy blur that adapts to
    // light/dark mode automatically and persists through background state.
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.tag = 999
    window.addSubview(blurView)
    self.blurEffectView = blurView
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    if let blurView = self.blurEffectView {
      blurView.removeFromSuperview()
      self.blurEffectView = nil
    }
    // Fallback: remove by tag in case the property reference was lost
    self.window?.viewWithTag(999)?.removeFromSuperview()
  }
}
