#!/bin/bash
# ============================================================
# Medicare — Build APK release Flutter (one-shot)
#
# Usage :
#   cd "/c/Users/kba/Desktop/Medicare Flutter/medicare"
#   bash build_apk.sh
#
# Prérequis :
#   - Le backend doit être déployé sur https://medicare-api.fly.dev
#   - Le keystore doit être généré (android/medicare-release.jks)
#     ET le fichier android/key.properties doit exister
#
# Sortie :
#   - APK signé : build/app/outputs/flutter-apk/app-release.apk
#   - Symboles debug : build/symbols/ (à garder pour dé-obfusquer les crashs)
# ============================================================

set -e

echo "──────────────────────────────────────────────────────"
echo " Medicare APK Release Build"
echo "──────────────────────────────────────────────────────"

# 1. Vérifier qu'on est dans le bon dossier
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Erreur : ce script doit être exécuté depuis medicare/ (dossier Flutter)"
  exit 1
fi

# 2. Vérifier le keystore (optionnel — on permet build debug si absent)
USE_RELEASE=true
if [ ! -f "android/key.properties" ] || [ ! -f "android/medicare-release.jks" ]; then
  echo "⚠️  Pas de keystore release (android/key.properties + medicare-release.jks)"
  echo "    → Build en mode DEBUG (non signé, non obfusqué)"
  echo "    Pour générer un keystore : cd android && ./generate_keystore.bat"
  USE_RELEASE=false
fi

# 3. Variables d'env
API_URL="https://medicare-api.fly.dev/api"
STRIPE_PK="pk_test_51TUy6XGluWQfV3EVtnMGuTs4NHtNTTPlgXyJKqiM0YRa0W2H1gnu1UkTpugYWdoDByddqd4DwZYnySCY5aXJcQHc00haKSYR9F"

echo ""
echo "Configuration :"
echo "  API_URL                 = $API_URL"
echo "  STRIPE_PUBLISHABLE_KEY  = ${STRIPE_PK:0:20}..."
echo "  AI_ENABLED              = false (par défaut)"
echo ""

# 4. flutter pub get
echo "📦 flutter pub get..."
flutter pub get

# 5. flutter clean (recommandé avant un build release)
echo ""
echo "🧹 flutter clean..."
flutter clean
flutter pub get

# 6. Build
echo ""
if [ "$USE_RELEASE" = true ]; then
  echo "🚀 Build APK RELEASE (signé + obfusqué)..."
  flutter build apk --release \
    --obfuscate \
    --split-debug-info=build/symbols \
    --dart-define=API_URL="$API_URL" \
    --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_PK"
else
  echo "🛠️  Build APK DEBUG..."
  flutter build apk --debug \
    --dart-define=API_URL="$API_URL" \
    --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_PK"
fi

# 7. Localiser l'APK
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
[ ! -f "$APK_PATH" ] && APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

echo ""
echo "──────────────────────────────────────────────────────"
echo " ✅ Build terminé"
echo "──────────────────────────────────────────────────────"
echo ""
echo " APK : $APK_PATH"
echo " Taille : $(du -h "$APK_PATH" 2>/dev/null | cut -f1)"
echo ""
echo " Pour installer sur l'émulateur :"
echo "   adb install -r $APK_PATH"
echo ""
echo " Pour distribuer via GitHub Releases :"
echo "   gh release create v1.0.0 $APK_PATH --title 'Medicare v1.0.0'"
echo ""
