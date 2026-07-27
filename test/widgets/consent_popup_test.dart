import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/widgets/consent_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper that wraps ConsentPopup in a MaterialApp with a navigator
/// and route stubs for terms and privacy.
Future<void> pumpConsentPopup(
  WidgetTester tester, {
  VoidCallback? onAccepted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ConsentPopup(
                uid: 'test-uid',
                onAccepted: onAccepted ?? () {},
              ),
            ),
            child: const Text('Show Dialog'),
          ),
        ),
      ),
      routes: {
        AppRouter.terms: (_) => const Scaffold(
              body: Center(child: Text('Terms Stub')),
            ),
        AppRouter.privacy: (_) => const Scaffold(
              body: Center(child: Text('Privacy Stub')),
            ),
      },
    ),
  );

  // Open the dialog
  await tester.tap(find.text('Show Dialog'));
  await tester.pumpAndSettle();
}

void main() {
  group('ConsentPopup', () {
    testWidgets('displays the dialog title and description', (tester) async {
      await pumpConsentPopup(tester);

      expect(find.text('Agreement Required'), findsOneWidget);
      expect(
        find.text(
          'Please read and accept our legal agreements to continue using Fun Pay.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows Terms & Conditions and Privacy Policy sections',
        (tester) async {
      await pumpConsentPopup(tester);

      expect(find.text('I have read and agree to the'), findsNWidgets(2));
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('"Accept & Continue" button is initially disabled',
        (tester) async {
      await pumpConsentPopup(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('checking only Terms leaves button disabled',
        (tester) async {
      await pumpConsentPopup(tester);

      // Check Terms only
      final termsCheckbox = find.byKey(const Key('terms-checkbox'));
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('checking only Privacy leaves button disabled',
        (tester) async {
      await pumpConsentPopup(tester);

      // Check Privacy only
      final privacyCheckbox = find.byKey(const Key('privacy-checkbox'));
      await tester.tap(privacyCheckbox);
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('checking both checkboxes enables the Accept button',
        (tester) async {
      await pumpConsentPopup(tester);

      // Check both
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacy-checkbox')));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Accept calls onAccepted and pops the dialog',
        (tester) async {
      bool accepted = false;
      await pumpConsentPopup(
        tester,
        onAccepted: () => accepted = true,
      );

      // Check both
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacy-checkbox')));
      await tester.pumpAndSettle();

      // Tap Accept
      await tester.tap(find.text('Accept & Continue'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      // Dialog should be dismissed
      expect(find.text('Agreement Required'), findsNothing);
    });

    testWidgets('tapping Terms & Conditions navigates to terms route',
        (tester) async {
      await pumpConsentPopup(tester);

      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();

      expect(find.text('Terms Stub'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy navigates to privacy route',
        (tester) async {
      await pumpConsentPopup(tester);

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Stub'), findsOneWidget);
    });

    testWidgets('shows the info icon in the dialog', (tester) async {
      await pumpConsentPopup(tester);

      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('shows the note text at the bottom', (tester) async {
      await pumpConsentPopup(tester);

      expect(
        find.text('You must accept both agreements to continue'),
        findsOneWidget,
      );
    });

    testWidgets('can uncheck a checkbox and button becomes disabled again',
        (tester) async {
      await pumpConsentPopup(tester);

      // Check both
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacy-checkbox')));
      await tester.pumpAndSettle();

      // Verify button is enabled
      final buttonEnabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(buttonEnabled.onPressed, isNotNull);

      // Uncheck Terms
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();

      // Button should be disabled again
      final buttonDisabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Accept & Continue'),
      );
      expect(buttonDisabled.onPressed, isNull);
    });
  });
}
