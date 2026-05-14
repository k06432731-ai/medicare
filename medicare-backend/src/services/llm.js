'use strict';

/**
 * Service LLM partagé — utilisé par les engines ai-assistant et ai-doctor.
 *
 * Compatible avec tout fournisseur exposant une API « OpenAI-compatible »
 * (/chat/completions). Configuration via variables d'environnement :
 *
 *   LLM_API_KEY    Clé API du fournisseur. À défaut, OPENAI_API_KEY est lu.
 *   LLM_BASE_URL   URL de base de l'API. Défaut : https://api.openai.com/v1
 *   LLM_MODEL      Identifiant du modèle. Défaut : gpt-4o-mini
 *
 * Exemples de configuration :
 *
 *   --- OpenAI (payant) ---
 *   LLM_API_KEY=sk-...
 *   LLM_BASE_URL=https://api.openai.com/v1
 *   LLM_MODEL=gpt-4o-mini
 *
 *   --- Groq (gratuit, recommandé) ---
 *   LLM_API_KEY=gsk_...
 *   LLM_BASE_URL=https://api.groq.com/openai/v1
 *   LLM_MODEL=llama-3.3-70b-versatile
 *
 * Voir docs/AI_SETUP.md pour le détail.
 */

function llmConfig() {
  const apiKey = process.env.LLM_API_KEY || process.env.OPENAI_API_KEY || '';
  const baseUrl = (process.env.LLM_BASE_URL || 'https://api.openai.com/v1')
    .replace(/\/+$/, '');
  const model = process.env.LLM_MODEL || process.env.OPENAI_MODEL || 'gpt-4o-mini';
  return { apiKey, baseUrl, model };
}

/** Indique si un fournisseur LLM est configuré. */
function isLLMConfigured() {
  const { apiKey } = llmConfig();
  return Boolean(apiKey) && !apiKey.startsWith('sk-REMPLACER');
}

/**
 * Appelle le LLM avec une liste de messages [{role, content}].
 * Retourne directement le contenu texte de la réponse.
 */
async function callLLM(messages, { temperature = 0.5, maxTokens = 700 } = {}) {
  const { apiKey, baseUrl, model } = llmConfig();

  if (!isLLMConfigured()) {
    throw new Error(
      "Aucune clé LLM configurée côté serveur (LLM_API_KEY ou OPENAI_API_KEY). " +
      "Voir docs/AI_SETUP.md."
    );
  }

  const res = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ model, messages, temperature, max_tokens: maxTokens }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message || `LLM HTTP ${res.status}`);
  }

  const data = await res.json();
  return data.choices[0].message.content;
}

/** Extrait le premier objet JSON valide d'une réponse texte. */
function extractJson(raw) {
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('Réponse JSON non trouvée dans la réponse du modèle.');
  return JSON.parse(match[0]);
}

module.exports = { callLLM, extractJson, isLLMConfigured };
