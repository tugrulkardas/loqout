// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'LoqOut';

  @override
  String get productMotto =>
      'Odaklanırsan sen kazanırsın, odaklanmazsan dünya kazanır.';

  @override
  String get gateStarting => 'LoqOut hazırlanıyor…';

  @override
  String get focusHowFeeling => 'Şu an nasıl hissediyorsunuz?';

  @override
  String get focusAxisGuide => 'Enerji (dikey) · Duygu (yatay)';

  @override
  String get navFocus => 'Odak';

  @override
  String get navInsights => 'İçgörüler';

  @override
  String get navImpact => 'Etki';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get confirm => 'Onayla';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get refresh => 'Yenile';

  @override
  String get openAppSettings => 'Uygulama ayarlarını aç';

  @override
  String themeTooltip(String mode) {
    return 'Tema: $mode';
  }

  @override
  String get themeDay => 'Gündüz';

  @override
  String get themeNight => 'Gece';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get languageTooltip => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get axisHighEnergy => 'Zinde';

  @override
  String get axisLowEnergy => 'Tükenmiş';

  @override
  String get axisPleasant => 'Pozitif';

  @override
  String get axisUnpleasant => 'Gergin';

  @override
  String get moodNeutral => 'Nötr';

  @override
  String get moodEnraged => 'Öfkeli';

  @override
  String get moodFurious => 'Hiddetli';

  @override
  String get moodPanicked => 'Panik';

  @override
  String get moodStressed => 'Stresli';

  @override
  String get moodFrustrated => 'Hüsran içinde';

  @override
  String get moodAnnoyed => 'Rahatsız';

  @override
  String get moodAnxious => 'Kaygılı';

  @override
  String get moodUneasy => 'Huzursuz';

  @override
  String get moodDespair => 'Umutsuz';

  @override
  String get moodDepressed => 'Çökmüş';

  @override
  String get moodExhausted => 'Bitkin';

  @override
  String get moodAlert => 'Uyanık';

  @override
  String get moodTired => 'Yorgun';

  @override
  String get moodEcstatic => 'Coşkulu';

  @override
  String get moodThrilled => 'Heyecanlı';

  @override
  String get moodEnergized => 'Enerjik';

  @override
  String get moodHappy => 'Mutlu';

  @override
  String get moodProductive => 'Verimli';

  @override
  String get moodFocused => 'Odaklı';

  @override
  String get moodContent => 'Memnun';

  @override
  String get moodAtEase => 'Rahat';

  @override
  String get moodSerene => 'Huzurlu';

  @override
  String get moodPeaceful => 'Sakin';

  @override
  String get moodChill => 'Dingin';

  @override
  String get checkInStressedFrustrated => 'Stresli / Hüsran içinde';

  @override
  String get checkInDrainedDistracted => 'Tükenmiş / Dağınık';

  @override
  String get checkInCalmFocused => 'Sakin / Odaklı';

  @override
  String get checkInEnergizedProductive => 'Enerjik / Verimli';

  @override
  String get energyHigh => 'Zinde';

  @override
  String get energyLow => 'Tükenmiş';

  @override
  String get valencePleasant => 'Pozitif';

  @override
  String get valenceUnpleasant => 'Gergin';

  @override
  String get focusTitle => 'Odak';

  @override
  String get focusMoodSelectedHint =>
      'Ruh haliniz seçildi. Odağı NFC veya QR ile başlatın.';

  @override
  String get focusBlocklistUpdated =>
      'Kalkan listesi güncellendi. Odağı NFC veya QR ile başlatın.';

  @override
  String get focusConfigureBlocklist =>
      'Odağa geçmeden önce varsayılan kalkan listenizi seçin.';

  @override
  String get focusNfcActivate => 'NFC — Odağı Başlat';

  @override
  String get focusScanQrBeta => 'QR Tara (Beta)';

  @override
  String get focusQrAuthenticated => 'Beta QR doğrulandı. Odak başlıyor…';

  @override
  String focusNfcCheckFailed(String error) {
    return 'NFC yanıt vermedi: $error. Aşağıdan QR ile devam edin.';
  }

  @override
  String get focusNfcUnavailable => 'Bu cihazda NFC yok. QR ile devam edin.';

  @override
  String get focusNoAppsShielded => 'Kalkan için uygulama henüz seçilmedi';

  @override
  String focusShieldCount(int count) {
    return '$count uygulama kalkan altında';
  }

  @override
  String get focusEditBlocklist => 'Kalkan listesi';

  @override
  String focusEnergyValencePair(String energy, String valence) {
    return '$energy · $valence';
  }

  @override
  String get sessionLocked => 'Oturum kilitli';

  @override
  String get sessionActivating => 'Etkinleştiriliyor…';

  @override
  String sessionMoodLine(String mood, int intensity) {
    return 'Ruh hali: $mood (Yoğunluk: $intensity/5)';
  }

  @override
  String sessionAuthLine(String channel, String uid) {
    return 'Doğrulama: $channel ($uid…)';
  }

  @override
  String get sessionAuthBetaQr => 'Beta QR';

  @override
  String get sessionAuthMockNfc => 'Deneme NFC';

  @override
  String get sessionAuthNfc => 'NFC';

  @override
  String sessionShieldingApps(int count) {
    return '$count uygulama kalkan altında';
  }

  @override
  String sessionBlockedAttempt(String package) {
    return 'Engellenen deneme: $package';
  }

  @override
  String get sessionStartingWatchdog => 'Odak denetimi başlıyor…';

  @override
  String get sessionActivateFailed =>
      'Odak henüz başlamadı. İzinleri kontrol edip yeniden deneyin.';

  @override
  String get sessionRetryActivate => 'Odağı yeniden başlat';

  @override
  String sessionAppsLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uygulama kilitli',
      one: '1 uygulama kilitli',
    );
    return '$_temp0';
  }

  @override
  String sessionCategoriesLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kategori kilitli',
      one: '1 kategori kilitli',
    );
    return '$_temp0';
  }

  @override
  String sessionWebsitesLocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count site kilitli',
      one: '1 site kilitli',
    );
    return '$_temp0';
  }

  @override
  String get lockThisSession => 'Bu oturum';

  @override
  String lockFocusTimeToday(int minutes) {
    return 'Bugün $minutes dk odak';
  }

  @override
  String lockFocusTimeWeek(int minutes) {
    return 'Bu hafta $minutes dk';
  }

  @override
  String lockStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Günlük Seri',
      one: '1 Günlük Seri',
      zero: '0 Günlük Seri',
    );
    return '$_temp0';
  }

  @override
  String get lockNoStreak => 'Henüz seri yok';

  @override
  String get lockInsightEmpty => 'Kaydın bu oturumla başlıyor.';

  @override
  String get lockHoldToUnlock => 'Açmak için basılı tut';

  @override
  String get lockStreakKeeps => 'Şimdi bitirmek bugünü seride tutar.';

  @override
  String get lockStreakMiss => 'Şimdi bitirmek bugünü seriye yazmaz.';

  @override
  String get lockStreakAlready => 'Bugün zaten seride.';

  @override
  String lockMinutesToStreak(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Bugünü seriye yazmaya $minutes dk kaldı',
      one: 'Bugünü seriye yazmaya 1 dk kaldı',
    );
    return '$_temp0';
  }

  @override
  String get lockTodayOnStreak => 'Bugün seride ✓';

  @override
  String get lockStartToday => 'Bugün başla';

  @override
  String lockMinutesShort(int count) {
    return '$count dk';
  }

  @override
  String lockHoursShort(String hours) {
    return '$hours sa';
  }

  @override
  String lockCumulativeToday(String amount) {
    return 'Bugün $amount';
  }

  @override
  String lockCumulativeWeek(String amount) {
    return 'Bu hafta $amount';
  }

  @override
  String lockCumulativeAllTime(String amount) {
    return 'Tüm zaman $amount';
  }

  @override
  String lockDayFocusShare(int percent) {
    return 'Günün %$percent\'ini odakta geçirdin';
  }

  @override
  String lockWeekFocusShare(int percent) {
    return 'Bu hafta uyanık sürenin %$percent\'i';
  }

  @override
  String get lockFocusShareNote =>
      'LoqOut içindeki odak süresi. Ekran süresi değil.';

  @override
  String get lockDayFocusShareUnder => 'Günün %1\'inden azını odakta geçirdin';

  @override
  String get lockWeekFocusShareUnder => 'Bu hafta uyanık sürenin %1\'inden azı';

  @override
  String lockAttemptsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count kez açmaya çalıştın, hepsinde engelledik.',
      one: 'Bugün 1 kez açmaya çalıştın, engelledik.',
    );
    return '$_temp0';
  }

  @override
  String lockAttemptsSession(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu oturumda $count kez.',
      one: 'Bu oturumda 1 kez.',
    );
    return '$_temp0';
  }

  @override
  String lockImpulsesBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '🛡️ $count Kez Kalkana Takıldın',
      one: '🛡️ 1 Kez Kalkana Takıldın',
    );
    return '$_temp0';
  }

  @override
  String lockReclaimedDay(String percent) {
    return 'Gününün %$percent kadarını geri aldın, tebrikler.';
  }

  @override
  String lockImpactUnlock(int currentTokens, int requiredTokens) {
    return '⚡ Mevcut: $currentTokens Impact Token • Sıradaki Açılış: $requiredTokens Token';
  }

  @override
  String lockAppChipBlocked(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count engelleme',
      one: '1 engelleme',
    );
    return '$name • $_temp0';
  }

  @override
  String lockAppChipLocked(String name) {
    return '$name • Kilitli';
  }

  @override
  String lockAppChipImpulses(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dürtü',
      one: '1 dürtü',
    );
    return '$name • $_temp0';
  }

  @override
  String lockBlockedAppSlot(int index) {
    return 'Engellenen Uygulama #$index';
  }

  @override
  String lockInsightFriction(int count, int minutes) {
    return '$count engelleme, son 7 gün. Yaklaşık $minutes dk — tahmin, ölçülmüş ekran süresi değil.';
  }

  @override
  String get lockUnlockAction => 'Kilidi aç';

  @override
  String get lockHoldSemanticsHint =>
      'Basılı tutmadan açmak için çift dokunun.';

  @override
  String get insightsFrictionEstimate =>
      'Yalnızca tahmin. Engellenen her deneme için yaklaşık 15 dakika. Ölçülmüş ekran süresi değildir.';

  @override
  String get insightsEstimatedAttention => 'Tahmini';

  @override
  String get sessionUnlockHint =>
      'Kilitli bir uygulama sizi buraya getirir.\nÇıkış için NFC veya QR kullanın. Acil Durum Kalkan İhlali İrade Kredisi yakar.';

  @override
  String get sessionScanQrUnlock => 'QR ile kilidi aç';

  @override
  String get sessionEmergencyUnlock => 'Acil Durum Kalkan İhlali';

  @override
  String sessionStartFailed(String error) {
    return 'Oturum başlatılamadı: $error';
  }

  @override
  String get qrScanTitle => 'QR Tara (Beta NFC)';

  @override
  String get qrDesktopHint =>
      'Kamera ile QR tarama Android beta cihazlar içindir. Beta kodunu aşağıya yazın.';

  @override
  String get qrPermissionRequired => 'Beta QR için kamera izni gerekir.';

  @override
  String get qrCameraOpenFailed =>
      'Kamera açılamadı. Ayarlardan izin verip yeniden deneyin.';

  @override
  String get qrGrantPermission => 'Kamera izni ver';

  @override
  String get qrOrEnterManually => 'Ya da beta kodunu yazın:';

  @override
  String get qrBetaAuthCode => 'Beta kodu';

  @override
  String qrScanPrompt(String payload) {
    return 'LoqOut beta QR kodunu tarayın (\"$payload\")';
  }

  @override
  String qrUnrecognized(String got, String expected) {
    return 'Bu QR tanınmadı. Okunan: \"$got\". Beklenen: \"$expected\".';
  }

  @override
  String qrInvalidCode(String expected) {
    return 'Kod geçersiz. Beklenen: $expected';
  }

  @override
  String get emergencyOverrideTitle => 'Acil Durum Kalkan İhlali';

  @override
  String emergencyOverrideBody(int cost) {
    return 'Bu oturumu kırmak $cost İrade Kredisi yakar. Kurumsal Taahhüt gereği LoqOut, yakılan tutarın karşılığını hayır kurumlarına aktarır.';
  }

  @override
  String emergencyOverrideOrdinal(String ordinal) {
    return 'Bu ayki $ordinal kalkan ihlaliniz.';
  }

  @override
  String get emergencyInsufficient => 'Bu ihlal için İrade Krediniz yetmiyor.';

  @override
  String get emergencyInsufficientHint =>
      'İrade Krediniz yetmiyor. NFC ile çıkın ya da gelecek ayın kotasını bekleyin.';

  @override
  String get emergencyConfirmBurn => 'Krediyi yak, kilidi aç';

  @override
  String get emergencyKeepLocked => 'Oturumu kilitli tut';

  @override
  String get impactTitle => 'Etki';

  @override
  String get impactHowThisWorks => 'Nasıl işler';

  @override
  String get impactHowThisWorksBody =>
      'Acil Durum Kalkan İhlali, Aylık İrade Kotanızı yakar. Kurumsal Taahhüt gereği LoqOut, yakılan tutarın karşılığını küresel hayır kurumlarına aktarır. Odaklanırsan sen kazanırsın, odaklanmazsan dünya kazanır.';

  @override
  String get impactMonthlyQuota => 'Aylık İrade Kotası';

  @override
  String get impactCredits => 'İrade Kredisi';

  @override
  String get impactQuotaBlurb =>
      'Odak aboneliğinize dahildir. Acil Durum Kalkan İhlali bu kotadan düşülür.';

  @override
  String get impactPenaltyLadder => 'Taviz Maliyeti';

  @override
  String get impactPenaltyIntro => 'Odağı bozmanın bedeli her ihlalde artar.';

  @override
  String impactPenaltyMonthStats(int used, int next) {
    return 'Bu ay · $used ihlal · sıradaki bedel $next kredi';
  }

  @override
  String get impactPenaltyCapDisclaimer =>
      'Bedel, ihlal başına en fazla 40 kredide sabitlenir.';

  @override
  String get impactCorporatePledge => 'Kurumsal Taahhüt';

  @override
  String get impactLifetimePledged => 'Bugüne dek taahhüt edilen İrade Kredisi';

  @override
  String get impactPledgeBody =>
      'Yakılan İrade Kredisinin %85’i, LoqOut tarafından doğrulanmış küresel hayır kurumlarına aktarılır. Disiplininiz etki üretir.';

  @override
  String get insightsTitle => 'İçgörüler';

  @override
  String get insightsHeroTitle => 'Dikkat kaydı';

  @override
  String get insightsHeroSubtitle =>
      'Ruh hali, sürtünme ve odak saatleri dikkatinizi nasıl belirliyor.';

  @override
  String get insightsEmptyTitle => 'Henüz kayıt yok';

  @override
  String get insightsEmptyBody =>
      'İlk odak oturumunuzdan sonra analiziniz burada görünür.';

  @override
  String insightsSessionsAnalyzed(int count, String time) {
    return '$count oturum · son güncelleme $time';
  }

  @override
  String get insightsExportBeta => 'Beta kaydını paylaş';

  @override
  String get insightsExporting => 'Hazırlanıyor…';

  @override
  String get insightsMoodDistractionTitle => 'Ruh hali ve dağınıklık';

  @override
  String get insightsMoodDistractionSubtitle =>
      'Dikkat nerede kayıyor, bedeli ne';

  @override
  String insightsVulnerability(String mood, int count) {
    return '$mood hissederken dağınıklığa en açık oluyorsunuz. Bu halde $count uygulama açma girişimi engellendi.';
  }

  @override
  String get insightsFrictionTitle => 'Sürtünme';

  @override
  String get insightsBeforeAfterTitle => 'Önce ve sonra';

  @override
  String get insightsBeforeAfterSubtitle =>
      'Odak, nasıl hissettiğinizi nasıl değiştiriyor';

  @override
  String get insightsBeforeAfterEmpty =>
      'Karşılaştırmayı görmek için oturum sonu kontrolünü tamamlayın.';

  @override
  String get insightsNotEnoughData => 'Henüz yeterli veri yok.';

  @override
  String get insightsPeakMorning =>
      'Sabah senin gücün. En zor işi öğleden önceye koy.';

  @override
  String get insightsPeakAfternoon =>
      'Odağın öğleden sonra yükseliyor. O saati dağınıklıktan koru.';

  @override
  String get insightsPeakEvening =>
      'Akşam kilitlendiğin saat. Toplantı ve kaydırmaya kaptırma.';

  @override
  String get insightsPeakNight =>
      'Gece kuşu gibisin. Akşam odak bloklarını koru.';

  @override
  String insightsShiftFromTo(String start, String end) {
    return 'En sık geçiş: $start  →  $end.';
  }

  @override
  String get insightsPeakTitle => 'En verimli saat';

  @override
  String get insightsMoodImproves => 'Odak, ruh halinizi toparlıyor.';

  @override
  String get insightsMoodSteadies => 'Odak, duygusal dengenizi sabitliyor.';

  @override
  String get insightsMoodDeclines =>
      'Oturumlar sizi daha tükenmiş bırakıyor. Toparlanmaya yer açın.';

  @override
  String get postSessionTitle => 'Kısa kontrol';

  @override
  String get postSessionPrompt => 'Bu oturumdan sonra nasıl hissediyorsunuz?';

  @override
  String get postSessionSkip => 'Geç';

  @override
  String get blocklistTitle => 'Kalkan Listesini Düzenle';

  @override
  String get blocklistSave => 'Kalkan Listesini Kaydet';

  @override
  String get blocklistSaving => 'Kaydediliyor…';

  @override
  String get blocklistEmptyApps => 'Listelenecek uygulama bulunamadı.';

  @override
  String get blocklistSelectOne => 'Kalkan için en az bir uygulama seçin.';

  @override
  String blocklistSaved(int count) {
    return 'Kalkan listesi kaydedildi — $count uygulama.';
  }

  @override
  String blocklistLoadFailed(String error) {
    return 'Uygulamalar yüklenemedi: $error';
  }

  @override
  String blocklistSaveFailed(String error) {
    return 'Kalkan listesi kaydedilemedi: $error';
  }

  @override
  String get blocklistOpenUsageSettings => 'Kullanım erişimini aç';

  @override
  String get permissionsTitle => 'Gerekli izinler';

  @override
  String get permissionsBody =>
      'LoqOut’un odağı uygulayabilmesi için aşağıdaki sistem izinleri gerekir.';

  @override
  String get permissionsGrantedRecheck => 'İzinleri verdim, yeniden kontrol et';

  @override
  String get permissionsGrant => 'İzin ver';

  @override
  String get daypartMorning => 'Sabah';

  @override
  String get daypartAfternoon => 'Öğleden sonra';

  @override
  String get daypartEvening => 'Akşam';

  @override
  String get daypartNight => 'Gece';

  @override
  String get iosShieldTitle => 'Kalkan';

  @override
  String get iosShieldBody =>
      'Odak oturumunda kilitlenecek uygulamaları, kategorileri ve siteleri seçin. Apple bu adları cihazda tutar; LoqOut yalnızca kalkan jetonlarını alır.';

  @override
  String get iosShieldAuthorize => 'Ekran Süresi iznini ver';

  @override
  String get iosShieldOpenPicker => 'Kalkan için seç';

  @override
  String get iosShieldDenied =>
      'Ekran Süresi izni kapalı. Ayarlar’dan LoqOut için açın.';

  @override
  String get iosShieldOpenSettings => 'Ayarları aç';

  @override
  String get iosShieldPasscodeTitle => 'Parola gerekli';

  @override
  String get iosShieldPasscodeBody =>
      'LoqOut diğer uygulamaları yalnızca bu iPhone’da bir parola varken kilitleyebilir. Apple, Ekran Süresi için bunu şart koşar. Ayarlar > Face ID ve Parola ya da Touch ID ve Parola bölümünden parola oluşturun, sonra buraya dönüp yeniden deneyin.';

  @override
  String get iosShieldTryAgain => 'Yeniden dene';

  @override
  String get iosShieldRestricted =>
      'Bu iPhone’da Ekran Süresi kısıtlı. LoqOut uygulamaları kilitleyemez. Bunu genellikle bir ebeveyn veya cihazı yöneten kuruluş ayarlar.';

  @override
  String get iosShieldNetwork =>
      'Ekran Süresi izni için Apple’a ulaşılamadı. Bağlantıyı kontrol edip yeniden deneyin.';

  @override
  String get iosShieldUnknown =>
      'Ekran Süresi izni açılamadı. Biraz sonra yeniden deneyin.';

  @override
  String get iosShieldNeedApprovalTitle => 'Ekran Süresi kapalı';

  @override
  String get iosShieldNeedApprovalBody =>
      'Kilitlemeden önce kalkan ekranından Ekran Süresi iznini verin. Parolası olmayan bir iPhone’da bu izin açılmaz.';

  @override
  String get iosShieldSelectOne =>
      'Kalkan için en az bir uygulama, kategori veya site seçin.';

  @override
  String get iosShieldSaved => 'Kalkan güncellendi.';

  @override
  String iosShieldSummary(int apps, int categories, int sites) {
    return '$apps uygulama · $categories kategori · $sites site';
  }

  @override
  String iosShieldApps(int count) {
    return '$count uygulama';
  }

  @override
  String iosShieldCategories(int count) {
    return '$count kategori';
  }

  @override
  String iosShieldSites(int count) {
    return '$count site';
  }
}
