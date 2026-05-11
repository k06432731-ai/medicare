'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/ai-assistant/chat',
      handler: 'ai-assistant.chat',
      config: { auth: false, policies: [] },
    },
    {
      method: 'POST',
      path: '/ai-assistant/triage',
      handler: 'ai-assistant.triage',
      config: { auth: false, policies: [] },
    },
  ],
};
