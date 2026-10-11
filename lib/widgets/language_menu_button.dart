import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/locale_controller.dart';

/// AppBar action: pick System / English / Turkish.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locales = LocaleController.instance;

    return PopupMenuButton<AppLanguagePreference>(
      tooltip: l10n.languageTooltip,
      icon: Icon(locales.preferenceIcon),
      initialValue: locales.preference,
      onSelected: locales.setPreference,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppLanguagePreference.system,
          child: Text(l10n.languageSystem),
        ),
        PopupMenuItem(
          value: AppLanguagePreference.english,
          child: Text(l10n.languageEnglish),
        ),
        PopupMenuItem(
          value: AppLanguagePreference.turkish,
          child: Text(l10n.languageTurkish),
        ),
      ],
    );
  }
}
