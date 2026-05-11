// Smoke test — verifies the LoginScreen builds and renders its key elements.
//
// We test LoginScreen in isolation (without GoRouter / full app bootstrap)
// because the production router has redirect logic that depends on auth state,
// secure storage, and async initialization which is awkward inside widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medicare/features/auth/presentation/screens/login_screen.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  testWidgets('LoginScreen builds without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(role: 'patient'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // No exception thrown by the pump above.
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginScreen renders email field and "Se connecter" button',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(role: 'patient'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // At least one TextField (email + password are both TextField subclasses).
    expect(find.byType(TextField), findsWidgets);

    // The login button text.
    expect(find.text('Se connecter'), findsOneWidget);

    // The screen title.
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('LoginScreen shows the correct role label for "doctor"',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(role: 'doctor'),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Médecin'), findsOneWidget);
  });
}
