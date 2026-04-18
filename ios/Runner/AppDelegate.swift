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

    // Opt-in on-device AI recap bridge. iOS implementation is intentionally
    // stubbed — always reports "unavailable" — until we can test against
    // Apple Foundation Models on a physical Apple Intelligence device.
    // The Android side (Gemini Nano via ML Kit GenAI) is the live path for
    // now; the toggle in Settings is disabled on iOS because of this stub.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.retraq.app/ondevice_ai",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "checkStatus":
          // TODO(ios-ai): wire Apple Foundation Models (`LanguageModelSession`)
          // once an Apple Intelligence device is available for testing.
          result("unavailable")
        case "startDownload":
          // iOS Apple FM ships with the OS — nothing to download. No-op
          // until we wire real inference.
          result(nil)
        case "summarize":
          result(FlutterError(
            code: "NOT_AVAILABLE",
            message: "On-device AI recap is not implemented on iOS yet",
            details: nil
          ))
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      // Mirror the Android EventChannel so the Dart-side broadcast stream
      // always finds a handler. Emits a single "unavailable" event on
      // subscribe; never changes.
      let events = FlutterEventChannel(
        name: "com.retraq.app/ondevice_ai/events",
        binaryMessenger: controller.binaryMessenger
      )
      events.setStreamHandler(_OnDeviceAiEventStub())
    }

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

/// Event-channel stub mirroring the Android implementation's shape —
/// emits a single `{status: "unavailable"}` event on subscribe and then
/// stays silent. Replace when Apple Foundation Models support lands.
private class _OnDeviceAiEventStub: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    events(["status": "unavailable"])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
