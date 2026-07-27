import 'package:cashspark/core/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(labelText: 'Email'),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(hintText: 'Enter email / Gmail address'),
          ),
        ),
      );

      expect(find.text('Enter email / Gmail address'), findsOneWidget);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(prefixIcon: Icons.email_outlined),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('renders with prefix text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(prefixText: '+1'),
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('password field shows visibility toggle icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(isPassword: true),
          ),
        ),
      );

      // Password field shows the "visibility off" icon (eye with slash)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('toggles password visibility when tapping the icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(isPassword: true),
          ),
        ),
      );

      // Initially shows visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Now shows visibility icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(changedValue, 'hello');
    });

    testWidgets('validates and shows error text', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation through FormState
      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('validates and passes when input is valid', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                validator: (value) {
                  result = value;
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'valid input');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(result, 'valid input');
    });

    testWidgets('renders with suffix icon (non-password)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(suffixIcon: Icons.check_circle),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              enabled: false,
              controller: controller,
            ),
          ),
        ),
      );

      // Attempt to enter text — disabled field should not update
      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.pumpAndSettle();

      // Controller text should remain unchanged
      expect(controller.text, isEmpty);
    });

    testWidgets('uses provided controller with initial text', (tester) async {
      final controller = TextEditingController(text: 'prefilled');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(controller: controller),
          ),
        ),
      );

      expect(find.text('prefilled'), findsOneWidget);
    });

    testWidgets('updates controller text when typing', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'typed text');
      expect(controller.text, 'typed text');
    });

    testWidgets('password field keeps visibility toggle when multiline maxLines passed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(isPassword: true, maxLines: 3),
          ),
        ),
      );

      // Password field still shows the visibility toggle even with maxLines: 3
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      // Password field should have maxLines forced to 1 internally,
      // but we verify the correct widget structure exists
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('handles phone field with prefix and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              isPhone: true,
              prefixText: '+1',
              labelText: 'Phone',
            ),
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('handles email field with icon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              isEmail: true,
              labelText: 'Email Address',
              prefixIcon: Icons.email_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('non-password field accepts custom keyboardType via parameter',
        (tester) async {
      // We can't directly read the keyboardType, but we verify the field
      // renders correctly when given a non-default keyboard type
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              keyboardType: TextInputType.url,
              labelText: 'Website',
            ),
          ),
        ),
      );

      expect(find.text('Website'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
