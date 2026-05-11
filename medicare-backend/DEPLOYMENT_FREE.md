# Déploiement 100% gratuit — Medicare (Fly.io + Neon)

> Guide complet pour mettre Medicare en production sans aucun coût mensuel récurrent.
> Cible : projet de fin d'études / beta privée / petite communauté d'utilisateurs.

---

## Section 1 — Vue d'ensemble du stack gratuit

| Composant | Service | Limite gratuite | Si on dépasse |
|---|---|---|---|
| Backend (Strapi) | **Fly.io** | 3 VMs shared-cpu-1x 256MB, 160GB bandwidth/mois, scale-to-zero | ~1,94 $/mois pour 256MB always-on |
| Base de données | **Neon.tech** (PostgreSQL serverless) | 0,5 GB stockage, 191h compute/mois, branches illimitées | 19 $/mois (Launch plan) |
| Domaine + HTTPS | `medicare-api.fly.dev` | Sous-domaine Fly + cert TLS Let's Encrypt auto | Acheter un .tn (~30 $/an) si besoin |
| Distribution APK | **GitHub Releases** | Illimité pour repo public, 2 GB/fichier | — |
| Push notifications | **Firebase Cloud Messaging** | Illimité, gratuit | — |
| Crash reporting | **Sentry** free tier | 5 000 événements/mois, 1 utilisateur | 26 $/mois (Team) |
| Paiement | **Stripe** (test mode gratuit illimité) | 1,4 % + 0,25 € par paiement réussi en mode live | Stripe Atlas si KYC TN refusé (~500 $/once) |
| Uptime monitoring | **Better Stack** (optionnel) | 10 monitors, ping 3 min | 18 $/mois |
| Email transactionnel | Skip — utiliser FCM push à la place | — | Resend free : 3000/mois |
| SMS | Remplacé par FCM push notifications | — | — |

**Coût total mensuel : 0,00 $** tant qu'on reste dans les quotas.

---

## Section 2 — Prérequis (tout gratuit)

- **GitHub** : compte gratuit ([github.com](https://github.com))
- **Fly.io** : créer un compte sur [fly.io/app/sign-up](https://fly.io/app/sign-up)
  Une carte bancaire est demandée pour vérification anti-fraude mais Fly ne facture rien tant que tu restes dans le free tier.
- **Neon** : créer un compte sur [neon.tech](https://neon.tech) (aucune CB demandée)
- **Stripe** : créer un compte sur [stripe.com](https://stripe.com) (mode test gratuit illimité)
- **Firebase** (pour FCM) : [console.firebase.google.com](https://console.firebase.google.com)
- **Sentry** (optionnel) : [sentry.io](https://sentry.io)

### Installation de `flyctl`

**Windows PowerShell :**
```powershell
iwr https://fly.io/install.ps1 -useb | iex
```

**macOS / Linux / Git Bash :**
```bash
curl -L https://fly.io/install.sh | sh
```

Puis vérifier :
```bash
fly version
```

---

## Section 3 — Étape 1 : Créer la base PostgreSQL sur Neon

1. Aller sur [console.neon.tech](https://console.neon.tech) → **New Project**.
2. Nom du projet : `medicare`.
3. Région : **Frankfurt (EU Central)** — la plus proche de la Tunisie et de Paris (où tournera Fly).
4. Version Postgres : **16** (par défaut).
5. Après création, copier la **connection string** depuis le dashboard :
   ```
   postgres://medicare_owner:XXXXX@ep-cool-snow-12345.eu-central-1.aws.neon.tech/medicare?sslmode=require
   ```
6. Décomposer cette URL pour les variables Strapi :
   - `DATABASE_HOST` = `ep-cool-snow-12345.eu-central-1.aws.neon.tech`
   - `DATABASE_PORT` = `5432`
   - `DATABASE_NAME` = `medicare`
   - `DATABASE_USERNAME` = `medicare_owner`
   - `DATABASE_PASSWORD` = `XXXXX`
   - `DATABASE_SSL` = `true`

> Astuce : Neon coupe automatiquement le compute après 5 min d'inactivité (cold start ~500 ms au prochain hit). C'est ce qui te permet de rester gratuit.

---

## Section 4 — Étape 2 : Générer les secrets Strapi

Sur ta machine locale, dans n'importe quel terminal avec Node 22+ :

```bash
node -e "console.log('APP_KEYS=' + Array.from({length:4},()=>require('crypto').randomBytes(16).toString('base64')).join(','))"
node -e "console.log('API_TOKEN_SALT=' + require('crypto').randomBytes(16).toString('base64'))"
node -e "console.log('ADMIN_JWT_SECRET=' + require('crypto').randomBytes(16).toString('base64'))"
node -e "console.log('TRANSFER_TOKEN_SALT=' + require('crypto').randomBytes(16).toString('base64'))"
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('base64'))"
```

Coller chaque ligne dans un fichier `medicare-backend/.env.production` **local** — ce fichier ne doit JAMAIS être commit (il est déjà dans `.gitignore`). Il sert uniquement de référence pour la commande `fly secrets set` à l'étape suivante.

---

## Section 5 — Étape 3 : Déployer sur Fly.io

### 5.1 — Initialiser l'app Fly

```bash
cd medicare-backend
fly auth signup    # ou: fly auth login
fly launch --no-deploy
```

Pendant `fly launch`, répondre :
- **App name** : `medicare-api`
- **Region** : `cdg` (Paris) — déjà défini dans `fly.toml`
- **Set up a Postgres database now?** → **No** (on utilise Neon, son free tier est plus généreux)
- **Set up an Upstash Redis database?** → **No**
- **Override existing fly.toml?** → **No** (on garde le nôtre)

### 5.2 — Pousser tous les secrets

> Sur PowerShell, remplacer les `\` de fin de ligne par un backtick `` ` `` (continuation PowerShell), ou tout mettre sur une seule ligne.

**Git Bash / macOS / Linux :**
```bash
fly secrets set \
  APP_KEYS="key1,key2,key3,key4" \
  API_TOKEN_SALT="..." \
  ADMIN_JWT_SECRET="..." \
  TRANSFER_TOKEN_SALT="..." \
  JWT_SECRET="..." \
  DATABASE_HOST="ep-cool-snow-12345.eu-central-1.aws.neon.tech" \
  DATABASE_PORT="5432" \
  DATABASE_NAME="medicare" \
  DATABASE_USERNAME="medicare_owner" \
  DATABASE_PASSWORD="..." \
  DATABASE_SSL="true" \
  STRIPE_SECRET_KEY="sk_test_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  PUBLIC_URL="https://medicare-api.fly.dev" \
  OPENAI_API_KEY=""
```

**Windows PowerShell :**
```powershell
fly secrets set `
  APP_KEYS="key1,key2,key3,key4" `
  API_TOKEN_SALT="..." `
  ADMIN_JWT_SECRET="..." `
  TRANSFER_TOKEN_SALT="..." `
  JWT_SECRET="..." `
  DATABASE_HOST="ep-cool-snow-12345.eu-central-1.aws.neon.tech" `
  DATABASE_PORT="5432" `
  DATABASE_NAME="medicare" `
  DATABASE_USERNAME="medicare_owner" `
  DATABASE_PASSWORD="..." `
  DATABASE_SSL="true" `
  STRIPE_SECRET_KEY="sk_test_..." `
  STRIPE_WEBHOOK_SECRET="whsec_..." `
  PUBLIC_URL="https://medicare-api.fly.dev" `
  OPENAI_API_KEY=""
```

> Si l'IA n'est pas encore activée, laisser `OPENAI_API_KEY=""` (chaîne vide) — le backend doit savoir désactiver gracieusement les endpoints AI.

### 5.3 — Créer le volume persistant pour les uploads

Sans volume, les fichiers uploadés (avatars, ordonnances PDF) disparaissent à chaque redémarrage du VM.

```bash
fly volumes create medicare_uploads --size 1 --region cdg
```
(1 GB est le minimum, et reste dans le free tier — Fly offre 3 GB de stockage volumes gratuit cumulé.)

### 5.4 — Déployer

```bash
fly deploy
```

Le premier déploiement prend ~5-10 min (build Docker multi-stage + push image + boot machine).

### 5.5 — Vérifier

```bash
fly status
fly logs           # logs en streaming
curl https://medicare-api.fly.dev/_health
# {"status":"ok"} ou redirection 30x vers /admin
```

Tester un endpoint protégé :
```bash
curl -i https://medicare-api.fly.dev/api/admin-stats
# HTTP/2 401 ou 403  → parfait, l'API tourne et exige l'auth
```

---

## Section 6 — Étape 4 : Créer le super-admin Strapi

1. Ouvrir [https://medicare-api.fly.dev/admin](https://medicare-api.fly.dev/admin)
2. L'écran de **first-time setup** s'affiche (Strapi détecte une DB vide).
3. Créer le compte admin avec un mot de passe fort (~16 caractères, password manager recommandé).
4. Se connecter et vérifier :
   - **Settings → Roles** : les rôles `Patient`, `Doctor`, `Admin` sont présents.
   - **Content-Type Builder** : tous les types métier sont là.
5. Configurer les **permissions publiques** au minimum (auth/local/register, etc.) — cf. `medicare-backend/README.md` pour la liste précise.

---

## Section 7 — Étape 5 : Mettre à jour l'app Flutter

Tester d'abord en debug avec la nouvelle URL :
```bash
cd medicare
flutter run --dart-define=API_URL=https://medicare-api.fly.dev/api
```

Build release App Bundle (si un jour Play Store) :
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_URL=https://medicare-api.fly.dev/api
```

Build APK pour distribution directe :
```bash
flutter build apk --release \
  --dart-define=API_URL=https://medicare-api.fly.dev/api
```

L'APK sort dans `build/app/outputs/flutter-apk/app-release.apk`.

---

## Section 8 — Étape 6 : Distribuer l'APK gratuitement via GitHub Releases

1. Sur GitHub, naviguer vers le repo `medicare` → **Releases** → **Draft a new release**.
2. **Tag version** : `v1.0.0` (ou `v1.0.0-beta.1`)
3. **Target** : `main`
4. **Release title** : `MediCare v1.0.0`
5. Glisser `app-release.apk` dans la zone "Attach binaries".
6. **Publish release**.

Lien direct partageable (toujours la dernière version) :
```
https://github.com/<USERNAME>/medicare/releases/latest
```

Côté utilisateur Android :
1. Télécharger l'APK.
2. **Paramètres → Sécurité → Sources inconnues** (ou par appli : Chrome → autoriser).
3. Installer.

**Alternatives gratuites avec auto-update :**
- **F-Droid** : publication gratuite, mais review humaine (compter 2-4 semaines), exigeance de build 100% open source.
- **Obtainium** : permet à l'utilisateur de s'abonner aux releases GitHub et recevoir des notifs de mise à jour.
- **APKMirror** : hébergement gratuit, pas d'auto-update natif.

---

## Section 9 — Étape 7 : Monitoring gratuit

### Fly.io dashboard (inclus)
- [fly.io/apps/medicare-api](https://fly.io/apps/medicare-api) → logs en temps réel, metrics CPU/RAM, alerting basique.
- `fly logs` en CLI pour streaming.
- `fly status` pour l'état des machines.

### Sentry (optionnel mais recommandé)
1. Créer un projet sur [sentry.io](https://sentry.io) → choisir **Flutter**.
2. Copier le DSN.
3. Ajouter au `pubspec.yaml` : `sentry_flutter: ^8.0.0`.
4. Wrapper le `main()` :
   ```dart
   await SentryFlutter.init(
     (options) => options.dsn = const String.fromEnvironment('SENTRY_DSN'),
     appRunner: () => runApp(const MedicareApp()),
   );
   ```
5. Builder avec `--dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy`.

### Better Stack (optionnel)
- [betterstack.com/uptime](https://betterstack.com/uptime) → free tier : 10 monitors, ping toutes les 3 min.
- Ajouter un monitor sur `https://medicare-api.fly.dev/_health` → email/Slack en cas de downtime.

---

## Section 10 — Limites du free tier et comment rester dedans

| Service | Limite | Comment l'éviter |
|---|---|---|
| Fly.io VM | 3 × 256MB shared-cpu | `auto_stop_machines = true` dans `fly.toml` (déjà fait) : VM dort après 0 requête active |
| Fly.io bandwidth | 160 GB/mois | À 0,5 MB par requête API, ça fait 320 000 requêtes/mois. Largement OK pour une beta. |
| Fly.io volumes | 3 GB total | Surveiller `public/uploads`. Si ça explose, switch vers Cloudflare R2 (10 GB gratuits). |
| Neon storage | 0,5 GB | Purger les anciennes audit logs, compress avatars en WebP. |
| Neon compute | 191 h/mois | Le scale-to-zero de Neon gère ça tout seul. |
| Sentry events | 5 000/mois | Filtrer en `beforeSend` les erreurs non critiques. |
| GitHub Actions | 2 000 min/mois | Largement suffisant pour un CI simple. |
| Stripe | 1,4 % + 0,25 € par paiement live | Tests en `pk_test_*` 100 % gratuits, illimités. |

---

## Section 11 — Sauvegardes gratuites

### Neon (intégré)
- **Point-in-time recovery 24 h** inclus dans le free tier.
- **Branches** : tu peux créer une branche "snapshot" gratuite avant chaque migration risquée.

### Script `pg_dump` quotidien (optionnel)
Créer `medicare-backend/scripts/backup.sh` :
```bash
#!/usr/bin/env bash
set -e
DATE=$(date +%Y-%m-%d)
PGPASSWORD="$DATABASE_PASSWORD" pg_dump \
  -h "$DATABASE_HOST" -U "$DATABASE_USERNAME" -d "$DATABASE_NAME" \
  --no-owner --no-acl -F c -f "backup-$DATE.dump"
gh release create "backup-$DATE" "backup-$DATE.dump" --prerelease --notes "Auto backup"
rm "backup-$DATE.dump"
```
Lancé manuellement ou via GitHub Actions cron quotidien (gratuit) → upload vers une **GitHub Release privée** d'un repo `medicare-backups` (privé, gratuit).

---

## Section 12 — Si Fly.io devient payant ou indisponible

Alternatives 100 % gratuites équivalentes :

| Service | Avantage | Inconvénient |
|---|---|---|
| **Koyeb** | 1 service free forever 512MB, pas de scale-to-zero | 1 seul service gratuit |
| **Render** | Très simple à utiliser, déploiement git auto | Sleep après 15 min d'inactivité, cold start lent (~30 s) |
| **Oracle Cloud Free Tier** | 4 ARM CPUs + 24 GB RAM **gratuits à vie** (le plus généreux) | Setup plus technique (VM nue, install Docker, nginx, certbot soi-même) |
| **Northflank** | 1 service free, 512MB | Limites I/O |

Pour basculer depuis Fly : le `Dockerfile` est portable, il suffit de recréer la base Neon (ou la garder), pousser les secrets sur le nouveau provider, et changer `API_URL` dans le build Flutter.

---

## Commandes utiles (cheat sheet)

```bash
# Logs live
fly logs

# Redémarrer toutes les machines
fly machine restart

# Connexion SSH au container
fly ssh console

# Voir la liste des secrets (sans leur valeur)
fly secrets list

# Mettre à jour un secret
fly secrets set KEY="newvalue"

# Détruire et recréer (full reset — danger)
fly apps destroy medicare-api
```

---

## Checklist finale avant ouverture aux utilisateurs

- [ ] `fly status` affiche `started` et `healthy`
- [ ] `https://medicare-api.fly.dev/admin` charge correctement
- [ ] Compte super-admin créé, mot de passe stocké dans password manager
- [ ] Permissions Strapi configurées (public/auth/local/register OK)
- [ ] Volume `medicare_uploads` monté (`fly volumes list`)
- [ ] APK release uploadé sur GitHub Releases
- [ ] Lien d'install testé sur un téléphone Android tiers
- [ ] Sentry initialisé (si activé)
- [ ] Better Stack monitor actif (si activé)
- [ ] Backup Neon vérifié (au moins un PITR test réussi)
