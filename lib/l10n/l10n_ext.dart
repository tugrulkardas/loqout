import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Convenience accessor for generated localizations.
extension TapFocusL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Maps English mood telemetry keys (stable for ML/CSV) to localized UI labels.
String localizeMoodLabel(AppLocalizations l10n, String englishKey) {
  switch (englishKey) {
    case 'Neutral':
      return l10n.moodNeutral;
    case 'Enraged':
      return l10n.moodEnraged;
    case 'Furious':
      return l10n.moodFurious;
    case 'Panicked':
      return l10n.moodPanicked;
    case 'Stressed':
      return l10n.moodStressed;
    case 'Frustrated':
      return l10n.moodFrustrated;
    case 'Annoyed':
      return l10n.moodAnnoyed;
    case 'Anxious':
      return l10n.moodAnxious;
    case 'Uneasy':
      return l10n.moodUneasy;
    case 'Despair':
      return l10n.moodDespair;
    case 'Depressed':
      return l10n.moodDepressed;
    case 'Exhausted':
      return l10n.moodExhausted;
    case 'Alert':
      return l10n.moodAlert;
    case 'Tired':
      return l10n.moodTired;
    case 'Ecstatic':
      return l10n.moodEcstatic;
    case 'Thrilled':
      return l10n.moodThrilled;
    case 'Energized':
      return l10n.moodEnergized;
    case 'Happy':
      return l10n.moodHappy;
    case 'Productive':
      return l10n.moodProductive;
    case 'Focused':
      return l10n.moodFocused;
    case 'Content':
      return l10n.moodContent;
    case 'At ease':
      return l10n.moodAtEase;
    case 'Serene':
      return l10n.moodSerene;
    case 'Peaceful':
      return l10n.moodPeaceful;
    case 'Chill':
      return l10n.moodChill;
    default:
      return englishKey;
  }
}
