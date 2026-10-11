import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Shared by the Runner and the Device Activity Monitor extension.
///
/// Tokens from FamilyActivityPicker are opaque. They live in the App Group so
/// the extension can re-apply the shield without Flutter running.
enum LoqOutShieldStore {
  static let appGroupId = "group.com.tugrul.loqout"
  static let activityName = DeviceActivityName("loqout.focus")
  static let storeName = ManagedSettingsStore.Name("loqout.focus")

  private static let selectionKey = "loqout.family.selection"
  private static let sessionActiveKey = "loqout.family.sessionActive"

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

  static func requestAuthorization() async throws {
    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
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
    guard authorizationStatusRaw() == "approved" else {
      throw LoqOutShieldError.authorizationRequired
    }
    guard let selection = loadSelection(), hasTargets(selection) else {
      throw LoqOutShieldError.emptySelection
    }
    let store = try requireDefaults()
    store.set(true, forKey: sessionActiveKey)
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

  var errorDescription: String? {
    switch self {
    case .appGroupUnavailable:
      return "App Group \(LoqOutShieldStore.appGroupId) is not available. Enable it on the App ID before signing."
    case .authorizationRequired:
      return "Family Controls authorization is required before a focus session can lock apps."
    case .emptySelection:
      return "Choose at least one app, category, or website to shield."
    }
  }
}
