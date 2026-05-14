# Configuration des assistants IA — MediCare

MediCare intègre deux fonctionnalités d'intelligence artificielle :

| Fonctionnalité | Acteur | Endpoints backend |
|----------------|--------|-------------------|
| **Assistant IA** (chat santé + triage des symptômes) | Patient | `POST /api/ai-assistant/chat`, `POST /api/ai-assistant/triage` |
| **Outils IA médecin** (résumé patient, brouillon d'ordonnance, suggestions diagnostiques) | Médecin | `POST /api/ai-doctor/summarize-patient`, `/prescription-draft`, `/diagnostic-suggestions` |

Le code (écrans Flutter + engines Strapi) est **entièrement implémenté**. Il ne
manque qu'**une clé API LLM** côté backend.

---

## 1. Quelle clé faut-il ?

Le backend appelle un modèle de langage via une API « OpenAI-compatible ».
Trois options :

| Fournisseur | Coût | Recommandation |
|-------------|------|----------------|
| **Groq** | **Gratuit** (quota généreux, très rapide) | ✅ Recommandé pour le PFE |
| **OpenAI** | Payant (~0,15 $/1M tokens, carte bancaire requise) | Si tu as déjà un compte |
| **Google Gemini** | Gratuit (quota limité) | Alternative |

> **Recommandation : Groq.** C'est gratuit, sans carte bancaire, et l'API est
> compatible OpenAI — aucune ligne de code à changer.

---

## 2. Procédure avec Groq (gratuit — recommandé)

1. Aller sur **https://console.groq.com** et créer un compte (Google/GitHub).
2. Menu **API Keys** → **Create API Key** → copier la clé (`gsk_...`).
3. Ouvrir `medicare-backend/.env` et renseigner :
   ```
   LLM_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxx
   LLM_BASE_URL=https://api.groq.com/openai/v1
   LLM_MODEL=llama-3.3-70b-versatile
   ```
4. Redémarrer le backend : `npm run develop`.

C'est tout. Les assistants IA sont opérationnels.

### En production (Fly.io)
```bash
fly secrets set \
  LLM_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxx" \
  LLM_BASE_URL="https://api.groq.com/openai/v1" \
  LLM_MODEL="llama-3.3-70b-versatile"
```

---

## 3. Procédure avec OpenAI (payant)

1. Aller sur **https://platform.openai.com/api-keys**, créer une clé (`sk-...`).
2. Ajouter un moyen de paiement (OpenAI ne donne plus de crédit gratuit).
3. Dans `medicare-backend/.env` :
   ```
   LLM_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
   LLM_BASE_URL=https://api.openai.com/v1
   LLM_MODEL=gpt-4o-mini
   ```
4. Redémarrer le backend.

---

## 4. Côté application Flutter

Les fonctionnalités IA sont **activées par défaut** (`EnvConfig.aiEnabled = true`).
Aucune action n'est requise. Pour les masquer ponctuellement (démo sans backend
IA configuré) :
```bash
flutter run --dart-define=AI_ENABLED=false
```

---

## 5. Comportement si aucune clé n'est configurée

Le backend ne plante pas : les endpoints IA renvoient une erreur explicite
(« Aucune clé LLM configurée côté serveur »). Côté application, l'utilisateur
voit un message d'erreur dans l'écran IA, le reste de l'application
fonctionne normalement.

---

## 6. Test rapide

Une fois la clé en place, tester l'endpoint chat :
```bash
# Récupérer un JWT
JWT=$(curl -s -X POST http://localhost:1337/api/auth/local \
  -H "Content-Type: application/json" \
  -d '{"identifier":"ahmed.benali@gmail.com","password":"Medicare2024!"}' \
  | grep -o '"jwt":"[^"]*"' | cut -d'"' -f4)

# Appeler l'assistant
curl -X POST http://localhost:1337/api/ai-assistant/chat \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"mode":"chat","messages":[{"role":"user","content":"J ai mal a la tete depuis hier"}]}'
```
Une réponse `{"data":{"reply":"..."}}` confirme que l'IA fonctionne.
