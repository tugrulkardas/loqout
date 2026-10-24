import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LoqOut'**
  String get appTitle;

  /// No description provided for @productMotto.
  ///
  /// In en, this message translates to:
  /// **'If you focus you win, if you don\'t focus the world wins.'**
  String get productMotto;

  /// No description provided for @gateStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting LoqOut…'**
  String get gateStarting;

  /// No description provided for @focusHowFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get focusHowFeeling;

  /// No description provided for @focusAxisGuide.
  ///
  /// In en, this message translates to:
  /// **'Energy (vertical) · Valence (horizontal)'**
  String get focusAxisGuide;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get navImpact;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @themeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Theme: {mode}'**
  String themeTooltip(String mode);

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @axisHighEnergy.
  ///
  /// In en, this message translates to:
  /// **'High Energy'**
  String get axisHighEnergy;

  /// No description provided for @axisLowEnergy.
  ///
  /// In en, this message translates to:
  /// **'Low Energy'**
  String get axisLowEnergy;

  /// No description provided for @axisPleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get axisPleasant;

  /// No description provided for @axisUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Unpleasant'**
  String get axisUnpleasant;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodEnraged.
  ///
  /// In en, this message translates to:
  /// **'Enraged'**
  String get moodEnraged;

  /// No description provided for @moodFurious.
  ///
  /// In en, this message translates to:
  /// **'Furious'**
  String get moodFurious;

  /// No description provided for @moodPanicked.
  ///
  /// In en, this message translates to:
  /// **'Panicked'**
  String get moodPanicked;

  /// No description provided for @moodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodStressed;

  /// No description provided for @moodFrustrated.
  ///
  /// In en, this message translates to:
  /// **'Frustrated'**
  String get moodFrustrated;

  /// No description provided for @moodAnnoyed.
  ///
  /// In en, this message translates to:
  /// **'Annoyed'**
  String get moodAnnoyed;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodAnxious;

  /// No description provided for @moodUneasy.
  ///
  /// In en, this message translates to:
  /// **'Uneasy'**
  String get moodUneasy;

  /// No description provided for @moodDespair.
  ///
  /// In en, this message translates to:
  /// **'Despair'**
  String get moodDespair;

  /// No description provided for @moodDepressed.
  ///
  /// In en, this message translates to:
  /// **'Depressed'**
  String get moodDepressed;

  /// No description provided for @moodExhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get moodExhausted;

  /// No description provided for @moodAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get moodAlert;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodEcstatic.
  ///
  /// In en, this message translates to:
  /// **'Ecstatic'**
  String get moodEcstatic;

  /// No description provided for @moodThrilled.
  ///
  /// In en, this message translates to:
  /// **'Thrilled'**
  String get moodThrilled;

  /// No description provided for @moodEnergized.
  ///
  /// In en, this message translates to:
  /// **'Energized'**
  String get moodEnergized;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodProductive.
  ///
  /// In en, this message translates to:
  /// **'Productive'**
  String get moodProductive;

  /// No description provided for @moodFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get moodFocused;

  /// No description provided for @moodContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get moodContent;

  /// No description provided for @moodAtEase.
  ///
  /// In en, this message translates to:
  /// **'At ease'**
  String get moodAtEase;

  /// No description provided for @moodSerene.
  ///
  /// In en, this message translates to:
  /// **'Serene'**
  String get moodSerene;

  /// No description provided for @moodPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get moodPeaceful;

  /// No description provided for @moodChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get moodChill;

  /// No description provided for @checkInStressedFrustrated.
  ///
  /// In en, this message translates to:
  /// **'Stressed / Frustrated'**
  String get checkInStressedFrustrated;

  /// No description provided for @checkInDrainedDistracted.
  ///
  /// In en, this message translates to:
  /// **'Drained / Distracted'**
  String get checkInDrainedDistracted;

  /// No description provided for @checkInCalmFocused.
  ///
  /// In en, this message translates to:
  /// **'Calm / Focused'**
  String get checkInCalmFocused;

  /// No description provided for @checkInEnergizedProductive.
  ///
  /// In en, this message translates to:
  /// **'Energized / Productive'**
  String get checkInEnergizedProductive;

  /// No description provided for @energyHigh.
  ///
  /// In en, this message translates to:
  /// **'High Energy'**
  String get energyHigh;

  /// No description provided for @energyLow.
  ///
  /// In en, this message translates to:
  /// **'Low Energy'**
  String get energyLow;

  /// No description provided for @valencePleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get valencePleasant;

  /// No description provided for @valenceUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Unpleasant'**
  String get valenceUnpleasant;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusMoodSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Mood selected. Tap NFC (or Scan QR) to start focus.'**
  String get focusMoodSelectedHint;

  /// No description provided for @focusBlocklistUpdated.
  ///
  /// In en, this message translates to:
  /// **'Blocklist updated. Tap NFC (or Scan QR) to start focus.'**
  String get focusBlocklistUpdated;

  /// No description provided for @focusConfigureBlocklist.
  ///
  /// In en, this message translates to:
  /// **'Configure your Default Blocklist before starting focus.'**
  String get focusConfigureBlocklist;

  /// No description provided for @focusNfcActivate.
  ///
  /// In en, this message translates to:
  /// **'NFC Tap — Activate Focus'**
  String get focusNfcActivate;

  /// No description provided for @focusScanQrBeta.
  ///
  /// In en, this message translates to:
  /// **'Scan QR (Beta NFC)'**
  String get focusScanQrBeta;

  /// No description provided for @focusQrAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Beta QR authenticated — starting focus…'**
  String get focusQrAuthenticated;

  /// No description provided for @focusNfcCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'NFC check failed: {error} — use Scan QR (Beta NFC) below.'**
  String focusNfcCheckFailed(String error);

  /// No description provided for @focusNfcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'NFC unavailable on this device — use Scan QR (Beta NFC).'**
  String get focusNfcUnavailable;

  /// No description provided for @focusNoAppsShielded.
  ///
  /// In en, this message translates to:
  /// **'No apps shielded yet'**
  String get focusNoAppsShielded;

  /// No description provided for @focusShieldCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps shielded'**
  String focusShieldCount(int count);

  /// No description provided for @focusEditBlocklist.
  ///
  /// In en, this message translates to:
  /// **'Edit Blocklist'**
  String get focusEditBlocklist;

  /// No description provided for @focusEnergyValencePair.
  ///
  /// In en, this message translates to:
  /// **'{energy} · {valence}'**
  String focusEnergyValencePair(String energy, String valence);

  /// No description provided for @sessionLocked.
  ///
  /// In en, this message translates to:
  /// **'Session locked'**
  String get sessionLocked;

  /// No description provided for @sessionActivating.
  ///
  /// In en, this message translates to:
  /// **'Activating…'**
  String get sessionActivating;

  /// No description provided for @sessionMoodLine.
  ///
  /// In en, this message translates to:
  /// **'Mood: {mood} (Intensity: {intensity}/5)'**
  String sessionMoodLine(String mood, int intensity);

  /// No description provided for @sessionAuthLine.
  ///
  /// In en, this message translates to:
  /// **'Auth: {channel} ({uid}…)'**
  String sessionAuthLine(String channel, String uid);

  /// No description provided for @sessionAuthBetaQr.
  ///
  /// In en, this message translates to:
  /// **'Beta QR'**
  String get sessionAuthBetaQr;

  /// No description provided for @sessionAuthMockNfc.
  ///
  /// In en, this message translates to:
  /// **'Mock NFC'**
  String get sessionAuthMockNfc;

  /// No description provided for @sessionAuthNfc.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get sessionAuthNfc;

  /// No description provided for @sessionShieldingApps.
  ///
  /// In en, this message translates to:
  /// **'Shielding {count} apps'**
  String sessionShieldingApps(int count);

  /// No description provided for @sessionBlockedAttempt.
  ///
  /// In en, this message translates to:
  /// **'Blocked attempt: {package}'**
  String sessionBlockedAttempt(String package);

  /// No description provided for @sessionStartingWatchdog.
  ///
  /// In en, this message translates to:
  /// **'Starting focus watchdog…'**
  String get sessionStartingWatchdog;

  /// No description provided for @sessionActivateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not activate focus yet. Check permissions and retry.'**
  String get sessionActivateFailed;

  /// No description provided for @sessionRetryActivate.
  ///
  /// In en, this message translates to:
  /// **'Retry Activate Focus'**
  String get sessionRetryActivate;

  /// No description provided for @sessionAppsLocked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app locked} other{{count} apps locked}}'**
  String sessionAppsLocked(int count);

  /// No description provided for @sessionCategoriesLocked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 category locked} other{{count} categories locked}}'**
  String sessionCategoriesLocked(int count);

  /// No description provided for @sessionWebsitesLocked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 website locked} other{{count} websites locked}}'**
  String sessionWebsitesLocked(int count);

  /// No description provided for @lockThisSession.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get lockThisSession;

  /// No description provided for @lockFocusTimeToday.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focus time today'**
  String lockFocusTimeToday(int minutes);

  /// No description provided for @lockFocusTimeWeek.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min this week'**
  String lockFocusTimeWeek(int minutes);

  /// No description provided for @lockStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String lockStreakDays(int count);

  /// No description provided for @lockNoStreak.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get lockNoStreak;

  /// No description provided for @lockInsightEmpty.
  ///
  /// In en, this message translates to:
  /// **'This session starts your record.'**
  String get lockInsightEmpty;

  /// No description provided for @lockHoldToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Hold to unlock'**
  String get lockHoldToUnlock;

  /// No description provided for @lockStreakKeeps.
  ///
  /// In en, this message translates to:
  /// **'Ending now keeps today on your streak.'**
  String get lockStreakKeeps;

  /// No description provided for @lockStreakMiss.
  ///
  /// In en, this message translates to:
  /// **'Ending now does not count today toward your streak.'**
  String get lockStreakMiss;

  /// No description provided for @lockStreakAlready.
  ///
  /// In en, this message translates to:
  /// **'Today already counts toward your streak.'**
  String get lockStreakAlready;

  /// No description provided for @insightsFrictionEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate only. About 15 minutes per blocked attempt. This is not measured screen time.'**
  String get insightsFrictionEstimate;

  /// No description provided for @insightsEstimatedAttention.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get insightsEstimatedAttention;

  /// No description provided for @sessionUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Opening a locked app brings you back here.\nPrefer NFC / QR unlock. Emergency override burns Impact Credits.'**
  String get sessionUnlockHint;

  /// No description provided for @sessionScanQrUnlock.
  ///
  /// In en, this message translates to:
  /// **'Scan QR (Beta NFC) — Unlock'**
  String get sessionScanQrUnlock;

  /// No description provided for @sessionEmergencyUnlock.
  ///
  /// In en, this message translates to:
  /// **'Emergency Unlock (Burn Credits)'**
  String get sessionEmergencyUnlock;

  /// No description provided for @sessionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Session start failed: {error}'**
  String sessionStartFailed(String error);

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR (Beta NFC)'**
  String get qrScanTitle;

  /// No description provided for @qrDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Camera QR is for Android beta devices. Enter the beta code below.'**
  String get qrDesktopHint;

  /// No description provided for @qrPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan the beta QR.'**
  String get qrPermissionRequired;

  /// No description provided for @qrCameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera. Grant Camera Permission in settings and try again.'**
  String get qrCameraOpenFailed;

  /// No description provided for @qrGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Camera Permission'**
  String get qrGrantPermission;

  /// No description provided for @qrOrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter the beta code manually:'**
  String get qrOrEnterManually;

  /// No description provided for @qrBetaAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Beta auth code'**
  String get qrBetaAuthCode;

  /// No description provided for @qrScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan the LoqOut beta QR (\"{payload}\")'**
  String qrScanPrompt(String payload);

  /// No description provided for @qrUnrecognized.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized QR. Got \"{got}\" — need \"{expected}\".'**
  String qrUnrecognized(String got, String expected);

  /// No description provided for @qrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Expected: {expected}'**
  String qrInvalidCode(String expected);

  /// No description provided for @emergencyOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Override'**
  String get emergencyOverrideTitle;

  /// No description provided for @emergencyOverrideBody.
  ///
  /// In en, this message translates to:
  /// **'Breaking this session will burn {cost} Impact Credits. As a Corporate Pledge, LoqOut donates the financial equivalent to charity.'**
  String emergencyOverrideBody(int cost);

  /// No description provided for @emergencyOverrideOrdinal.
  ///
  /// In en, this message translates to:
  /// **'This is your {ordinal} unlock this month.'**
  String emergencyOverrideOrdinal(String ordinal);

  /// No description provided for @emergencyInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Impact Credits for this override.'**
  String get emergencyInsufficient;

  /// No description provided for @emergencyInsufficientHint.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Impact Credits. Unlock with NFC, or wait for next month\'s quota.'**
  String get emergencyInsufficientHint;

  /// No description provided for @emergencyConfirmBurn.
  ///
  /// In en, this message translates to:
  /// **'Burn credits & unlock'**
  String get emergencyConfirmBurn;

  /// No description provided for @emergencyKeepLocked.
  ///
  /// In en, this message translates to:
  /// **'Keep session locked'**
  String get emergencyKeepLocked;

  /// No description provided for @impactTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impactTitle;

  /// No description provided for @impactHowThisWorks.
  ///
  /// In en, this message translates to:
  /// **'How this works'**
  String get impactHowThisWorks;

  /// No description provided for @impactHowThisWorksBody.
  ///
  /// In en, this message translates to:
  /// **'Emergency unlocking a session burns your Monthly Impact Quota. As a Corporate Pledge, LoqOut donates the financial equivalent of your burned quota to global charities. If you focus you win, if you don\'t focus the world wins.'**
  String get impactHowThisWorksBody;

  /// No description provided for @impactMonthlyQuota.
  ///
  /// In en, this message translates to:
  /// **'Monthly Impact Quota'**
  String get impactMonthlyQuota;

  /// No description provided for @impactCredits.
  ///
  /// In en, this message translates to:
  /// **'Impact Credits'**
  String get impactCredits;

  /// No description provided for @impactQuotaBlurb.
  ///
  /// In en, this message translates to:
  /// **'Included with your focus subscription. Emergency overrides draw from this monthly quota.'**
  String get impactQuotaBlurb;

  /// No description provided for @impactPenaltyLadder.
  ///
  /// In en, this message translates to:
  /// **'Penalty Ladder'**
  String get impactPenaltyLadder;

  /// No description provided for @impactPenaltyIntro.
  ///
  /// In en, this message translates to:
  /// **'The cost of breaking your focus escalates with every unlock.'**
  String get impactPenaltyIntro;

  /// No description provided for @impactPenaltyMonthStats.
  ///
  /// In en, this message translates to:
  /// **'This month · {used} used · next override {next} credits'**
  String impactPenaltyMonthStats(int used, int next);

  /// No description provided for @impactPenaltyCapDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Cost escalates up to a maximum of 40 credits per unlock.'**
  String get impactPenaltyCapDisclaimer;

  /// No description provided for @impactCorporatePledge.
  ///
  /// In en, this message translates to:
  /// **'Corporate Pledge'**
  String get impactCorporatePledge;

  /// No description provided for @impactLifetimePledged.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Impact Credits pledged'**
  String get impactLifetimePledged;

  /// No description provided for @impactPledgeBody.
  ///
  /// In en, this message translates to:
  /// **'85% of burned Impact Credit value is pledged by LoqOut to verified global charities. Your focus discipline funds impact.'**
  String get impactPledgeBody;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Behavioral telemetry'**
  String get insightsHeroTitle;

  /// No description provided for @insightsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See how mood, friction, and focus windows shape your attention.'**
  String get insightsHeroSubtitle;

  /// No description provided for @insightsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get insightsEmptyTitle;

  /// No description provided for @insightsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a focus session to unlock your attention analytics.'**
  String get insightsEmptyBody;

  /// No description provided for @insightsSessionsAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions analyzed · updated {time}'**
  String insightsSessionsAnalyzed(int count, String time);

  /// No description provided for @insightsExportBeta.
  ///
  /// In en, this message translates to:
  /// **'Export Beta Telemetry'**
  String get insightsExportBeta;

  /// No description provided for @insightsExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get insightsExporting;

  /// No description provided for @insightsMoodDistractionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood vs. distraction'**
  String get insightsMoodDistractionTitle;

  /// No description provided for @insightsMoodDistractionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where attention slips — and what it costs you'**
  String get insightsMoodDistractionSubtitle;

  /// No description provided for @insightsVulnerability.
  ///
  /// In en, this message translates to:
  /// **'You are most vulnerable to distractions when feeling {mood}. We blocked {count} urge(s) to open apps while you were in this state.'**
  String insightsVulnerability(String mood, int count);

  /// No description provided for @insightsFrictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Friction score'**
  String get insightsFrictionTitle;

  /// No description provided for @insightsBeforeAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Before & after'**
  String get insightsBeforeAfterTitle;

  /// No description provided for @insightsBeforeAfterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How focus sessions reshape how you feel'**
  String get insightsBeforeAfterSubtitle;

  /// No description provided for @insightsBeforeAfterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Complete a post-session check-in to unlock your mood story.'**
  String get insightsBeforeAfterEmpty;

  /// No description provided for @insightsShiftFromTo.
  ///
  /// In en, this message translates to:
  /// **'You mostly shift from {start}  →  {end}.'**
  String insightsShiftFromTo(String start, String end);

  /// No description provided for @insightsPeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak focus window'**
  String get insightsPeakTitle;

  /// No description provided for @insightsMoodImproves.
  ///
  /// In en, this message translates to:
  /// **'Focusing improves your mood.'**
  String get insightsMoodImproves;

  /// No description provided for @insightsMoodSteadies.
  ///
  /// In en, this message translates to:
  /// **'Focusing steadies your emotional state.'**
  String get insightsMoodSteadies;

  /// No description provided for @insightsMoodDeclines.
  ///
  /// In en, this message translates to:
  /// **'Sessions leave you more drained — protect recovery.'**
  String get insightsMoodDeclines;

  /// No description provided for @postSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick check-in'**
  String get postSessionTitle;

  /// No description provided for @postSessionPrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you feel after this focus session?'**
  String get postSessionPrompt;

  /// No description provided for @postSessionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get postSessionSkip;

  /// No description provided for @blocklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Blocklist'**
  String get blocklistTitle;

  /// No description provided for @blocklistSave.
  ///
  /// In en, this message translates to:
  /// **'Save Blocklist'**
  String get blocklistSave;

  /// No description provided for @blocklistSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get blocklistSaving;

  /// No description provided for @blocklistEmptyApps.
  ///
  /// In en, this message translates to:
  /// **'No launchable apps found.'**
  String get blocklistEmptyApps;

  /// No description provided for @blocklistSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one app for your Default Blocklist.'**
  String get blocklistSelectOne;

  /// No description provided for @blocklistSaved.
  ///
  /// In en, this message translates to:
  /// **'Default Blocklist saved — {count} apps.'**
  String blocklistSaved(int count);

  /// No description provided for @blocklistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load apps: {error}'**
  String blocklistLoadFailed(String error);

  /// No description provided for @blocklistSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save blocklist: {error}'**
  String blocklistSaveFailed(String error);

  /// No description provided for @blocklistOpenUsageSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Usage Access Settings'**
  String get blocklistOpenUsageSettings;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions required'**
  String get permissionsTitle;

  /// No description provided for @permissionsBody.
  ///
  /// In en, this message translates to:
  /// **'LoqOut needs a few system permissions to enforce focus sessions. Grant each one below.'**
  String get permissionsBody;

  /// No description provided for @permissionsGrantedRecheck.
  ///
  /// In en, this message translates to:
  /// **'I granted them — check again'**
  String get permissionsGrantedRecheck;

  /// No description provided for @permissionsGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get permissionsGrant;

  /// No description provided for @daypartMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get daypartMorning;

  /// No description provided for @daypartAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get daypartAfternoon;

  /// No description provided for @daypartEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get daypartEvening;

  /// No description provided for @daypartNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get daypartNight;

  /// No description provided for @iosShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get iosShieldTitle;

  /// No description provided for @iosShieldBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the apps, categories, and websites LoqOut locks during a focus session. Apple keeps those names on the device; LoqOut only receives the shield tokens.'**
  String get iosShieldBody;

  /// No description provided for @iosShieldAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Allow Screen Time access'**
  String get iosShieldAuthorize;

  /// No description provided for @iosShieldOpenPicker.
  ///
  /// In en, this message translates to:
  /// **'Choose what to shield'**
  String get iosShieldOpenPicker;

  /// No description provided for @iosShieldDenied.
  ///
  /// In en, this message translates to:
  /// **'Screen Time access is off. Enable it for LoqOut in Settings.'**
  String get iosShieldDenied;

  /// No description provided for @iosShieldOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get iosShieldOpenSettings;

  /// No description provided for @iosShieldPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'A passcode is required'**
  String get iosShieldPasscodeTitle;

  /// No description provided for @iosShieldPasscodeBody.
  ///
  /// In en, this message translates to:
  /// **'LoqOut can lock other apps only after this iPhone has a passcode. Apple requires one for Screen Time access. Set it in Settings > Face ID & Passcode, or Touch ID & Passcode, then come back and try again.'**
  String get iosShieldPasscodeBody;

  /// No description provided for @iosShieldTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get iosShieldTryAgain;

  /// No description provided for @iosShieldRestricted.
  ///
  /// In en, this message translates to:
  /// **'Screen Time is restricted on this iPhone, so LoqOut cannot lock apps. A parent or the organization that manages the phone usually sets this.'**
  String get iosShieldRestricted;

  /// No description provided for @iosShieldNetwork.
  ///
  /// In en, this message translates to:
  /// **'LoqOut could not reach Apple to turn on Screen Time access. Check the connection and try again.'**
  String get iosShieldNetwork;

  /// No description provided for @iosShieldUnknown.
  ///
  /// In en, this message translates to:
  /// **'LoqOut could not turn on Screen Time access. Try again in a moment.'**
  String get iosShieldUnknown;

  /// No description provided for @iosShieldNeedApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Time access is off'**
  String get iosShieldNeedApprovalTitle;

  /// No description provided for @iosShieldNeedApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Screen Time access on the shield screen before locking. An iPhone without a passcode cannot turn this on.'**
  String get iosShieldNeedApprovalBody;

  /// No description provided for @iosShieldSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one app, category, or website to shield.'**
  String get iosShieldSelectOne;

  /// No description provided for @iosShieldSaved.
  ///
  /// In en, this message translates to:
  /// **'Shield updated.'**
  String get iosShieldSaved;

  /// No description provided for @iosShieldSummary.
  ///
  /// In en, this message translates to:
  /// **'{apps} apps · {categories} categories · {sites} websites'**
  String iosShieldSummary(int apps, int categories, int sites);

  /// No description provided for @iosShieldApps.
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String iosShieldApps(int count);

  /// No description provided for @iosShieldCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String iosShieldCategories(int count);

  /// No description provided for @iosShieldSites.
  ///
  /// In en, this message translates to:
  /// **'{count} websites'**
  String iosShieldSites(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
