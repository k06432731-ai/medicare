'use strict';

/**
 * WhatsApp Recovery Messaging Service — Twilio Adapter
 *
 * Configuration via environment variables:
 *   TWILIO_ACCOUNT_SID  — Twilio account SID
 *   TWILIO_AUTH_TOKEN   — Twilio auth token
 *   TWILIO_WHATSAPP_FROM — e.g. whatsapp:+14155238886
 *   APP_DEEPLINK_BASE   — e.g. https://medicare.app/
 *
 * In development / when TWILIO_ACCOUNT_SID is not set, messages are logged only.
 */

const TWILIO_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const FROM = process.env.TWILIO_WHATSAPP_FROM || 'whatsapp:+14155238886';
const DEEPLINK_BASE = process.env.APP_DEEPLINK_BASE || 'https://medicare.app/';

// Lazy-load Twilio to avoid crash if not installed
let twilioClient = null;
function getTwilio() {
  if (!TWILIO_SID || !TWILIO_TOKEN) return null;
  if (!twilioClient) {
    try {
      const twilio = require('twilio');
      twilioClient = twilio(TWILIO_SID, TWILIO_TOKEN);
    } catch {
      return null;
    }
  }
  return twilioClient;
}

// ── Send helpers ──────────────────────────────────────────────────────────────

async function send(to, body) {
  const client = getTwilio();
  const toNumber = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;

  if (!client) {
    // En dev : strapi n'est pas importé dans ce fichier → utiliser console.log
    console.log(`[WhatsApp][DEV] To: ${toNumber}\n${body}`);
    return { sid: 'dev_mock', status: 'sent' };
  }

  const message = await client.messages.create({ from: FROM, to: toNumber, body });
  return { sid: message.sid, status: message.status };
}

// ── Recovery message templates ────────────────────────────────────────────────

module.exports = {
  async sendNoShowRecovery({ phone, patientName, appointmentDate, doctorName, caseId }) {
    const dateStr = new Date(appointmentDate).toLocaleString('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      hour: '2-digit',
      minute: '2-digit',
    });
    const link = `${DEEPLINK_BASE}booking?recovery=${caseId}`;
    const body =
      `Bonjour ${patientName}, vous avez manqué votre RDV du ${dateStr} avec ${doctorName}.\n` +
      `Souhaitez-vous le reprogrammer ?\n\n` +
      `👉 Rebooker maintenant : ${link}\n\n` +
      `Répondez STOP pour ne plus recevoir ces messages.`;
    return send(phone, body);
  },

  async sendRebookingOptions({ phone, patientName, slots }) {
    const slotLines = slots
      .map((s, i) => `${i + 1}. ${new Date(s).toLocaleString('fr-FR')}`)
      .join('\n');
    const body =
      `Bonjour ${patientName}, voici 3 créneaux disponibles :\n\n${slotLines}\n\n` +
      `Répondez 1, 2 ou 3 pour confirmer votre RDV.\n` +
      `Répondez STOP pour ne plus recevoir ces messages.`;
    return send(phone, body);
  },

  async sendInactivePatient({ phone, patientName, daysSince, caseId }) {
    const link = `${DEEPLINK_BASE}doctors?recovery=${caseId}`;
    const body =
      `Bonjour ${patientName}, votre équipe médicale n'a pas eu de nouvelles depuis ${daysSince} jours.\n` +
      `Tout va bien ? Pensez à planifier un bilan si besoin.\n\n` +
      `👉 Prendre RDV : ${link}\n\n` +
      `Répondez STOP pour ne plus recevoir ces messages.`;
    return send(phone, body);
  },

  async sendChronicFollowup({ phone, patientName, prescriptionEndDate, caseId }) {
    const dateStr = new Date(prescriptionEndDate).toLocaleDateString('fr-FR');
    const link = `${DEEPLINK_BASE}booking?recovery=${caseId}`;
    const body =
      `Bonjour ${patientName}, votre traitement se termine le ${dateStr}.\n` +
      `N'oubliez pas de prendre RDV pour le renouveler avant cette date.\n\n` +
      `👉 Planifier le renouvellement : ${link}\n\n` +
      `Répondez STOP pour ne plus recevoir ces messages.`;
    return send(phone, body);
  },

  async sendPreconsultReminder({ phone, patientName, appointmentDate, link }) {
    const dateStr = new Date(appointmentDate).toLocaleString('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      hour: '2-digit',
      minute: '2-digit',
    });
    const body =
      `Rappel : votre RDV est ${dateStr}.\n` +
      `Merci de remplir votre questionnaire avant la consultation :\n\n` +
      `👉 ${link}\n\n` +
      `Répondez STOP pour ne plus recevoir ces messages.`;
    return send(phone, body);
  },
};
