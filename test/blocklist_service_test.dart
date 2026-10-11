import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapfocus_project/services/blocklist_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('BlocklistService', () {
    test('load returns empty by default', () async {
      final service = BlocklistService();
      final list = await service.load();
      expect(list.isEmpty, isTrue);
      expect(list.packages, isEmpty);
      expect(list.summaryLabels(), 'None');
    });

    test('save and load round-trip packages and names', () async {
      final service = BlocklistService();
      await service.save(
        packages: const [
          'com.instagram.android',
          'com.zhiliaoapp.musically',
        ],
        names: const ['Instagram', 'TikTok'],
      );

      final list = await service.load();
      expect(list.length, 2);
      expect(list.packages, [
        'com.instagram.android',
        'com.zhiliaoapp.musically',
      ]);
      expect(list.names, ['Instagram', 'TikTok']);
      expect(list.summaryLabels(), 'Instagram, TikTok');
    });

    test('save dedupes and trims packages', () async {
      final service = BlocklistService();
      await service.save(
        packages: const [
          ' com.a ',
          'com.a',
          'com.b',
          '',
        ],
        names: const ['A', 'A-dup', 'B', 'ignored'],
      );

      final list = await service.load();
      expect(list.packages, ['com.a', 'com.b']);
      expect(list.names.length, 2);
    });

    test('summary truncates long lists', () async {
      final list = DefaultBlocklist(
        packages: const ['a', 'b', 'c', 'd'],
        names: const ['One', 'Two', 'Three', 'Four'],
      );
      expect(list.summaryLabels(maxNames: 3), 'One, Two, Three +1 more');
    });

    test('clear empties the default blocklist', () async {
      final service = BlocklistService();
      await service.save(
        packages: const ['com.x'],
        names: const ['X'],
      );
      await service.clear();
      final list = await service.load();
      expect(list.isEmpty, isTrue);
    });

    test('uses distinct prefs key from session watchdog list', () {
      expect(
        BlocklistService.packagesKey,
        isNot(equals('tapfocus_blocked_apps')),
      );
    });
  });
}
