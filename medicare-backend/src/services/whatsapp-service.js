'use strict';

/**
 * Recovery Messaging Service — No-op stub
 *
 * Twilio/WhatsApp/SMS support has been removed.
 * SMS removed — use FCM push notifications instead.
 * See notification-engine for in-app/push notifications.
 *
 * All functions return a mocked success response so any existing
 * caller (e.g. recovery-engine) continues to work without errors.
 */

async function send(to, body) {
  console.log(`[Recovery][NOOP] To: ${to}\n${body}`);
  return { sid: 'noop_mock', status: 'sent' };
}

module.exports = {
  async sendNoShowRecovery({ phone, patientName, appointmentDate, doctorName, caseId }) {
    const body = `[NOOP] No-show recovery for ${patientName} (case ${caseId})`;
    return send(phone, body);
  },

  async sendRebookingOptions({ phone, patientName, slots }) {
    const body = `[NOOP] Rebooking options for ${patientName} (${slots.length} slots)`;
    return send(phone, body);
  },

  async sendInactivePatient({ phone, patientName, daysSince, caseId }) {
    const body = `[NOOP] Inactive patient ${patientName} (${daysSince}d, case ${caseId})`;
    return send(phone, body);
  },

  async sendChronicFollowup({ phone, patientName, prescriptionEndDate, caseId }) {
    const body = `[NOOP] Chronic followup for ${patientName} (case ${caseId})`;
    return send(phone, body);
  },

  async sendPreconsultReminder({ phone, patientName, appointmentDate, link }) {
    const body = `[NOOP] Preconsult reminder for ${patientName}`;
    return send(phone, body);
  },
};
