'use strict';

module.exports = {
  // GET /notification-engine/my
  async getMyNotifications(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const notifications = await strapi.query('api::notification.notification').findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
      limit: 60,
    });

    return ctx.send({ data: notifications });
  },

  // GET /notification-engine/unread-count
  async getUnreadCount(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const count = await strapi.query('api::notification.notification').count({
      where: { userId: user.id, read: false },
    });

    return ctx.send({ count });
  },

  // PUT /notification-engine/mark-read/:id
  async markRead(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const id = Number(ctx.params.id);
    const notif = await strapi.query('api::notification.notification').findOne({
      where: { id, userId: user.id },
    });
    if (!notif) return ctx.notFound();

    await strapi.query('api::notification.notification').update({
      where: { id },
      data: { read: true },
    });

    return ctx.send({ success: true });
  },

  // PUT /notification-engine/mark-all-read
  async markAllRead(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const unread = await strapi.query('api::notification.notification').findMany({
      where: { userId: user.id, read: false },
    });

    for (const n of unread) {
      await strapi.query('api::notification.notification').update({
        where: { id: n.id },
        data: { read: true },
      });
    }

    return ctx.send({ success: true, count: unread.length });
  },
};
