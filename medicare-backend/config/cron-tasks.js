'use strict';

// Helper : appelle une méthode du service recovery-engine si elle existe
async function safeCall(strapi, methodName, context) {
  try {
    const engineService = strapi.service('api::recovery-engine.recovery-engine');
    if (typeof engineService[methodName] !== 'function') {
      strapi.log.warn(`[Cron/${context}] Méthode ${methodName} introuvable dans recovery-engine service`);
      return;
    }
    await engineService[methodName]();
  } catch (err) {
    strapi.log.error(`[Cron/${context}] Erreur dans ${methodName}: ${err.message}`);
  }
}

module.exports = {
  // ── Toutes les 15 minutes : détection des no-shows ──────────────────────────
  '*/15 * * * *': async ({ strapi }) => {
    await safeCall(strapi, 'detectNoShows', 'NoShow');
    await safeCall(strapi, 'escalateStaleCases', 'NoShow');
  },

  // ── Toutes les heures : recalcul des scores de risque ────────────────────────
  '0 * * * *': async ({ strapi }) => {
    await safeCall(strapi, 'recalculateRiskScores', 'RiskScore');
  },

  // ── Tous les jours à 08h00 : patients inactifs + suivis chroniques ───────────
  '0 8 * * *': async ({ strapi }) => {
    await safeCall(strapi, 'detectInactivePatients', 'Daily');
    await safeCall(strapi, 'detectChronicFollowups', 'Daily');
  },
};
