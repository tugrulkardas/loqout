import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable user preference: which apps to shield during every focus session.
///
/// Distinct from session-scoped [kPrefsBlockedAppsKey] used by the watchdog
/// while a session is active (cleared on unlock).
class DefaultBlocklist {
  const DefaultBlocklist({
    required this.packages,
    required this.names,
  });

  final List<String> packages;
  final List<String> names;

  bool get isEmpty => packages.isEmpty;
  bool get isNotEmpty => packages.isNotEmpty;
  int get length => packages.length;

  /// Short summary for the launch badge, e.g. "Instagram, TikTok, …".
  String summaryLabels({int maxNames = 3}) {
    if (names.isEmpty && packages.isEmpty) return 'None';
    final labels = names.isNotEmpty ? names : packages;
    if (labels.length <= maxNames) return labels.join(', ');
    final head = labels.take(maxNames).join(', ');
    return '$head +${labels.length - maxNames} more';
  }
}

/// Persists the user's Default Blocklist across sessions and restarts.
class BlocklistService {
  BlocklistService();

  /// Do not reuse the watchdog session key — that list is cleared on unlock.
  static const String packagesKey = 'tapfocus_default_blocklist';
  static const String namesKey = 'tapfocus_default_blocklist_names';

  Future<DefaultBlocklist> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packages = List<String>.from(
        prefs.getStringList(packagesKey) ?? const <String>[],
      );
      final names = List<String>.from(
        prefs.getStringList(namesKey) ?? const <String>[],
      );
      // Keep names aligned with packages when possible.
      final alignedNames = <String>[];
      for (var i = 0; i < packages.length; i++) {
        if (i < names.length && names[i].trim().isNotEmpty) {
          alignedNames.add(names[i].trim());
        } else {
          alignedNames.add(packages[i]);
        }
      }
      return DefaultBlocklist(packages: packages, names: alignedNames);
    } catch (e, st) {
      debugPrint('BlocklistService.load failed: $e\n$st');
      return const DefaultBlocklist(packages: [], names: []);
    }
  }

  Future<List<String>> loadPackages() async => (await load()).packages;

  Future<void> save({
    required List<String> packages,
    List<String>? names,
  }) async {
    final cleaned = packages
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final labelSource = names ?? cleaned;
    final cleanedNames = <String>[];
    for (var i = 0; i < cleaned.length; i++) {
      if (i < labelSource.length && labelSource[i].trim().isNotEmpty) {
        cleanedNames.add(labelSource[i].trim());
      } else {
        cleanedNames.add(cleaned[i]);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(packagesKey, cleaned);
      await prefs.setStringList(namesKey, cleanedNames);
    } catch (e, st) {
      debugPrint('BlocklistService.save failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> clear() => save(packages: const [], names: const []);
}
