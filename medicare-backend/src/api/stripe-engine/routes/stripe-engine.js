'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/stripe-engine/create-intent',
      handler: 'stripe-engine.createIntent',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/stripe-engine/confirm',
      handler: 'stripe-engine.confirmPayment',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/stripe-engine/webhook',
      handler: 'stripe-engine.webhook',
      config: { auth: false },
    },
  ],
};
