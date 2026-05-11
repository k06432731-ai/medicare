#!/bin/bash
# ============================================================
# Medicare — Script de déploiement Fly.io (one-shot)
#
# Usage :
#   cd "/c/Users/kba/Desktop/Medicare Flutter/medicare/medicare-backend"
#   bash deploy.sh
#
# Ce script :
#   1. Nettoie les anciens secrets Konnect
#   2. Pousse tous les secrets nécessaires (Strapi, Neon, Stripe, FCM)
#   3. Crée le volume persistant si manquant
#   4. Lance fly deploy
# ============================================================

set -e  # exit on any error

echo "──────────────────────────────────────────────────────"
echo " Medicare deploy → Fly.io"
echo "──────────────────────────────────────────────────────"

# 1. Vérifier qu'on est dans le bon dossier
if [ ! -f "fly.toml" ] || [ ! -f "Dockerfile" ]; then
  echo "❌ Erreur : ce script doit être exécuté depuis medicare-backend/"
  echo "    Lance : cd \"/c/Users/kba/Desktop/Medicare Flutter/medicare/medicare-backend\""
  exit 1
fi

# 2. Vérifier que flyctl est installé
if ! command -v fly &> /dev/null; then
  echo "❌ Erreur : flyctl n'est pas installé."
  echo "    Installe-le : curl -L https://fly.io/install.sh | sh"
  exit 1
fi

# 3. Préparer le service account Firebase (single-line JSON)
SA_FILE="C:/Users/kba/AppData/Local/Temp/fcm_sa.txt"
if [ ! -f "$SA_FILE" ]; then
  echo "❌ Erreur : le fichier service account Firebase est introuvable : $SA_FILE"
  echo "    Régénère-le avec :"
  echo "    node -e \"const fs=require('fs'); fs.writeFileSync('$SA_FILE', JSON.stringify(JSON.parse(fs.readFileSync('C:/Users/kba/Downloads/medicare-cc897-firebase-adminsdk-fbsvc-35c7decb73.json','utf8'))));\""
  exit 1
fi
FIREBASE_SA=$(cat "$SA_FILE")

# 4. Nettoyer les anciens secrets Konnect (silencieusement si absents)
echo ""
echo "🧹 Suppression des anciens secrets Konnect..."
fly secrets unset KONNECT_API_KEY KONNECT_WALLET_ID KONNECT_BASE_URL 2>/dev/null || true

# 5. Pousser tous les secrets en une seule commande (atomique)
echo ""
echo "🔐 Push des secrets (Strapi + Neon + Stripe + Firebase)..."
fly secrets set \
  APP_KEYS="boXpS6xRbxKNMo0xWuVE1Q==,0fHAF13q2tZpUs5vxnC4zg==,iizoK2Me/LhlGtQYisa9pQ==,T4VFdrByjUr9rZ3t34/nHQ==" \
  API_TOKEN_SALT="ZuH1Be3tnjtGDKjoCm9Yog==" \
  ADMIN_JWT_SECRET="OKc33RAn5iSNfjbe1HPlwA==" \
  TRANSFER_TOKEN_SALT="/WRQQ2YdCISfS9iKZGtyxw==" \
  ENCRYPTION_KEY="kXaSPD+DabsTZkQVaaPR8A==" \
  JWT_SECRET="49qa6++w3mldmRCgjfxj7g==" \
  DATABASE_CLIENT="postgres" \
  DATABASE_HOST="ep-flat-field-alidmwlu.c-3.eu-central-1.aws.neon.tech" \
  DATABASE_PORT="5432" \
  DATABASE_NAME="neondb" \
  DATABASE_USERNAME="neondb_owner" \
  DATABASE_PASSWORD="npg_XQem3JIFSYt1" \
  DATABASE_SSL="true" \
  STRIPE_SECRET_KEY="sk_test_51TUy6XGluWQfV3EVGcvxyA3av1cOkLj6Re3LJljWV2ktTOkVfQDHMRcAmdjlCfYlwtbrb24vPiWzX3b72NoqjFqY00rHT1tmCN" \
  STRIPE_WEBHOOK_SECRET="whsec_W5akk4cUcU70ckxg3Tccb2KPZrLwBZhS" \
  STRIPE_CURRENCY="eur" \
  FIREBASE_SERVICE_ACCOUNT="$FIREBASE_SA" \
  PUBLIC_URL="https://medicare-api.fly.dev" \
  NODE_ENV="production"

# 6. Créer le volume s'il n'existe pas
echo ""
echo "💾 Vérification du volume persistant..."
if ! fly volumes list | grep -q "medicare_uploads"; then
  fly volumes create medicare_uploads --size 1 --region cdg --yes
else
  echo "   → volume medicare_uploads déjà créé, OK"
fi

# 7. Déployer !
echo ""
echo "🚀 Déploiement..."
fly deploy

echo ""
echo "──────────────────────────────────────────────────────"
echo " ✅ Déploiement terminé"
echo "──────────────────────────────────────────────────────"
echo ""
echo " Backend URL : https://medicare-api.fly.dev"
echo " Admin Strapi : https://medicare-api.fly.dev/admin"
echo ""
echo " Test rapide :"
echo "   curl https://medicare-api.fly.dev/api/admin-stats"
echo "   → Devrait retourner 403 (auth required) = OK"
echo ""
echo " ⚠️  À FAIRE APRÈS le premier déploiement réussi :"
echo "   1. Aller sur https://medicare-api.fly.dev/admin créer le super-admin"
echo "   2. Reconfigurer l'URL du webhook Stripe vers https://medicare-api.fly.dev/api/stripe-engine/webhook"
echo "   3. Builder l'APK release avec :"
echo "      cd \"/c/Users/kba/Desktop/Medicare Flutter/medicare\" && bash build_apk.sh"
echo "   4. Sécurité : rotater les clés Neon + Firebase + Stripe partagées en chat"
echo ""
