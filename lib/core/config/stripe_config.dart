/// Configuration Stripe.
/// Remplacez [publishableKey] par votre clé publique de test depuis
/// https://dashboard.stripe.com/test/apikeys
class StripeConfig {
  StripeConfig._();

  // Test key — inoffensive, ne charge rien en sandbox
  static const String publishableKey =
      'pk_test_51TUy6XGluWQfV3EVtnMGuTs4NHtNTTPlgXyJKqiM0YRa0W2H1gnu1UkTpugYWdoDByddqd4DwZYnySCY5aXJcQHc00haKSYR9F';

  // Scheme utilisé pour les redirections 3DS (doit correspondre à AndroidManifest + Info.plist)
  static const String returnUrl = 'medicare://stripe-return';

  static const String merchantName = 'Medicare';
}
