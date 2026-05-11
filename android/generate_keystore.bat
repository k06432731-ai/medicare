@echo off
REM ============================================================
REM  Medicare Android Release Keystore Generator (Windows)
REM ============================================================
REM  Generates a release keystore for signing the Medicare app.
REM  You will be prompted interactively for passwords by keytool.
REM  DO NOT share or commit the generated .jks file.
REM ============================================================

setlocal

set KEYSTORE_FILE=%~dp0medicare-release.jks
set KEY_ALIAS=medicare

if exist "%KEYSTORE_FILE%" (
    echo.
    echo [ERROR] Keystore already exists at: %KEYSTORE_FILE%
    echo Remove it manually if you want to regenerate.
    echo.
    exit /b 1
)

where keytool >nul 2>nul
if errorlevel 1 (
    echo.
    echo [ERROR] keytool not found in PATH.
    echo Make sure a JDK is installed and JAVA_HOME\bin is on PATH.
    echo.
    exit /b 1
)

echo.
echo Generating release keystore at:
echo    %KEYSTORE_FILE%
echo.
echo You will be prompted for:
echo    1. A keystore password (remember it!)
echo    2. Your name and organization details
echo    3. A key password (you can press Enter to reuse the keystore password)
echo.

keytool -genkey -v ^
    -keystore "%KEYSTORE_FILE%" ^
    -keyalg RSA ^
    -keysize 2048 ^
    -validity 10000 ^
    -alias %KEY_ALIAS%

if errorlevel 1 (
    echo.
    echo [ERROR] Keystore generation failed.
    echo.
    exit /b 1
)

echo.
echo ============================================================
echo  Keystore generated successfully!
echo ============================================================
echo.
echo  IMPORTANT NEXT STEPS:
echo.
echo  1. NEVER commit medicare-release.jks to git.
echo     It is already covered by android/.gitignore (**/*.jks).
echo.
echo  2. Copy android/key.properties.template to android/key.properties
echo     and fill in your keystore and key passwords:
echo.
echo         storePassword=YOUR_KEYSTORE_PASSWORD
echo         keyPassword=YOUR_KEY_PASSWORD
echo         keyAlias=medicare
echo         storeFile=medicare-release.jks
echo.
echo  3. BACK UP the keystore in a password manager (1Password,
echo     Bitwarden, etc.). If you lose it, you will NOT be able
echo     to publish updates to your app on the Play Store.
echo.
echo ============================================================

endlocal
