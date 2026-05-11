'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/notification-engine/my',
      handler: 'notification-engine.getMyNotifications',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/notification-engine/unread-count',
      handler: 'notification-engine.getUnreadCount',
      config: { policies: [] },
    },
    {
      method: 'PUT',
      path: '/notification-engine/mark-read/:id',
      handler: 'notification-engine.markRead',
      config: { policies: [] },
    },
    {
      method: 'PUT',
      path: '/notification-engine/mark-all-read',
      handler: 'notification-engine.markAllRead',
      config: { policies: [] },
    },
  ],
};
