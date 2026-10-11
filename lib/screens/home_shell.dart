import 'package:flutter/material.dart';

import '../focus_setup_screen.dart';
import '../l10n/l10n_ext.dart';
import '../services/insights_service.dart';
import '../services/theme_controller.dart';
import '../services/wallet_manager.dart';
import 'impact_wallet_screen.dart';
import 'insights_dashboard_screen.dart';

/// Root shell after permissions: Focus · Insights · Impact Wallet.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final InsightsService _insights = InsightsService();
  final ThemeController _themes = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    // Warm wallet so Impact tab / emergency override see seeded balance.
    WalletManager.instance.ensureLoaded();
    _themes.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themes.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  String _localizedThemeMode(AppLocalizations l10n) {
    return switch (_themes.mode) {
      ThemeMode.light => l10n.themeDay,
      ThemeMode.dark => l10n.themeNight,
      ThemeMode.system => l10n.themeSystem,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeTip = l10n.themeTooltip(_localizedThemeMode(l10n));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          FocusSetupScreen(
            onToggleTheme: _themes.cycleMode,
            themeIcon: _themes.modeIcon,
            themeTooltip: themeTip,
          ),
          InsightsDashboardScreen(
            insightsService: _insights,
            onToggleTheme: _themes.cycleMode,
            themeIcon: _themes.modeIcon,
            themeTooltip: themeTip,
          ),
          ImpactWalletScreen(
            onToggleTheme: _themes.cycleMode,
            themeIcon: _themes.modeIcon,
            themeTooltip: themeTip,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 1) {
            _insights.load();
          } else if (i == 2) {
            WalletManager.instance.ensureLoaded();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.center_focus_weak_outlined),
            selectedIcon: const Icon(Icons.center_focus_strong),
            label: l10n.navFocus,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.navImpact,
          ),
        ],
      ),
    );
  }
}
