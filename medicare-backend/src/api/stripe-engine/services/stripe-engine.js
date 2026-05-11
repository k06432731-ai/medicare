'use strict';

let stripeClient = null;

function getStripe() {
  if (stripeClient) return stripeClient;
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new Error('STRIPE_SECRET_KEY not set');
  }
  const Stripe = require('stripe');
  stripeClient = new Stripe(key);
  return stripeClient;
}

async function createPaymentIntent({ amount, currency, metadata }) {
  const stripe = getStripe();
  return stripe.paymentIntents.create({
    // Stripe expects the smallest currency unit (cents)
    amount: Math.round(amount * 100),
    currency,
    automatic_payment_methods: { enabled: true },
    metadata,
  });
}

async function retrievePaymentIntent(id) {
  const stripe = getStripe();
  return stripe.paymentIntents.retrieve(id);
}

function constructWebhookEvent(rawBody, signature) {
  const stripe = getStripe();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    // Dev/test fallback when no webhook secret configured
    return typeof rawBody === 'string' ? JSON.parse(rawBody) : rawBody;
  }
  return stripe.webhooks.constructEvent(rawBody, signature, secret);
}

module.exports = { createPaymentIntent, retrievePaymentIntent, constructWebhookEvent };
