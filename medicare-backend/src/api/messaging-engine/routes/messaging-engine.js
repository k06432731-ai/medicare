'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/messaging-engine/conversations',
      handler: 'messaging-engine.getConversations',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/messaging-engine/find-or-create',
      handler: 'messaging-engine.findOrCreate',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/messaging-engine/messages/:conversationId',
      handler: 'messaging-engine.getMessages',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/messaging-engine/send',
      handler: 'messaging-engine.sendMessage',
      config: { policies: [] },
    },
    {
      method: 'PUT',
      path: '/messaging-engine/mark-read/:conversationId',
      handler: 'messaging-engine.markRead',
      config: { policies: [] },
    },
  ],
};
