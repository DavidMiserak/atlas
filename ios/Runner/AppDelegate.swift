import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.miserak.atlas/share",
      binaryMessenger: engineBridge.flutterEngine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareFile",
            let args = call.arguments as? [String: String],
            let filePath = args["path"],
            let subject = args["subject"] else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.shareFile(path: filePath, subject: subject, result: result)
    }
  }

  private func shareFile(path: String, subject: String, result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path)
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    activityVC.setValue(subject, forKey: "subject")

    guard let rootVC = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first?.windows
      .first?.rootViewController else {
      result(FlutterError(code: "NO_VC", message: "No root view controller", details: nil))
      return
    }

    rootVC.present(activityVC, animated: true) {
      result(nil)
    }
  }
}
