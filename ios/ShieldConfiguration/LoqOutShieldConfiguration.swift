import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Replaces the system "Restricted" cover with the same message Android shows
/// when a blocked app is opened.
final class LoqOutShieldConfiguration: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    shield(named: application.localizedDisplayName)
  }

  override func configuration(
    shielding application: Application,
    in category: ActivityCategory
  ) -> ShieldConfiguration {
    shield(named: application.localizedDisplayName)
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    shield(named: webDomain.domain)
  }

  override func configuration(
    shielding webDomain: WebDomain,
    in category: ActivityCategory
  ) -> ShieldConfiguration {
    shield(named: webDomain.domain)
  }

  private func shield(named name: String?) -> ShieldConfiguration {
    let subject = (name?.isEmpty == false) ? name! : "This app"
    return ShieldConfiguration(
      backgroundBlurStyle: .systemThickMaterialDark,
      backgroundColor: UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1),
      icon: UIImage(systemName: "lock.fill"),
      title: ShieldConfiguration.Label(text: "Return to LoqOut", color: .white),
      subtitle: ShieldConfiguration.Label(
        text: "\(subject) is locked.\nReturn to LoqOut to continue focusing.",
        color: UIColor(white: 0.78, alpha: 1)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .white),
      primaryButtonBackgroundColor: UIColor(red: 0.18, green: 0.42, blue: 0.95, alpha: 1)
    )
  }
}
