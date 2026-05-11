'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/konnect-engine/init-payment',
      handler: 'konnect-engine.initPayment',
      config: { auth: false, policies: [] },
    },
    {
      method: 'GET',
      path: '/konnect-engine/verify/:paymentRef',
      handler: 'konnect-engine.verifyPayment',
      config: { auth: false, policies: [] },
    },
    {
      // Konnect appelle ce webhook en GET avec ?payment_ref=xxx (silentWebhook=true)
      method: 'GET',
      path: '/konnect-engine/webhook',
      handler: 'konnect-engine.webhook',
      config: { auth: false, policies: [] },
    },
    {
      // Fallback POST au cas où Konnect serait configuré différemment
      method: 'POST',
      path: '/konnect-engine/webhook',
      handler: 'konnect-engine.webhook',
      config: { auth: false, policies: [] },
    },
  ],
};
