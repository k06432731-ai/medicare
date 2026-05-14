/// Configuration par environnement via --dart-define.
///
/// Lancement dev  : flutter run --dart-define=API_URL=http://10.0.2.2:1337/api
/// Lancement prod : flutter run --release --dart-define=API_URL=https://ton-domaine.com/api
///
/// Les fonctionnalités IA (assistant patient + outils IA médecin) sont
/// ACTIVÉES par défaut. Pour les désactiver ponctuellement :
///   flutter run --dart-define=AI_ENABLED=false
/// Une clé LLM doit être configurée côté backend (OPENAI_API_KEY) — voir
/// docs/AI_SETUP.md pour les options gratuites (Groq, Google Gemini).
class EnvConfig {
  EnvConfig._();

  // ── URL du backend Strapi ────────────────────────────────────────────────
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:1337/api', // Android emulator par défaut
  );

  // ── Flag IA (activé par défaut) ─────────────────────────────────────────
  // Quand false, les boutons / cartes IA ne s'affichent pas dans l'UI.
  static bool get aiEnabled =>
      const bool.fromEnvironment('AI_ENABLED', defaultValue: true);

  // ── Helpers ─────────────────────────────────────────────────────────────
  static bool get isProduction => !apiUrl.contains('10.0.2.2') &&
      !apiUrl.contains('localhost');
}
