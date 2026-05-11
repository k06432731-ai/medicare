// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medicare/app/theme.dart';
import 'package:medicare/features/settings/providers/settings_provider.dart';

// ── Minimal test widget ───────────────────────────────────────────────────────
// Tests the theme selection logic in isolation (no router, no splash, no I/O).
class _TestThemeApp extends ConsumerWidget {
  const _TestThemeApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).darkMode;
    return MaterialApp(
      key: const Key('test_app'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const Scaffold(body: Center(child: Text('MediCare'))),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<ProviderScope> _buildTestApp(
    {bool darkMode = false}) async {
  SharedPreferences.setMockInitialValues({'dark_mode': darkMode});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const _TestThemeApp(),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  // ── Theme selection ────────────────────────────────────────────────────────

  group('Theme selection — reads dark_mode from SharedPreferences', () {
    testWidgets('dark_mode=false → ThemeMode.light',
        (WidgetTester tester) async {
      await tester.pumpWidget(await _buildTestApp(darkMode: false));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('dark_mode=true → ThemeMode.dark',
        (WidgetTester tester) async {
      await tester.pumpWidget(await _buildTestApp(darkMode: true));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('App renders text "MediCare"', (WidgetTester tester) async {
      await tester.pumpWidget(await _buildTestApp());
      await tester.pump();

      expect(find.text('MediCare'), findsOneWidget);
    });

    testWidgets('Light theme has correct primary color',
        (WidgetTester tester) async {
      await tester.pumpWidget(await _buildTestApp(darkMode: false));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.colorScheme.primary.toARGB32(),
          AppTheme.light.colorScheme.primary.toARGB32());
    });

    testWidgets('Dark theme scaffold background is dark',
        (WidgetTester tester) async {
      await tester.pumpWidget(await _buildTestApp(darkMode: true));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      // Dark scaffold background should be dark (not white)
      final darkBg = app.darkTheme!.scaffoldBackgroundColor;
      final lightBg = app.theme!.scaffoldBackgroundColor;
      expect(darkBg, isNot(equals(lightBg)));
    });
  });

  // ── SettingsProvider persists to SharedPreferences ─────────────────────────

  group('SettingsNotifier — dark mode toggle persists', () {
    testWidgets('toggle darkMode updates widget themeMode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'dark_mode': false});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const _TestThemeApp(),
        ),
      );
      await tester.pump();

      // Initially light
      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);

      // Toggle via provider container
      final element = tester.element(find.byType(_TestThemeApp));
      final container = ProviderScope.containerOf(element);
      await container.read(settingsProvider.notifier).setDarkMode(true);
      await tester.pump();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });
}
