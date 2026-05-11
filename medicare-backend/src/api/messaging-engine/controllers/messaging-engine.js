'use strict';

const fcmSender = require('../../../services/fcm-sender');

// ── helpers ───────────────────────────────────────────────────────────────────

function displayName(u) {
  if (!u) return 'Utilisateur';
  const full = `${u.firstName || ''} ${u.lastName || ''}`.trim();
  return full || u.username || 'Utilisateur';
}

async function createNotif(userId, title, body, data) {
  try {
    await strapi.query('api::notification.notification').create({
      data: { userId, title, body, type: 'message', data: data || null, read: false },
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
          data: { type: 'message', ...(data || {}) },
        });
      }
    } catch (fcmErr) {
      strapi.log.warn('messaging FCM push error:', fcmErr.message);
    }
  } catch (e) {
    strapi.log.warn('messaging notif error:', e.message);
  }
}

// ── controller ────────────────────────────────────────────────────────────────

module.exports = {
  // GET /messaging-engine/conversations
  async getConversations(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const isDoctor = user.appRole === 'doctor';
    const where = isDoctor ? { doctorId: user.id } : { patientId: user.id };

    const conversations = await strapi.query('api::conversation.conversation').findMany({
      where,
      orderBy: { lastMessageAt: 'desc' },
    });

    return ctx.send({ data: conversations });
  },

  // POST /messaging-engine/find-or-create  — body: { doctorId } ou { patientId }
  async findOrCreate(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { doctorId, patientId } = ctx.request.body || {};

    let pid, did;
    if (user.appRole === 'patient') {
      if (!doctorId) return ctx.badRequest('doctorId requis');
      pid = user.id;
      did = Number(doctorId);
    } else if (user.appRole === 'doctor') {
      if (!patientId) return ctx.badRequest('patientId requis');
      pid = Number(patientId);
      did = user.id;
    } else {
      return ctx.forbidden();
    }

    // Cherche une conversation existante
    const existing = await strapi.query('api::conversation.conversation').findOne({
      where: { patientId: pid, doctorId: did },
    });
    if (existing) return ctx.send({ data: existing });

    // Récupère les noms
    const [patient, doctor] = await Promise.all([
      strapi.query('plugin::users-permissions.user').findOne({ where: { id: pid } }),
      strapi.query('plugin::users-permissions.user').findOne({ where: { id: did } }),
    ]);

    const conv = await strapi.query('api::conversation.conversation').create({
      data: {
        patientId: pid,
        patientName: displayName(patient),
        doctorId: did,
        doctorName: `Dr. ${displayName(doctor)}`,
        patientUnread: 0,
        doctorUnread: 0,
      },
    });

    return ctx.send({ data: conv });
  },

  // GET /messaging-engine/messages/:conversationId
  async getMessages(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const conversationId = Number(ctx.params.conversationId);
    const conv = await strapi.query('api::conversation.conversation').findOne({
      where: { id: conversationId },
    });
    if (!conv) return ctx.notFound();
    if (conv.patientId !== user.id && conv.doctorId !== user.id) return ctx.forbidden();

    const messages = await strapi.query('api::message.message').findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      limit: 100,
    });

    return ctx.send({ data: messages });
  },

  // POST /messaging-engine/send  — body: { conversationId, content }
  async sendMessage(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { conversationId, content } = ctx.request.body || {};
    if (!conversationId || !content?.trim()) {
      return ctx.badRequest('conversationId et content requis');
    }

    const conv = await strapi.query('api::conversation.conversation').findOne({
      where: { id: Number(conversationId) },
    });
    if (!conv) return ctx.notFound();
    if (conv.patientId !== user.id && conv.doctorId !== user.id) return ctx.forbidden();

    const isDoctor = user.appRole === 'doctor';
    const senderRole = isDoctor ? 'doctor' : 'patient';
    const senderName = isDoctor ? `Dr. ${displayName(user)}` : displayName(user);

    // Crée le message
    const message = await strapi.query('api::message.message').create({
      data: {
        conversationId: Number(conversationId),
        senderId: user.id,
        senderName,
        senderRole,
        content: content.trim(),
        read: false,
        messageType: 'text',
      },
    });

    // Met à jour la conversation
    const updateData = {
      lastMessage: content.trim().slice(0, 100),
      lastMessageAt: new Date(),
    };
    if (isDoctor) {
      updateData.patientUnread = (conv.patientUnread || 0) + 1;
    } else {
      updateData.doctorUnread = (conv.doctorUnread || 0) + 1;
    }
    await strapi.query('api::conversation.conversation').update({
      where: { id: Number(conversationId) },
      data: updateData,
    });

    // Notification pour le destinataire
    const recipientId = isDoctor ? conv.patientId : conv.doctorId;
    await createNotif(
      recipientId,
      `Nouveau message de ${senderName}`,
      content.trim().slice(0, 80),
      { conversationId: Number(conversationId) },
    );

    return ctx.send({ data: message });
  },

  // PUT /messaging-engine/mark-read/:conversationId
  async markRead(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const conversationId = Number(ctx.params.conversationId);
    const conv = await strapi.query('api::conversation.conversation').findOne({
      where: { id: conversationId },
    });
    if (!conv) return ctx.notFound();
    if (conv.patientId !== user.id && conv.doctorId !== user.id) return ctx.forbidden();

    const isDoctor = user.appRole === 'doctor';
    await strapi.query('api::conversation.conversation').update({
      where: { id: conversationId },
      data: isDoctor ? { doctorUnread: 0 } : { patientUnread: 0 },
    });

    return ctx.send({ success: true });
  },
};
