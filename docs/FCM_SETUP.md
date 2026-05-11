# Firebase Cloud Messaging (FCM) — Setup Guide

Ce projet utilise **FCM** pour les notifications push (Sprint 20). Les fichiers
de configuration Firebase (`google-services.json`, `GoogleService-Info.plist`,
clé service account) ne sont **pas** committés — vous devez les générer
vous-même via la console Firebase.

Des fichiers placeholder existent déjà à la place :

- `android/app/google-services.json` (placeholder + template `.template`)
- `ios/Runner/GoogleService-Info.plist` (placeholder + template `.template`)

Tant que ces placeholders sont en place, l'app démarre quand même : `FcmService.init()`
attrape l'erreur d'initialisation et retourne `null` au lieu de crasher.

---

## 1. Créer un projet Firebase (gratuit)

- Aller sur https://console.firebase.google.com/
- Créer un projet "medicare-prod"
- Activer **Cloud Messaging (FCM)** dans le menu Build → Cloud Messaging

## 2. Android setup

- Project Settings → Add app → Android
- Package name : `com.example.medicare`
  (vérifier dans `android/app/build.gradle.kts` → `applicationId`)
- Télécharger `google-services.json`
- Remplacer le placeholder : `medicare/android/app/google-services.json`

Le plugin Gradle est déjà configuré (`com.google.gms.google-services` dans
`android/settings.gradle.kts` et `android/app/build.gradle.kts`).

## 3. iOS setup

- Project Settings → Add app → iOS
- Bundle ID : `com.example.medicare`
- Télécharger `GoogleService-Info.plist`
- Remplacer le placeholder : `medicare/ios/Runner/GoogleService-Info.plist`
- Xcode → Runner target → Signing & Capabilities → ajouter **Push Notifications**

## 4. Backend setup (envoi de push)

- Project Settings → **Service Accounts** → "Generate new private key"
  → télécharger le JSON
- Convertir le JSON en une ligne (utiliser `jq -c .` ou `JSON.stringify`)
- Configurer la variable d'environnement `FIREBASE_SERVICE_ACCOUNT` :

  **Fly.io (prod)** :
  ```
  fly secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
  ```

  **Strapi local (dev)** : ajouter dans `medicare-backend/.env` :
  ```
  FIREBASE_SERVICE_ACCOUNT='{...}'
  ```

- Installer la dépendance backend : `cd medicare-backend && npm install`
  (déjà ajoutée à `package.json` : `firebase-admin: 12.7.0`)

## 5. Builder l'app avec FCM activé

- Android : `flutter build apk --release`
  (le plugin Google Services s'occupe d'intégrer `google-services.json`)
- iOS : Xcode → Push Notifications activé dans Signing & Capabilities

## 6. Tester

1. Lancer l'app (login pour déclencher `registerFcmToken`)
2. Vérifier dans les logs que le token FCM a bien été obtenu
   (cherche `FCM Token: ...`)
3. Console Firebase → Cloud Messaging → "Send test message" →
   coller le token loggé → envoyer
4. Le push doit arriver sur l'appareil

Pour tester depuis le backend, créer une notification (RDV, message, etc.) — la
fonction `notify()` envoie aussi un push FCM si l'utilisateur a un `fcmToken`.

## 7. Sécurité

- **NE PAS** committer `google-services.json` ni `GoogleService-Info.plist`
  (déjà gitignorés)
- **NE PAS** committer la clé service account
- Restreindre l'utilisation de l'API key Firebase aux package names attendus
  (Firebase Console → Project Settings → API restrictions)

## 8. Workflow .template

Pour qu'un dev qui clone le repo n'ait pas un build cassé, deux fichiers
`.template` sont committés à côté des fichiers réels (ignorés) :

- `android/app/google-services.json.template`
- `ios/Runner/GoogleService-Info.plist.template`

Au premier setup : copier le `.template` vers le nom réel (sans `.template`),
puis remplacer le contenu par le vrai fichier téléchargé depuis Firebase.
