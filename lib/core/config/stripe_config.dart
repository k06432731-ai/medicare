/// Configuration Stripe — lue via --dart-define au build.
///
/// Mode test (par défaut) :
///   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
///
/// Mode production :
///   flutter build apk --release \
///     --dart-define=API_URL=https://medicare-api.fly.dev/api \
///     --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx
///
/// La clé secrète (`sk_live_*`) reste exclusivement côté backend dans les
/// secrets Fly.io — JAMAIS dans l'app mobile.
class StripeConfig {
  StripeConfig._();

  /// Clé publique Stripe (peut être visible côté client sans risque).
  /// Vide par défaut → bouton Stripe désactivé tant qu'aucune clé n'est fournie.
  static const String publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Nom affiché dans la PaymentSheet native Stripe.
  static const String merchantName = 'MediCare';

  /// URL de retour après authentification 3D-Secure (deep link).
  /// Doit correspondre à l'intent-filter `medicare://` dans AndroidManifest
  /// et CFBundleURLSchemes dans Info.plist.
  static const String returnUrl = 'medicare://stripe-return';

  /// True si une clé publique est configurée → on peut afficher l'option Stripe.
  static bool get isConfigured => publishableKey.isNotEmpty;
}
