import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n_ext.dart';
import 'screens/app_gate.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';
import 'theme/tapfocus_theme.dart';

// --- CONFIG ---
const String supabaseUrl = 'https://swdpklzvbnnpoqrxzgay.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3ZHBrbHp2Ym5ucG9xcnh6Z2F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4Njg1NzIsImV4cCI6MjA3NjQ0NDU3Mn0.an_7-tREwm5LVjmCqo4GylgVMFSkzdcwuYe3oiIVYyw';

/// Lazy getter — only use after [Supabase.initialize] completes.
SupabaseClient get supabase => Supabase.instance.client;

/// Lightweight, crash-safe entrypoint.
///
/// Guardrails (manifesto §7):
/// - No `flutter_background_service` configure/start here
/// - No usage-stats or overlay queries before the first Activity frame
/// - Background watchdog stays dormant until explicit session start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  } catch (e, st) {
    // Network / init failures must not prevent the UI from launching.
    debugPrint('Supabase init error (continuing without backend): $e\n$st');
  }

  await Future.wait([
    ThemeController.instance.ensureLoaded(),
    LocaleController.instance.ensureLoaded(),
  ]);
  runApp(const TapFocusApp());
}

class TapFocusApp extends StatelessWidget {
  const TapFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themes = ThemeController.instance;
    final locales = LocaleController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([themes, locales]),
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildTapFocusLightTheme(),
          darkTheme: buildTapFocusDarkTheme(),
          themeMode: themes.mode,
          locale: locales.materialLocale,
          localeResolutionCallback: (locale, supported) {
            // Prefer device / forced language when we ship it; else English.
            if (locale == null) return const Locale('en');
            for (final s in supported) {
              if (s.languageCode == locale.languageCode) return s;
            }
            return const Locale('en');
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppGate(),
        );
      },
    );
  }
}
