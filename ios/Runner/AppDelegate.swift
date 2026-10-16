import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private var familyControlsBridge: FamilyControlsBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The scene delegate creates the Flutter view after this returns.
    // Plugins must register through this callback, not against a window
    // that does not exist yet.
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    guard familyControlsBridge == nil,
          let registrar = registry.registrar(forPlugin: "LoqOutFamilyControls") else {
      return
    }
    familyControlsBridge = FamilyControlsBridge.register(messenger: registrar.messenger())
  }
}
