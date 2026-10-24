import FamilyControls
import Flutter
import SwiftUI
import UIKit

/// Flutter entry for Family Controls. The shield is armed only from
/// `startShield`, which the session screen calls after NFC or QR auth.
final class FamilyControlsBridge: NSObject, UIAdaptivePresentationControllerDelegate {
  static let channelName = "com.tugrul.tapfocus/family_controls"

  private var channel: FlutterMethodChannel?
  private var pickerResult: FlutterResult?
  private var pickerHost: UIViewController?

  static func register(messenger: FlutterBinaryMessenger) -> FamilyControlsBridge {
    let bridge = FamilyControlsBridge()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    bridge.channel = channel
    channel.setMethodCallHandler { [weak bridge] call, result in
      bridge?.handle(call, result: result)
    }
    return bridge
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "authorizationStatus":
      result(LoqOutShieldStore.authorizationStatusRaw())
    case "selectionSummary":
      result(LoqOutShieldStore.summaryMap())
    case "devicePasscodeStatus":
      result(LoqOutShieldStore.devicePasscodeStatus())
    case "noteAuthFailure":
      let code = call.arguments as? String ?? "unknown"
      LoqOutShieldStore.logAuthFailure(code)
      result(nil)
    case "requestAuthorization":
      Task { @MainActor in
        do {
          try await LoqOutShieldStore.requestAuthorization()
          result(LoqOutShieldStore.summaryMap())
        } catch {
          result(self.authFailure(error))
        }
      }
    case "presentActivityPicker":
      Task { @MainActor in
        self.presentPicker(result: result)
      }
    case "startShield":
      do {
        try LoqOutShieldStore.beginSession()
        result(LoqOutShieldStore.summaryMap())
      } catch {
        result(authFailure(error))
      }
    case "stopShield":
      LoqOutShieldStore.endSession()
      result(nil)
    case "isSessionActive":
      result(LoqOutShieldStore.isSessionActive)
    case "restoreShield":
      LoqOutShieldStore.reapplyIfSessionActive()
      if LoqOutShieldStore.isSessionActive {
        try? LoqOutShieldStore.rearmMonitor()
      }
      result(LoqOutShieldStore.isSessionActive)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @MainActor
  private func presentPicker(result: @escaping FlutterResult) {
    guard pickerResult == nil else {
      result(
        FlutterError(
          code: "pickerBusy",
          message: "The app picker is already open.",
          details: nil
        )
      )
      return
    }
    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "pickerUnavailable",
          message: "Could not present the Family Activity picker.",
          details: nil
        )
      )
      return
    }
    pickerResult = result
    let initial = LoqOutShieldStore.loadSelection() ?? FamilyActivitySelection()
    let host = UIHostingController(
      rootView: LoqOutActivityPicker(initial: initial, onFinish: { [weak self] selection in
        self?.finishPicker(selection)
      })
    )
    host.modalPresentationStyle = .formSheet
    host.presentationController?.delegate = self
    pickerHost = host
    presenter.present(host, animated: true)
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finishPicker(nil)
  }

  private func finishPicker(_ selection: FamilyActivitySelection?) {
    guard let callback = pickerResult else { return }
    pickerResult = nil
    let host = pickerHost
    pickerHost = nil
    let complete = {
    if let selection {
      do {
        try LoqOutShieldStore.save(selection: selection)
        callback(LoqOutShieldStore.summaryMap())
      } catch {
        callback(self.failure("saveSelectionFailed", error))
      }
    } else {
      var summary = LoqOutShieldStore.summaryMap()
      summary["cancelled"] = true
      callback(summary)
    }
    }
    if host?.presentingViewController != nil {
      host?.dismiss(animated: true, completion: complete)
    } else {
      complete()
    }
  }

  private func failure(_ code: String, _ error: Error) -> FlutterError {
    FlutterError(code: code, message: error.localizedDescription, details: nil)
  }

  /// Stable code only. The raw Family Controls sentence stays out of the UI.
  private func authFailure(_ error: Error) -> FlutterError {
    let code = (error as? LoqOutShieldError)?.failureCode ?? "unknown"
    return FlutterError(code: code, message: code, details: nil)
  }

  @MainActor
  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let root = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
    var current = root
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }
}

private struct LoqOutActivityPicker: View {
  @State private var selection: FamilyActivitySelection
  let onFinish: (FamilyActivitySelection?) -> Void

  init(initial: FamilyActivitySelection, onFinish: @escaping (FamilyActivitySelection?) -> Void) {
    _selection = State(initialValue: initial)
    self.onFinish = onFinish
  }

  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("LoqOut")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onFinish(nil) }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { onFinish(selection) }
          }
        }
    }
  }
}
