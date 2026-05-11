'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/schedule-engine/availability',
      handler: 'schedule-engine.getAvailability',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/schedule-engine/availability',
      handler: 'schedule-engine.setAvailability',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/schedule-engine/blocks',
      handler: 'schedule-engine.getBlocks',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/schedule-engine/blocks',
      handler: 'schedule-engine.addBlock',
      config: { policies: [] },
    },
    {
      method: 'DELETE',
      path: '/schedule-engine/blocks/:id',
      handler: 'schedule-engine.removeBlock',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/schedule-engine/public-availability',
      handler: 'schedule-engine.getPublicAvailability',
      config: { policies: [] }, // accessible aux patients authentifiés
    },
  ],
};
