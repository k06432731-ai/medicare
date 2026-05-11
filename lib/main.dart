import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/config/stripe_config.dart';
import 'core/services/fcm_service.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Stripe — set publishable key only if configured (--dart-define).
  // Without a key the Stripe button stays disabled, app still launches.
  if (StripeConfig.isConfigured) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  // Firebase Cloud Messaging (Sprint 20)
  // Wrapped in try/catch: if google-services.json is still a placeholder,
  // FcmService.init() returns null and the app still launches.
  try {
    await FcmService.init();
  } catch (_) {
    // ignored — app still launches without push notifications
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MedicareApp(),
    ),
  );
}
