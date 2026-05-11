# MediCare

> Application mobile de santé pour la Tunisie

[![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#licence)
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)

---

## À propos

**MediCare** est une application mobile de santé conçue pour le marché tunisien. Elle réunit dans une seule plateforme la prise de rendez-vous médicaux, le dossier médical numérique, la téléconsultation, le paiement en ligne et un assistant médical basé sur l'IA. L'application s'adresse aussi bien aux patients qu'aux médecins, avec un panneau d'administration pour la gestion des utilisateurs et la supervision de la plateforme.

L'objectif est de simplifier le parcours de soins : un patient peut prendre rendez-vous, consulter son dossier, payer ses factures et discuter avec son médecin sans quitter l'application. Côté médecin, l'outil regroupe le planning, les dossiers patients, la rédaction d'ordonnances et un assistant IA d'aide à la décision (résumé patient, suggestions diagnostiques).

---

## Fonctionnalités

### Patient
- Prise de rendez-vous en ligne (recherche de médecins, créneaux disponibles)
- Dossier médical consultable (antécédents, allergies, traitements)
- Ordonnances numériques avec historique
- Factures et paiement en ligne via Stripe
- Messagerie temps réel avec les soignants
- Téléconsultation vidéo via Jitsi Meet
- Assistant médical IA (triage de symptômes, questions santé)
- Notifications de rappel pour les rendez-vous et la prise de médicaments

### Médecin
- Planning et calendrier des consultations
- Accès aux dossiers patients
- Création et signature d'ordonnances
- Création et mise à jour des dossiers médicaux
- AI Doctor : résumé automatique du patient, suggestions diagnostiques
- Centre de récupération (recovery center) pour le suivi post-consultation
- Messagerie patient
- Téléconsultation intégrée

### Admin
- Dashboard avec statistiques de la plateforme
- Gestion des utilisateurs (patients, médecins)
- Supervision des paiements et des factures
- Gestion des contenus et des configurations

---

## Stack technique

**Mobile (Flutter)**
- Flutter 3.24+ / Dart 3.4+
- Riverpod (state management)
- GoRouter (navigation déclarative)
- Dio (client HTTP)
- flutter_secure_storage (JWT, secrets)
- google_fonts, fl_chart, table_calendar, lottie (UI)

**Backend (Strapi)**
- Strapi v5
- Node.js 22+
- PostgreSQL (production) / SQLite (développement)
- Authentification JWT (users-permissions)

**Services tiers**
- Stripe (paiements)
- Jitsi Meet (téléconsultation vidéo)
- Twilio (SMS / notifications)
- OpenAI (assistant IA patient et médecin)

---

## Architecture

L'application Flutter suit une **architecture feature-first**. Chaque domaine métier (auth, appointment, prescription, dossier médical, etc.) vit dans son propre dossier sous `lib/features/<feature>/` et contient ses propres couches : `data` (models, repositories), `providers` (Riverpod), `presentation` (screens, widgets). Le code partagé est dans `lib/core/` (constants, network, errors) et `lib/shared/` (widgets réutilisables).

Côté backend, Strapi v5 expose chaque entité métier comme une API REST (`/api/<resource>`). Les filtres suivent la syntaxe v5 (`filters[champ][$eq]=valeur`). Les comportements métier complexes (paiement Stripe, génération PDF, intégration OpenAI, notifications) sont implémentés comme des **moteurs custom** (engines) sous `src/api/<engine>-engine/` exposant des endpoints dédiés. Le tout est protégé par JWT et par les permissions configurables dans l'admin Strapi.

---

## Démarrage rapide

### Prérequis
- Flutter **3.24** ou supérieur ([guide d'installation](https://docs.flutter.dev/get-started/install))
- Node.js **22+** et npm
- Android Studio (SDK Android + émulateur) ou un appareil physique
- Un éditeur (VS Code recommandé avec l'extension Flutter)

### Backend (Strapi)
```bash
cd medicare-backend
npm install
npm run develop
```
Le backend démarre par défaut sur `http://localhost:1337`. L'interface admin est disponible sur `http://localhost:1337/admin`.

### Application Flutter
```bash
cd medicare
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:1337/api
```
> Sur émulateur Android, `10.0.2.2` est l'alias de la machine hôte. Sur appareil physique, remplacer par l'IP locale de la machine (par ex. `http://192.168.1.20:1337/api`).

---

## Comptes de test

Des comptes de démonstration (patient, médecin, admin) sont documentés dans `memory/test_accounts.md`. Le mot de passe partagé pour les comptes de seed est `Medicare2024!`.

Une fois le backend déployé, l'API publique sera disponible sur `https://medicare-api.fly.dev/api` (cf. `medicare-backend/DEPLOYMENT_FREE.md`).

---

## Variables d'environnement

Les valeurs sensibles ou dépendantes de l'environnement sont passées via `--dart-define` au moment du build :

| Variable | Description | Exemple |
|---|---|---|
| `API_URL` | URL de base de l'API Strapi | `https://medicare-api.fly.dev/api` |
| `STRIPE_PUBLISHABLE_KEY` | Clé publique Stripe (test ou live) | `pk_test_...` |

Exemple :
```bash
flutter run \
  --dart-define=API_URL=https://medicare-api.fly.dev/api \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx
```

Côté backend, créer un fichier `.env` dans `medicare-backend/` avec au minimum : `HOST`, `PORT`, `APP_KEYS`, `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, `DATABASE_*`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`. La clé `OPENAI_API_KEY` est optionnelle (IA désactivée par défaut). Pour les push notifications, ajouter `FIREBASE_SERVICE_ACCOUNT` (JSON sur une ligne — voir `docs/FCM_SETUP.md`).

---

## Build release

Un script de génération de keystore Android est fourni :
- Windows : `android/generate_keystore.bat`
- Unix : `android/generate_keystore.sh`

Une fois le keystore généré et `android/key.properties` configuré :
```bash
flutter build apk --release \
  --dart-define=API_URL=https://medicare-api.fly.dev/api \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx
```
Pour un App Bundle (Play Store) : `flutter build appbundle --release ...`.

---

## Tests

```bash
flutter analyze      # analyse statique (0 issue attendu)
flutter test         # tous les tests unitaires & widget tests
```

La suite couvre actuellement : les modèles (parsing JSON), les providers (settings, theme), un smoke test de l'écran de connexion et un test unitaire du repository des ordonnances (vérifie le format des filtres Strapi v5).

---

## Déploiement backend

**Déploiement 100% gratuit (recommandé)** : Fly.io + Neon (PostgreSQL serverless), aucun coût mensuel récurrent — voir `medicare-backend/DEPLOYMENT_FREE.md`.

Pour la mise en production de Stripe en mode **live**, voir `medicare/docs/STRIPE_LIVE_SETUP.md`.
Pour configurer les push notifications gratuitement, voir `medicare/docs/FCM_SETUP.md`.

---

## Structure du projet

```
medicare/
├── android/                  # Configuration Android (Gradle, keystore)
├── ios/                      # Configuration iOS
├── assets/                   # Images, icônes, animations Lottie
├── lib/
│   ├── app/                  # Bootstrap (app.dart, router.dart, theme.dart)
│   ├── core/                 # Constants, network (Dio), errors, utils
│   ├── shared/               # Widgets réutilisables (boutons, champs, etc.)
│   └── features/             # Modules métier (feature-first)
│       ├── auth/
│       ├── appointment/
│       ├── ai_assistant/
│       ├── ai_doctor/
│       ├── doctor/
│       ├── dossier/
│       ├── home/
│       ├── invoice/
│       ├── laboratory/
│       ├── medical_record/
│       ├── messaging/
│       ├── notification/
│       ├── payment/
│       ├── prescription/
│       ├── profile/
│       ├── recovery/
│       ├── schedule/
│       ├── settings/
│       └── teleconsultation/
├── test/                     # Tests unitaires & widget tests
├── docs/                     # Documentation technique (Stripe live, etc.)
└── pubspec.yaml
```

Chaque feature suit typiquement :
```
features/<feature>/
├── data/
│   ├── models/
│   └── repositories/
├── providers/
└── presentation/
    ├── screens/
    └── widgets/
```

---

## Contribuer

1. Forker le dépôt et créer une branche descriptive : `feat/nom-feature`, `fix/nom-bug`.
2. Respecter les conventions de commit ([Conventional Commits](https://www.conventionalcommits.org/fr/v1.0.0/)) :
   - `feat: ajoute la prise de rendez-vous récurrents`
   - `fix: corrige le crash au logout`
   - `docs: met à jour le README`
   - `refactor: …`, `test: …`, `chore: …`
3. Avant de pousser : `flutter analyze` doit être à 0 issue et `flutter test` doit passer.
4. Ouvrir une Pull Request vers `main` avec une description claire (contexte, captures d'écran si UI, étapes de test).
5. La CI doit être verte avant merge.

---

## Licence

Distribué sous licence **MIT**. Voir le fichier `LICENSE` (à ajouter) pour le texte complet.

---

## Auteur

**Karim Ben** — étudiant développeur, projet de fin d'études.

Contributions, suggestions et retours sont les bienvenus via les Issues GitHub.
