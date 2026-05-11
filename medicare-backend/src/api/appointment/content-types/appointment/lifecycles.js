'use strict';

const fcmSender = require('../../../../services/fcm-sender');

async function notify(userId, title, body, type, data) {
  try {
    await strapi.query('api::notification.notification').create({
      data: { userId, title, body, type, data: data || null, read: false },
    });
    // Also send FCM push if user has a token
    try {
      const user = await strapi.query('plugin::users-permissions.user').findOne({
        where: { id: userId },
        select: ['id', 'fcmToken'],
      });
      if (user && user.fcmToken) {
        await fcmSender.sendToUser(user.fcmToken, {
          title,
          body,
          data: { type, ...(data || {}) },
        });
      }
    } catch (fcmErr) {
      strapi.log.warn('Appointment lifecycle — FCM push error:', fcmErr.message);
    }
  } catch (e) {
    strapi.log.warn('Appointment lifecycle — notif error:', e.message);
  }
}

module.exports = {
  // Notifie le médecin quand un patient prend RDV
  async afterCreate(event) {
    const { result } = event;
    if (result.doctorId) {
      await notify(
        result.doctorId,
        'Nouveau rendez-vous 📅',
        'Un patient a réservé un rendez-vous avec vous.',
        'appointment',
        { appointmentId: result.id },
      );
    }
  },

  // Notifie le patient selon le changement de statut
  async afterUpdate(event) {
    const { result, params } = event;
    const newStatus = params?.data?.status;
    if (!newStatus || !result.patientId) return;

    if (newStatus === 'confirmed') {
      await notify(
        result.patientId,
        'Rendez-vous confirmé ✅',
        'Votre rendez-vous a été confirmé par le médecin.',
        'appointment',
        { appointmentId: result.id },
      );
    } else if (newStatus === 'cancelled') {
      await notify(
        result.patientId,
        'Rendez-vous annulé',
        'Votre rendez-vous a été annulé. Vous pouvez en reprogrammer un.',
        'appointment',
        { appointmentId: result.id },
      );
    } else if (newStatus === 'completed') {
      await notify(
        result.patientId,
        'Consultation terminée 🎉',
        'Merci pour votre visite. Votre dossier a été mis à jour.',
        'appointment',
        { appointmentId: result.id },
      );
    }
  },
};
