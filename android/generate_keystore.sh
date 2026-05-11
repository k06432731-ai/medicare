#!/usr/bin/env bash
# ============================================================
#  Medicare Android Release Keystore Generator (bash)
# ============================================================
#  Generates a release keystore for signing the Medicare app.
#  You will be prompted interactively for passwords by keytool.
#  DO NOT share or commit the generated .jks file.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE_FILE="${SCRIPT_DIR}/medicare-release.jks"
KEY_ALIAS="medicare"

if [ -f "${KEYSTORE_FILE}" ]; then
    echo ""
    echo "[ERROR] Keystore already exists at: ${KEYSTORE_FILE}"
    echo "Remove it manually if you want to regenerate."
    echo ""
    exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
    echo ""
    echo "[ERROR] keytool not found in PATH."
    echo "Make sure a JDK is installed and JAVA_HOME/bin is on PATH."
    echo ""
    exit 1
fi

echo ""
echo "Generating release keystore at:"
echo "    ${KEYSTORE_FILE}"
echo ""
echo "You will be prompted for:"
echo "    1. A keystore password (remember it!)"
echo "    2. Your name and organization details"
echo "    3. A key password (you can press Enter to reuse the keystore password)"
echo ""

keytool -genkey -v \
    -keystore "${KEYSTORE_FILE}" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "${KEY_ALIAS}"

echo ""
echo "============================================================"
echo " Keystore generated successfully!"
echo "============================================================"
echo ""
echo " IMPORTANT NEXT STEPS:"
echo ""
echo " 1. NEVER commit medicare-release.jks to git."
echo "    It is already covered by android/.gitignore (**/*.jks)."
echo ""
echo " 2. Copy android/key.properties.template to android/key.properties"
echo "    and fill in your keystore and key passwords:"
echo ""
echo "        storePassword=YOUR_KEYSTORE_PASSWORD"
echo "        keyPassword=YOUR_KEY_PASSWORD"
echo "        keyAlias=medicare"
echo "        storeFile=medicare-release.jks"
echo ""
echo " 3. BACK UP the keystore in a password manager (1Password,"
echo "    Bitwarden, etc.). If you lose it, you will NOT be able"
echo "    to publish updates to your app on the Play Store."
echo ""
echo "============================================================"
