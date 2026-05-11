'use strict';

// ── helper OpenAI ─────────────────────────────────────────────────────────────

async function callOpenAI(messages, { maxTokens = 800, temperature = 0.4 } = {}) {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error('OPENAI_API_KEY non configurée dans .env du backend');

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages,
      temperature,
      max_tokens: maxTokens,
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message || `OpenAI HTTP ${res.status}`);
  }

  const data = await res.json();
  return data.choices[0].message.content;
}

function extractJson(raw) {
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('Réponse JSON non trouvée dans la réponse du modèle');
  return JSON.parse(match[0]);
}

// ── prompts ───────────────────────────────────────────────────────────────────

const PRESCRIPTION_SYSTEM = `
Tu es un assistant de rédaction d'ordonnances pour un médecin en Tunisie.
Génère un brouillon d'ordonnance structuré en JSON valide (sans markdown, sans texte autour).

Format strict :
{
  "diagnosis": "diagnostic proposé",
  "medications": [
    {
      "name": "Nom du médicament (disponible en Tunisie)",
      "dosage": "ex: 1 comprimé",
      "frequency": "ex: 3 fois par jour",
      "duration": "ex: 7 jours",
      "instructions": "ex: Après les repas"
    }
  ],
  "notes": "Conseils généraux pour le patient",
  "followUp": "Recommandation de suivi"
}
Utilise uniquement des médicaments courants disponibles en Tunisie.
Ce brouillon est soumis à la validation et modification du médecin avant usage.
`.trim();

const SUMMARY_SYSTEM = `
Tu es un assistant médical qui rédige des résumés cliniques pour des médecins tunisiens.
Analyse les données fournies et rédige un résumé concis (6-8 lignes max) en français.
Structure : état général, traitements actifs, historique récent, points d'attention.
Sois factuel, professionnel, et ne pose pas de diagnostic.
`.trim();

const DIAGNOSTIC_SYSTEM = `
Tu es un assistant d'aide au diagnostic pour un médecin en Tunisie.
À partir des symptômes décrits, propose 2-3 hypothèses diagnostiques probables en JSON.

Format strict :
{
  "hypotheses": [
    { "name": "Nom de la pathologie", "probability": "élevée|moyenne|faible", "rationale": "justification courte" }
  ],
  "recommended_exams": ["Examen 1", "Examen 2"],
  "disclaimer": "Ces hypothèses sont indicatives et ne remplacent pas le jugement clinique du médecin."
}
`.trim();

// ── controller ────────────────────────────────────────────────────────────────

module.exports = {

  // POST /ai-doctor/prescription-draft
  // body: { symptoms, diagnosis?, patientAge?, allergies?, patientName? }
  async prescriptionDraft(ctx) {
    const user = ctx.state.user;
    if (!user || user.appRole !== 'doctor') return ctx.forbidden();

    const { symptoms, diagnosis, patientAge, allergies, patientName } =
      ctx.request.body || {};

    if (!symptoms?.trim()) return ctx.badRequest('symptoms requis');

    const userPrompt = [
      patientName   && `Patient : ${patientName}`,
      patientAge    && `Âge : ${patientAge} ans`,
      allergies     && `Allergies connues : ${allergies}`,
      `Symptômes / motif : ${symptoms}`,
      diagnosis     && `Diagnostic envisagé : ${diagnosis}`,
    ]
      .filter(Boolean)
      .join('\n');

    try {
      const raw = await callOpenAI(
        [
          { role: 'system', content: PRESCRIPTION_SYSTEM },
          { role: 'user', content: userPrompt },
        ],
        { maxTokens: 900, temperature: 0.35 },
      );

      const draft = extractJson(raw);
      return ctx.send({ data: draft });
    } catch (e) {
      strapi.log.warn('ai-doctor prescription-draft error:', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // POST /ai-doctor/summarize-patient
  // body: { patientId }
  async summarizePatient(ctx) {
    const user = ctx.state.user;
    if (!user || user.appRole !== 'doctor') return ctx.forbidden();

    const { patientId } = ctx.request.body || {};
    if (!patientId) return ctx.badRequest('patientId requis');

    try {
      // Récupère les données cliniques du patient
      const [prescriptions, records, appointments, patient] = await Promise.all([
        strapi.query('api::prescription.prescription').findMany({
          where: { patientId: Number(patientId) },
          orderBy: { createdAt: 'desc' },
          limit: 5,
        }),
        strapi.query('api::medical-record.medical-record').findMany({
          where: { patientId: Number(patientId) },
          orderBy: { createdAt: 'desc' },
          limit: 5,
        }),
        strapi.query('api::appointment.appointment').findMany({
          where: { patientId: Number(patientId) },
          orderBy: { appointmentDate: 'desc' },
          limit: 5,
        }),
        strapi.query('plugin::users-permissions.user').findOne({
          where: { id: Number(patientId) },
        }),
      ]);

      // Construit le contexte textuel pour le LLM
      const lines = [];

      if (patient) {
        const name = `${patient.firstName || ''} ${patient.lastName || ''}`.trim();
        lines.push(`Patient : ${name || patient.username || 'Inconnu'}`);
      }

      if (appointments.length > 0) {
        lines.push('\nConsultations récentes :');
        for (const a of appointments) {
          const date = a.appointmentDate
            ? new Date(a.appointmentDate).toLocaleDateString('fr-FR')
            : '?';
          lines.push(`  - ${date} | ${a.status || ''} | ${a.reason || 'Sans motif'}`);
        }
      }

      if (prescriptions.length > 0) {
        lines.push('\nOrdonnances récentes :');
        for (const p of prescriptions) {
          lines.push(
            `  - ${p.diagnosis || 'Sans diagnostic'} | statut: ${p.status || ''} | ${
              Array.isArray(p.medications)
                ? p.medications.map((m) => m.name).join(', ')
                : ''
            }`,
          );
        }
      }

      if (records.length > 0) {
        lines.push('\nDossiers médicaux :');
        for (const r of records) {
          lines.push(`  - ${r.title || r.type || 'Entrée'} : ${r.content || r.findings || ''}`);
        }
      }

      if (lines.length === 0) {
        return ctx.send({ data: { summary: 'Aucune donnée clinique disponible pour ce patient.' } });
      }

      const summary = await callOpenAI(
        [
          { role: 'system', content: SUMMARY_SYSTEM },
          { role: 'user', content: lines.join('\n') },
        ],
        { maxTokens: 400, temperature: 0.3 },
      );

      return ctx.send({ data: { summary } });
    } catch (e) {
      strapi.log.warn('ai-doctor summarize-patient error:', e.message);
      return ctx.badRequest(e.message);
    }
  },

  // POST /ai-doctor/diagnostic-suggestions
  // body: { symptoms, patientAge?, medicalHistory? }
  async diagnosticSuggestions(ctx) {
    const user = ctx.state.user;
    if (!user || user.appRole !== 'doctor') return ctx.forbidden();

    const { symptoms, patientAge, medicalHistory } = ctx.request.body || {};
    if (!symptoms?.trim()) return ctx.badRequest('symptoms requis');

    const prompt = [
      `Symptômes : ${symptoms}`,
      patientAge     && `Âge du patient : ${patientAge} ans`,
      medicalHistory && `Antécédents : ${medicalHistory}`,
    ]
      .filter(Boolean)
      .join('\n');

    try {
      const raw = await callOpenAI(
        [
          { role: 'system', content: DIAGNOSTIC_SYSTEM },
          { role: 'user', content: prompt },
        ],
        { maxTokens: 500, temperature: 0.3 },
      );

      const result = extractJson(raw);
      return ctx.send({ data: result });
    } catch (e) {
      strapi.log.warn('ai-doctor diagnostic error:', e.message);
      return ctx.badRequest(e.message);
    }
  },
};
