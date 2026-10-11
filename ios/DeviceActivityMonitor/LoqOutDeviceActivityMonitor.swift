import DeviceActivity
import Foundation

/// Re-asserts the LoqOut shield while a focus session is active.
///
/// The extension does not start a session by itself. The Runner sets the
/// session flag only after the user authenticates with NFC or QR.
final class LoqOutDeviceActivityMonitor: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    guard activity == LoqOutShieldStore.activityName else { return }
    LoqOutShieldStore.reapplyIfSessionActive()
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    guard activity == LoqOutShieldStore.activityName else { return }
    guard LoqOutShieldStore.isSessionActive else { return }
    do {
      try LoqOutShieldStore.rearmMonitor()
    } catch {
      // The named ManagedSettings store applied by the app stays in place
      // until the user taps out and the Runner calls endSession.
    }
  }
}
