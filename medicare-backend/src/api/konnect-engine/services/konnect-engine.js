'use strict';

const axios = require('axios');

const BASE_URL = () =>
  process.env.KONNECT_BASE_URL || 'https://api.preprod.konnect.network/api/v2';

function getApiKey() {
  const key = process.env.KONNECT_API_KEY;
  if (!key || key.startsWith('your_konnect_api_key')) {
    throw new Error(
      'KONNECT_API_KEY non configurée. Ajoutez votre clé dans .env'
    );
  }
  return key;
}

function getWalletId() {
  const id = process.env.KONNECT_WALLET_ID;
  if (!id || id.startsWith('your_wallet_id')) {
    throw new Error(
      'KONNECT_WALLET_ID non configuré. Ajoutez votre wallet ID dans .env'
    );
  }
  return id;
}

/**
 * Initialise un paiement Konnect.
 * @param {object} payload - Doit contenir au minimum amount (millimes),
 *   firstName, lastName, email, phoneNumber, orderId, description.
 * @returns {Promise<{payUrl: string, paymentRef: string}>}
 */
async function initKonnectPayment(payload) {
  const apiKey = getApiKey();
  const walletId = getWalletId();

  const body = {
    receiverWalletId: walletId,
    token: 'TND',
    type: 'immediate',
    lifespan: 10,
    checkoutForm: true,
    addPaymentFeesToAmount: true,
    acceptedPaymentMethods: ['wallet', 'bank_card', 'e-DINAR'],
    silentWebhook: true,
    theme: 'light',
    ...payload,
  };

  const res = await axios.post(`${BASE_URL()}/payments/init-payment`, body, {
    headers: {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    },
    timeout: 15000,
  });

  return {
    payUrl: res.data.payUrl,
    paymentRef: res.data.paymentRef,
  };
}

/**
 * Récupère le statut d'un paiement Konnect.
 * @param {string} paymentRef
 * @returns {Promise<object>} - Objet payment retourné par Konnect.
 */
async function getKonnectPayment(paymentRef) {
  const apiKey = getApiKey();

  const res = await axios.get(`${BASE_URL()}/payments/${paymentRef}`, {
    headers: {
      'x-api-key': apiKey,
    },
    timeout: 15000,
  });

  // Konnect renvoie typiquement { payment: { ... } }
  return res.data.payment || res.data;
}

module.exports = {
  initKonnectPayment,
  getKonnectPayment,
};
