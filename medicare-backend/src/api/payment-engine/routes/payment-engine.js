'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/payment-engine/init',
      handler: 'payment-engine.initPayment',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/payment-engine/verify',
      handler: 'payment-engine.verifyPayment',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/payment-engine/status/:invoiceId',
      handler: 'payment-engine.getStatus',
      config: { policies: [] },
    },
    {
      method: 'GET',
      path: '/payment-engine/callback',
      handler: 'payment-engine.handleCallback',
      config: { auth: false, policies: [] },
    },
  ],
};
