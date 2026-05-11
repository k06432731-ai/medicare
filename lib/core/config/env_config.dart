/// Configuration par environnement via --dart-define.
///
/// Lancement dev  : flutter run --dart-define=API_URL=http://10.0.2.2:1337/api
/// Lancement prod : flutter run --release --dart-define=API_URL=https://ton-domaine.com/api
///
/// Pour activer les fonctionnalités IA (désactivées par défaut) :
///   flutter run --dart-define=AI_ENABLED=true
/// (Une clé OPENAI_API_KEY doit également être configurée côté backend.)
class EnvConfig {
  EnvConfig._();

  // ── URL du backend Strapi ────────────────────────────────────────────────
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:1337/api', // Android emulator par défaut
  );

  // ── Flag IA (désactivé par défaut, gratuit sans OpenAI) ─────────────────
  // Quand false, les boutons / cartes IA ne s'affichent pas dans l'UI.
  static bool get aiEnabled =>
      const bool.fromEnvironment('AI_ENABLED', defaultValue: false);

  // ── Helpers ─────────────────────────────────────────────────────────────
  static bool get isProduction => !apiUrl.contains('10.0.2.2') &&
      !apiUrl.contains('localhost');
}
