# Konnect — Configuration paiement Tunisie

Konnect est le gateway de paiement local utilisé par Medicare pour accepter
les paiements en TND (carte bancaire CIB, e-DINAR, wallet Konnect).

## 1. Inscription

- Aller sur https://konnect.network
- Créer un compte (gratuit). KYC simple pour la Tunisie (CIN + RIB
  professionnel ou personnel).
- Une fois validé, accès au dashboard.

## 2. Récupérer la clé API

- Dashboard → **Settings** → **API Keys**
- Copier la clé `x-api-key` (sandbox ET production sont des clés distinctes).

## 3. Récupérer le wallet ID

- Dashboard → **Wallet**
- Copier le `receiverWalletId` (identifie le compte destinataire des fonds).

## 4. Mode sandbox (pré-production)

Pour tester sans frais réels, utiliser l'environnement preprod :

- Dashboard sandbox : https://dashboard.preprod.konnect.network
- API base URL    : `https://api.preprod.konnect.network/api/v2`
- Cartes de test fournies par Konnect dans la doc dev :
  - `4000 0000 0000 0010` → succès
  - `4000 0000 0000 0028` → échec

## 5. Variables d'environnement

Dans `medicare-backend/.env` (dev) ou `fly secrets` (production) :

```
KONNECT_API_KEY=<votre clé API>
KONNECT_WALLET_ID=<votre wallet ID>
KONNECT_BASE_URL=https://api.preprod.konnect.network/api/v2
PUBLIC_URL=https://medicare.fly.dev
```

En production, remplacer la base URL par
`https://api.konnect.network/api/v2`.

## 6. Configurer le webhook

- Dashboard → **Settings** → **Webhooks**
- URL : `https://api.medicare.fly.dev/api/konnect-engine/webhook`
- Type : GET (silentWebhook=true → Konnect appelle l'URL avec `?payment_ref=xxx`)

Le backend vérifie ensuite le statut via l'API Konnect, donc le webhook
n'a pas besoin d'être signé.

## 7. Méthodes de paiement acceptées

Configurées dans le backend (`acceptedPaymentMethods`) :

- `bank_card` — Visa / Mastercard CIB (carte bancaire tunisienne)
- `e-DINAR` — Carte e-DINAR émise par la Poste Tunisienne
- `wallet` — Wallet Konnect (utilisateurs qui ont déjà un compte Konnect)

## 8. Frais Konnect

- ~2.5% par transaction réussie (à confirmer avec Konnect selon volume).
- Aucun frais fixe mensuel ni d'installation.
- Possibilité de répercuter les frais sur le client via
  `addPaymentFeesToAmount: true` (déjà activé côté backend).

## 9. Tester en sandbox

1. Lancer le backend avec `KONNECT_BASE_URL=https://api.preprod.konnect.network/api/v2`
2. Ouvrir l'app Flutter → écran Factures → "Régler la facture"
3. Choisir "Payer par carte / wallet (Konnect)"
4. La WebView ouvre `gateway.preprod.konnect.network`
5. Saisir une carte de test (cf. §4)
6. Vérifier la redirection vers `medicare://payment/success?ref=xxx`
7. La facture passe en `paid` et un reçu PDF est généré

## 10. Passer en production

1. Demander l'activation du mode "live" sur le dashboard Konnect (KYC complet)
2. Récupérer la clé API + wallet ID live
3. Mettre à jour les secrets Fly.io :
   ```
   fly secrets set KONNECT_API_KEY="<live key>" \
                   KONNECT_WALLET_ID="<live wallet>" \
                   KONNECT_BASE_URL="https://api.konnect.network/api/v2"
   ```
4. Re-deploy : `fly deploy`
5. Tester un paiement réel avec un petit montant (1 TND) avant de basculer.
