'use strict';

// Helper : vérifie le JWT et retourne l'utilisateur, ou null
async function getAuthUser(ctx) {
  try {
    const bearer = ctx.request.headers.authorization || '';
    const token = bearer.startsWith('Bearer ') ? bearer.slice(7) : null;
    if (!token) return null;

    const jwt = require('jsonwebtoken');
    const secret = process.env.JWT_SECRET;
    const payload = jwt.verify(token, secret);

    return await strapi.entityService.findOne(
      'plugin::users-permissions.user',
      payload.id
    );
  } catch (_) {
    return null;
  }
}

// Service LLM partagé (compatible OpenAI / Groq / Gemini — voir
// src/services/llm.js et docs/AI_SETUP.md).
const { callLLM } = require('../../../services/llm');

const SYSTEM_CHAT_PROMPT = `Tu es MediCare AI, assistant médical de l'application MediCare Tunisie.
Tu aides les patients avec des conseils de santé généraux en français.

Règles absolues :
- Fournis uniquement des informations générales, jamais de diagnostics définitifs.
- Recommande toujours de consulter un médecin pour tout symptôme persistant ou inquiétant.
- En cas d'urgence vitale (douleur thoracique intense, détresse respiratoire, AVC, inconscience), indique immédiatement d'appeler le SAMU au 190.
- Sois concis (3-5 phrases max par réponse), bienveillant et professionnel.
- Réponds toujours en français.
- Tu connais le contexte médical tunisien (médicaments disponibles, conventions locales).`;

const SYSTEM_TRIAGE_PROMPT = `Tu es un système de triage médical de MediCare Tunisie.
Analyse les symptômes décrits et réponds UNIQUEMENT avec un objet JSON valide, sans markdown, sans texte autour.

Format exact :
{"urgency":"low","specialty":"Médecin généraliste","recommendation":"...","disclaimer":"Ceci est une orientation indicative. Consultez un médecin pour un diagnostic précis."}

Valeurs urgency :
- "low"       → peut attendre 2-3 jours
- "medium"    → consultation dans les 24h
- "high"      → consultation aujourd'hui
- "emergency" → appeler le SAMU 190 immédiatement

Spécialités possibles :
Médecin généraliste, Cardiologue, Dermatologue, Neurologue, Orthopédiste,
Pédiatre, Gynécologue, Ophtalmologue, ORL, Gastro-entérologue,
Pneumologue, Psychiatre, Urologue, Rhumatologue, Urgences`;

module.exports = {

  // ── POST /api/ai-assistant/chat ──────────────────────────────────────────
  // Body: { messages: [{role, content}], mode: 'chat' | 'triage' }
  // → { data: { reply: string } }
  async chat(ctx) {
    const user = await getAuthUser(ctx);
    if (!user) return ctx.unauthorized();

    const { messages, symptoms, mode } = ctx.request.body;

    try {
      let openAiMessages;
      let temperature;
      let maxTokens;

      if (mode === 'triage') {
        // Triage: symptômes → JSON structuré
        const text = symptoms || (messages && messages[messages.length - 1]?.content) || '';
        openAiMessages = [
          { role: 'system', content: SYSTEM_TRIAGE_PROMPT },
          { role: 'user', content: text },
        ];
        temperature = 0.3;
        maxTokens = 300;
      } else {
        // Chat général
        openAiMessages = [
          { role: 'system', content: SYSTEM_CHAT_PROMPT },
          ...(messages || []),
        ];
        temperature = 0.7;
        maxTokens = 600;
      }

      const reply = await callLLM(openAiMessages, { temperature, maxTokens });

      return ctx.send({ data: { reply } });
    } catch (e) {
      strapi.log.error('AI Assistant error:', e.message);
      return ctx.internalServerError(e.message);
    }
  },

  // ── POST /api/ai-assistant/triage ────────────────────────────────────────
  // Body: { symptoms: string }
  // → { data: { urgency, specialty, recommendation, disclaimer } }
  async triage(ctx) {
    const user = await getAuthUser(ctx);
    if (!user) return ctx.unauthorized();

    const { symptoms } = ctx.request.body;
    if (!symptoms) return ctx.badRequest('symptoms est requis.');

    try {
      const raw = await callLLM(
        [
          { role: 'system', content: SYSTEM_TRIAGE_PROMPT },
          { role: 'user', content: symptoms },
        ],
        { temperature: 0.3, maxTokens: 300 }
      );

      // Parser le JSON retourné par le modèle
      let parsed;
      try {
        parsed = JSON.parse(raw);
      } catch (_) {
        // Essayer d'extraire le JSON si le modèle a ajouté du texte
        const match = raw.match(/\{[\s\S]*\}/);
        if (match) parsed = JSON.parse(match[0]);
        else throw new Error('Réponse triage non analysable');
      }

      return ctx.send({ data: parsed });
    } catch (e) {
      strapi.log.error('AI Triage error:', e.message);
      return ctx.internalServerError(e.message);
    }
  },
};
