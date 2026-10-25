import DeviceActivity
import FamilyControls
import Foundation
import LocalAuthentication
import ManagedSettings
import os

/// Shared by the Runner, the Device Activity Monitor, and Shield Action.
///
/// Tokens from FamilyActivityPicker are opaque. They live in the App Group so
/// the extension can re-apply the shield without Flutter running.
enum LoqOutShieldStore {
  static let appGroupId = "group.com.tugrul.loqout"
  static let activityName = DeviceActivityName("loqout.focus")
  static let storeName = ManagedSettingsStore.Name("loqout.focus")

  private static let selectionKey = "loqout.family.selection"
  private static let sessionActiveKey = "loqout.family.sessionActive"
  /// Shield-button taps for the open session. Not app launches.
  private static let impulseCountKey = "loqout.shield.impulseCount"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  static func requireDefaults() throws -> UserDefaults {
    guard let defaults else {
      throw LoqOutShieldError.appGroupUnavailable
    }
    return defaults
  }

  static var isSessionActive: Bool {
    defaults?.bool(forKey: sessionActiveKey) ?? false
  }

  /// Taps on the shield button during the open session. Zero after the next
  /// session starts. This is not a count of every locked-app launch.
  static var impulseCount: Int {
    defaults?.integer(forKey: impulseCountKey) ?? 0
  }

  static func recordImpulse() {
    guard isSessionActive, let store = defaults else { return }
    store.set(store.integer(forKey: impulseCountKey) + 1, forKey: impulseCountKey)
    store.synchronize()
  }

  static func resetImpulseCount() {
    defaults?.set(0, forKey: impulseCountKey)
    defaults?.synchronize()
  }

  static func authorizationStatusRaw() -> String {
    switch AuthorizationCenter.shared.authorizationStatus {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .approved:
      return "approved"
    @unknown default:
      return "unknown"
    }
  }

  /// `available`, `missing`, or `unknown`. Does not prompt and does not call
  /// Family Controls. A missing passcode makes Screen Time authorization fail.
  static func devicePasscodeStatus() -> String {
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
      return "available"
    }
    if let error,
       error.domain == LAError.errorDomain,
       error.code == LAError.passcodeNotSet.rawValue {
      return "missing"
    }
    return "unknown"
  }

  static func requestAuthorization() async throws {
    if devicePasscodeStatus() == "missing" {
      throw LoqOutShieldError.passcodeRequired
    }
    do {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    } catch {
      throw LoqOutShieldError.classified(authorizationFailureCode(for: error))
    }
  }

  /// Stable codes: passcodeRequired, denied, restricted, network, unknown.
  static func authorizationFailureCode(for error: Error) -> String {
    let ns = error as NSError
    let text = [
      ns.localizedDescription,
      ns.localizedFailureReason ?? "",
    ].joined(separator: " ").lowercased()
    if text.contains("passcode") {
      return "passcodeRequired"
    }
    if text.contains("restrict") {
      return "restricted"
    }
    if ns.domain == NSURLErrorDomain
      || text.contains("network")
      || text.contains("internet")
      || text.contains("offline") {
      return "network"
    }
    if authorizationStatusRaw() == "denied"
      || text.contains("denied")
      || text.contains("not authorized") {
      return "denied"
    }
    return "unknown"
  }

  /// Local counter only. Nothing here is uploaded.
  static func logAuthFailure(_ code: String) {
    let allowed = ["passcodeRequired", "denied", "restricted", "network", "unknown", "authorizationRequired"]
    let stable = allowed.contains(code) ? code : "unknown"
    let key = "loqout.authFailure.\(stable)"
    let count = UserDefaults.standard.integer(forKey: key) + 1
    UserDefaults.standard.set(count, forKey: key)
    Logger(subsystem: "com.loqout.app", category: "FamilyControls")
      .error("family_controls_auth_failure code=\(stable, privacy: .public) count=\(count)")
  }

  static func save(selection: FamilyActivitySelection) throws {
    let store = try requireDefaults()
    let data = try PropertyListEncoder().encode(selection)
    store.set(data, forKey: selectionKey)
    store.synchronize()
  }

  static func loadSelection() -> FamilyActivitySelection? {
    guard let data = defaults?.data(forKey: selectionKey) else { return nil }
    return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
  }

  static func hasTargets(_ selection: FamilyActivitySelection) -> Bool {
    !selection.applicationTokens.isEmpty
      || !selection.categoryTokens.isEmpty
      || !selection.webDomainTokens.isEmpty
  }

  static func summaryMap() -> [String: Any] {
    let selection = loadSelection() ?? FamilyActivitySelection()
    return [
      "authorizationStatus": authorizationStatusRaw(),
      "applicationCount": selection.applicationTokens.count,
      "categoryCount": selection.categoryTokens.count,
      "webDomainCount": selection.webDomainTokens.count,
    ]
  }

  /// NFC/QR session start. Applies the shield immediately, then arms the
  /// monitor so the extension keeps it in place while the app is suspended.
  static func beginSession() throws {
    if devicePasscodeStatus() == "missing" {
      throw LoqOutShieldError.passcodeRequired
    }
    guard authorizationStatusRaw() == "approved" else {
      throw LoqOutShieldError.authorizationRequired
    }
    guard let selection = loadSelection(), hasTargets(selection) else {
      throw LoqOutShieldError.emptySelection
    }
    let store = try requireDefaults()
    store.set(true, forKey: sessionActiveKey)
    store.set(0, forKey: impulseCountKey)
    store.synchronize()
    apply(selection)
    do {
      try armMonitor()
    } catch {
      store.set(false, forKey: sessionActiveKey)
      store.synchronize()
      ManagedSettingsStore(named: storeName).clearAllSettings()
      throw error
    }
  }

  /// Physical unlock. Clears the session flag before stopping the monitor so
  /// `intervalDidEnd` does not arm another window.
  static func endSession() {
    defaults?.set(false, forKey: sessionActiveKey)
    defaults?.synchronize()
    DeviceActivityCenter().stopMonitoring([activityName])
    ManagedSettingsStore(named: storeName).clearAllSettings()
  }

  static func reapplyIfSessionActive() {
    guard isSessionActive, let selection = loadSelection(), hasTargets(selection) else {
      return
    }
    apply(selection)
  }

  /// Called from the extension when an interval ends but the user has not tapped out.
  static func rearmMonitor() throws {
    guard isSessionActive else { return }
    try DeviceActivityCenter().startMonitoring(activityName, during: makeSchedule())
  }

  private static func apply(_ selection: FamilyActivitySelection) {
    let store = ManagedSettingsStore(named: storeName)
    store.shield.applications = selection.applicationTokens.isEmpty
      ? nil
      : selection.applicationTokens
    store.shield.webDomains = selection.webDomainTokens.isEmpty
      ? nil
      : selection.webDomainTokens
    if selection.categoryTokens.isEmpty {
      store.shield.applicationCategories = nil
    } else {
      store.shield.applicationCategories = .specific(
        selection.categoryTokens,
        except: Set<ApplicationToken>()
      )
    }
    store.shield.webDomainCategories = nil
  }

  private static func armMonitor() throws {
    let center = DeviceActivityCenter()
    center.stopMonitoring([activityName])
    try center.startMonitoring(activityName, during: makeSchedule())
  }

  /// DeviceActivitySchedule rejects windows shorter than 15 minutes.
  /// A focus session ends on NFC/QR, so the window is a long cover that the
  /// extension renews until [endSession] clears the flag.
  private static func makeSchedule(now: Date = Date()) -> DeviceActivitySchedule {
    let calendar = Calendar.current
    let startDate = calendar.date(byAdding: .minute, value: -1, to: now) ?? now
    let endDate = calendar.date(byAdding: .hour, value: 8, to: now) ?? now.addingTimeInterval(8 * 3600)
    return DeviceActivitySchedule(
      intervalStart: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate),
      intervalEnd: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate),
      repeats: false
    )
  }
}

enum LoqOutShieldError: LocalizedError {
  case appGroupUnavailable
  case authorizationRequired
  case emptySelection
  case passcodeRequired
  case classified(String)

  /// Code the Flutter UI maps to a sentence. Never the raw Apple text.
  var failureCode: String {
    switch self {
    case .passcodeRequired:
      return "passcodeRequired"
    case .authorizationRequired:
      return "authorizationRequired"
    case .classified(let code):
      return code
    case .appGroupUnavailable, .emptySelection:
      return "unknown"
    }
  }

  var errorDescription: String? {
    switch self {
    case .appGroupUnavailable:
      return "App Group \(LoqOutShieldStore.appGroupId) is not available. Enable it on the App ID before signing."
    case .authorizationRequired:
      return "authorizationRequired"
    case .emptySelection:
      return "Choose at least one app, category, or website to shield."
    case .passcodeRequired:
      return "passcodeRequired"
    case .classified(let code):
      return code
    }
  }
}
