// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LoqOut';

  @override
  String get productMotto =>
      'If you focus you win, if you don\'t focus the world wins.';

  @override
  String get gateStarting => 'Starting LoqOut…';

  @override
  String get focusHowFeeling => 'How are you feeling right now?';

  @override
  String get focusAxisGuide => 'Energy (vertical) · Valence (horizontal)';

  @override
  String get navFocus => 'Focus';

  @override
  String get navInsights => 'Insights';

  @override
  String get navImpact => 'Impact';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Try again';

  @override
  String get refresh => 'Refresh';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String themeTooltip(String mode) {
    return 'Theme: $mode';
  }

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get themeSystem => 'System';

  @override
  String get languageTooltip => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get axisHighEnergy => 'High Energy';

  @override
  String get axisLowEnergy => 'Low Energy';

  @override
  String get axisPleasant => 'Pleasant';

  @override
  String get axisUnpleasant => 'Unpleasant';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodEnraged => 'Enraged';

  @override
  String get moodFurious => 'Furious';

  @override
  String get moodPanicked => 'Panicked';

  @override
  String get moodStressed => 'Stressed';

  @override
  String get moodFrustrated => 'Frustrated';

  @override
  String get moodAnnoyed => 'Annoyed';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodUneasy => 'Uneasy';

  @override
  String get moodDespair => 'Despair';

  @override
  String get moodDepressed => 'Depressed';

  @override
  String get moodExhausted => 'Exhausted';

  @override
  String get moodAlert => 'Alert';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodEcstatic => 'Ecstatic';

  @override
  String get moodThrilled => 'Thrilled';

  @override
  String get moodEnergized => 'Energized';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodProductive => 'Productive';

  @override
  String get moodFocused => 'Focused';

  @override
  String get moodContent => 'Content';

  @override
  String get moodAtEase => 'At ease';

  @override
  String get moodSerene => 'Serene';

  @override
  String get moodPeaceful => 'Peaceful';

  @override
  String get moodChill => 'Chill';

  @override
  String get checkInStressedFrustrated => 'Stressed / Frustrated';

  @override
  String get checkInDrainedDistracted => 'Drained / Distracted';

  @override
  String get checkInCalmFocused => 'Calm / Focused';

  @override
  String get checkInEnergizedProductive => 'Energized / Productive';

  @override
  String get energyHigh => 'High Energy';

  @override
  String get energyLow => 'Low Energy';

  @override
  String get valencePleasant => 'Pleasant';

  @override
  String get valenceUnpleasant => 'Unpleasant';

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusMoodSelectedHint =>
      'Mood selected. Tap NFC (or Scan QR) to start focus.';

  @override
  String get focusBlocklistUpdated =>
      'Blocklist updated. Tap NFC (or Scan QR) to start focus.';

  @override
  String get focusConfigureBlocklist =>
      'Configure your Default Blocklist before starting focus.';

  @override
  String get focusNfcActivate => 'NFC Tap — Activate Focus';

  @override
  String get focusScanQrBeta => 'Scan QR (Beta NFC)';

  @override
  String get focusQrAuthenticated => 'Beta QR authenticated — starting focus…';

  @override
  String focusNfcCheckFailed(String error) {
    return 'NFC check failed: $error — use Scan QR (Beta NFC) below.';
  }

  @override
  String get focusNfcUnavailable =>
      'NFC unavailable on this device — use Scan QR (Beta NFC).';

  @override
  String get focusNoAppsShielded => 'No apps shielded yet';

  @override
  String focusShieldCount(int count) {
    return '$count apps shielded';
  }

  @override
  String get focusEditBlocklist => 'Edit Blocklist';

  @override
  String focusEnergyValencePair(String energy, String valence) {
    return '$energy · $valence';
  }

  @override
  String get sessionLocked => 'Session locked';

  @override
  String get sessionActivating => 'Activating…';

  @override
  String sessionMoodLine(String mood, int intensity) {
    return 'Mood: $mood (Intensity: $intensity/5)';
  }

  @override
  String sessionAuthLine(String channel, String uid) {
    return 'Auth: $channel ($uid…)';
  }

  @override
  String get sessionAuthBetaQr => 'Beta QR';

  @override
  String get sessionAuthMockNfc => 'Mock NFC';

  @override
  String get sessionAuthNfc => 'NFC';

  @override
  String sessionShieldingApps(int count) {
    return 'Shielding $count apps';
  }

  @override
  String sessionBlockedAttempt(String package) {
    return 'Blocked attempt: $package';
  }

  @override
  String get sessionStartingWatchdog => 'Starting focus watchdog…';

  @override
  String get sessionActivateFailed =>
      'Could not activate focus yet. Check permissions and retry.';

  @override
  String get sessionRetryActivate => 'Retry Activate Focus';

  @override
  String sessionAppsLocked(int count) {
    return '$count apps locked';
  }

  @override
  String get sessionUnlockHint =>
      'Opening a locked app brings you back here.\nPrefer NFC / QR unlock. Emergency override burns Impact Credits.';

  @override
  String get sessionScanQrUnlock => 'Scan QR (Beta NFC) — Unlock';

  @override
  String get sessionEmergencyUnlock => 'Emergency Unlock (Burn Credits)';

  @override
  String sessionStartFailed(String error) {
    return 'Session start failed: $error';
  }

  @override
  String get qrScanTitle => 'Scan QR (Beta NFC)';

  @override
  String get qrDesktopHint =>
      'Camera QR is for Android beta devices. Enter the beta code below.';

  @override
  String get qrPermissionRequired =>
      'Camera permission is required to scan the beta QR.';

  @override
  String get qrCameraOpenFailed =>
      'Could not open the camera. Grant Camera Permission in settings and try again.';

  @override
  String get qrGrantPermission => 'Grant Camera Permission';

  @override
  String get qrOrEnterManually => 'Or enter the beta code manually:';

  @override
  String get qrBetaAuthCode => 'Beta auth code';

  @override
  String qrScanPrompt(String payload) {
    return 'Scan the LoqOut beta QR (\"$payload\")';
  }

  @override
  String qrUnrecognized(String got, String expected) {
    return 'Unrecognized QR. Got \"$got\" — need \"$expected\".';
  }

  @override
  String qrInvalidCode(String expected) {
    return 'Invalid code. Expected: $expected';
  }

  @override
  String get emergencyOverrideTitle => 'Emergency Override';

  @override
  String emergencyOverrideBody(int cost) {
    return 'Breaking this session will burn $cost Impact Credits. As a Corporate Pledge, LoqOut donates the financial equivalent to charity.';
  }

  @override
  String emergencyOverrideOrdinal(String ordinal) {
    return 'This is your $ordinal unlock this month.';
  }

  @override
  String get emergencyInsufficient =>
      'Insufficient Impact Credits for this override.';

  @override
  String get emergencyInsufficientHint =>
      'Insufficient Impact Credits. Unlock with NFC, or wait for next month\'s quota.';

  @override
  String get emergencyConfirmBurn => 'Burn credits & unlock';

  @override
  String get emergencyKeepLocked => 'Keep session locked';

  @override
  String get impactTitle => 'Impact';

  @override
  String get impactHowThisWorks => 'How this works';

  @override
  String get impactHowThisWorksBody =>
      'Emergency unlocking a session burns your Monthly Impact Quota. As a Corporate Pledge, LoqOut donates the financial equivalent of your burned quota to global charities. If you focus you win, if you don\'t focus the world wins.';

  @override
  String get impactMonthlyQuota => 'Monthly Impact Quota';

  @override
  String get impactCredits => 'Impact Credits';

  @override
  String get impactQuotaBlurb =>
      'Included with your focus subscription. Emergency overrides draw from this monthly quota.';

  @override
  String get impactPenaltyLadder => 'Penalty Ladder';

  @override
  String get impactPenaltyIntro =>
      'The cost of breaking your focus escalates with every unlock.';

  @override
  String impactPenaltyMonthStats(int used, int next) {
    return 'This month · $used used · next override $next credits';
  }

  @override
  String get impactPenaltyCapDisclaimer =>
      'Cost escalates up to a maximum of 40 credits per unlock.';

  @override
  String get impactCorporatePledge => 'Corporate Pledge';

  @override
  String get impactLifetimePledged => 'Lifetime Impact Credits pledged';

  @override
  String get impactPledgeBody =>
      '85% of burned Impact Credit value is pledged by LoqOut to verified global charities. Your focus discipline funds impact.';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsHeroTitle => 'Behavioral telemetry';

  @override
  String get insightsHeroSubtitle =>
      'See how mood, friction, and focus windows shape your attention.';

  @override
  String get insightsEmptyTitle => 'No sessions yet';

  @override
  String get insightsEmptyBody =>
      'Complete a focus session to unlock your attention analytics.';

  @override
  String insightsSessionsAnalyzed(int count, String time) {
    return '$count sessions analyzed · updated $time';
  }

  @override
  String get insightsExportBeta => 'Export Beta Telemetry';

  @override
  String get insightsExporting => 'Exporting…';

  @override
  String get insightsMoodDistractionTitle => 'Mood vs. distraction';

  @override
  String get insightsMoodDistractionSubtitle =>
      'Where attention slips — and what it costs you';

  @override
  String insightsVulnerability(String mood, int count) {
    return 'You are most vulnerable to distractions when feeling $mood. We blocked $count urge(s) to open apps while you were in this state.';
  }

  @override
  String get insightsFrictionTitle => 'Friction score';

  @override
  String get insightsBeforeAfterTitle => 'Before & after';

  @override
  String get insightsBeforeAfterSubtitle =>
      'How focus sessions reshape how you feel';

  @override
  String get insightsBeforeAfterEmpty =>
      'Complete a post-session check-in to unlock your mood story.';

  @override
  String insightsShiftFromTo(String start, String end) {
    return 'You mostly shift from $start  →  $end.';
  }

  @override
  String get insightsPeakTitle => 'Peak focus window';

  @override
  String get insightsMoodImproves => 'Focusing improves your mood.';

  @override
  String get insightsMoodSteadies => 'Focusing steadies your emotional state.';

  @override
  String get insightsMoodDeclines =>
      'Sessions leave you more drained — protect recovery.';

  @override
  String get postSessionTitle => 'Quick check-in';

  @override
  String get postSessionPrompt => 'How do you feel after this focus session?';

  @override
  String get postSessionSkip => 'Skip';

  @override
  String get blocklistTitle => 'Edit Blocklist';

  @override
  String get blocklistSave => 'Save Blocklist';

  @override
  String get blocklistSaving => 'Saving…';

  @override
  String get blocklistEmptyApps => 'No launchable apps found.';

  @override
  String get blocklistSelectOne =>
      'Select at least one app for your Default Blocklist.';

  @override
  String blocklistSaved(int count) {
    return 'Default Blocklist saved — $count apps.';
  }

  @override
  String blocklistLoadFailed(String error) {
    return 'Could not load apps: $error';
  }

  @override
  String blocklistSaveFailed(String error) {
    return 'Could not save blocklist: $error';
  }

  @override
  String get blocklistOpenUsageSettings => 'Open Usage Access Settings';

  @override
  String get permissionsTitle => 'Permissions required';

  @override
  String get permissionsBody =>
      'LoqOut needs a few system permissions to enforce focus sessions. Grant each one below.';

  @override
  String get permissionsGrantedRecheck => 'I granted them — check again';

  @override
  String get permissionsGrant => 'Grant permission';

  @override
  String get daypartMorning => 'Morning';

  @override
  String get daypartAfternoon => 'Afternoon';

  @override
  String get daypartEvening => 'Evening';

  @override
  String get daypartNight => 'Night';

  @override
  String get iosShieldTitle => 'Shield';

  @override
  String get iosShieldBody =>
      'Choose the apps, categories, and websites LoqOut locks during a focus session. Apple keeps those names on the device; LoqOut only receives the shield tokens.';

  @override
  String get iosShieldAuthorize => 'Allow Screen Time access';

  @override
  String get iosShieldOpenPicker => 'Choose what to shield';

  @override
  String get iosShieldDenied =>
      'Screen Time access is off. Enable it for LoqOut in Settings.';

  @override
  String get iosShieldOpenSettings => 'Open Settings';

  @override
  String get iosShieldSelectOne =>
      'Choose at least one app, category, or website to shield.';

  @override
  String get iosShieldSaved => 'Shield updated.';

  @override
  String iosShieldSummary(int apps, int categories, int sites) {
    return '$apps apps · $categories categories · $sites websites';
  }

  @override
  String iosShieldApps(int count) {
    return '$count apps';
  }

  @override
  String iosShieldCategories(int count) {
    return '$count categories';
  }

  @override
  String iosShieldSites(int count) {
    return '$count websites';
  }
}
