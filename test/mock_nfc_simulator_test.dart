import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/widgets/mock_nfc_button.dart';

void main() {
  group('MockNfcSimulator', () {
    testWidgets('transitions countdown to NfcAuthResult.success',
        (tester) async {
      NfcAuthResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await MockNfcSimulator.authenticate(
                      context: context,
                      title: 'Mock NFC Tap (Test Mode)',
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Text('Start Mock NFC'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Start Mock NFC'));
      await tester.pump(); // show dialog
      expect(find.byType(MockNfcCountdownDialog), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('OK'), findsOneWidget);

      // Allow completion pop delay (350ms).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(result, NfcAuthResult.success);
      expect(find.byType(MockNfcCountdownDialog), findsNothing);
    });

    testWidgets('Cancel yields NfcAuthResult.cancelled', (tester) async {
      NfcAuthResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await MockNfcSimulator.authenticate(
                      context: context,
                      title: 'Mock NFC Tap (Test Mode)',
                      duration: const Duration(seconds: 5),
                    );
                  },
                  child: const Text('Start Mock NFC'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Start Mock NFC'));
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, NfcAuthResult.cancelled);
      expect(find.byType(MockNfcCountdownDialog), findsNothing);
    });

    testWidgets('run() returns true on success and false on cancel',
        (tester) async {
      bool? ok;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        ok = await MockNfcSimulator.run(
                          context: context,
                          title: 'Mock',
                          duration: const Duration(seconds: 1),
                        );
                      },
                      child: const Text('Succeed'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        ok = await MockNfcSimulator.run(
                          context: context,
                          title: 'Mock',
                          duration: const Duration(seconds: 5),
                        );
                      },
                      child: const Text('Will Cancel'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Succeed'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(ok, isTrue);

      await tester.tap(find.text('Will Cancel'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ok, isFalse);
    });
  });
}
