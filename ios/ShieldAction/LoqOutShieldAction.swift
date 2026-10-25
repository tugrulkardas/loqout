import ManagedSettings

/// Counts a tap on the shield button. Opening a locked app does not come here.
final class LoqOutShieldAction: ShieldActionDelegate {
  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    note(action)
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    note(action)
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    note(action)
    completionHandler(.close)
  }

  private func note(_ action: ShieldAction) {
    if action == .primaryButtonPressed {
      LoqOutShieldStore.recordImpulse()
    }
  }
}
