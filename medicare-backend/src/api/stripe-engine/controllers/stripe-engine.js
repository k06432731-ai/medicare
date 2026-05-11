'use strict';

const service = require('../services/stripe-engine');

async function markInvoicePaid(invoiceId, paymentIntentId, amount, userId) {
  // Idempotent: only update if not already paid
  const fresh = await strapi.query('api::invoice.invoice').findOne({
    where: { id: Number(invoiceId) },
  });
  if (!fresh) return null;
  if (fresh.status !== 'paid') {
    await strapi.query('api::invoice.invoice').update({
      where: { id: Number(invoiceId) },
      data: {
        status: 'paid',
        paidAt: new Date().toISOString(),
      },
    });
  }

  // Create or upsert Payment record
  const existing = await strapi.query('api::payment.payment').findOne({
    where: { transactionId: paymentIntentId },
  });
  if (!existing) {
    await strapi.entityService.create('api::payment.payment', {
      data: {
        invoiceId: Number(invoiceId),
        patientId: userId || fresh.patient?.id || 0,
        amount: amount || fresh.amount,
        method: 'card',
        status: 'completed',
        transactionId: paymentIntentId,
      },
    });
  } else if (existing.status !== 'completed') {
    await strapi.query('api::payment.payment').update({
      where: { id: existing.id },
      data: { status: 'completed' },
    });
  }
  return fresh;
}

module.exports = {
  // POST /api/stripe-engine/create-intent
  // Body: { invoiceId }
  async createIntent(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { invoiceId } = ctx.request.body || {};
    if (!invoiceId) return ctx.badRequest('invoiceId est requis.');

    const invoice = await strapi.query('api::invoice.invoice').findOne({
      where: { id: Number(invoiceId) },
      populate: ['patient', 'doctor'],
    });

    if (!invoice) return ctx.notFound('Facture introuvable.');
    if (invoice.status === 'paid') return ctx.badRequest('Cette facture est déjà payée.');

    // Authorization: patient owner, attached doctor, or admin
    const isPatient = invoice.patient && invoice.patient.id === user.id;
    const isDoctor = invoice.doctor && invoice.doctor.id === user.id;
    if (!isPatient && !isDoctor) return ctx.forbidden('Accès refusé à cette facture.');

    try {
      const intent = await service.createPaymentIntent({
        amount: Number(invoice.amount),
        currency: (process.env.STRIPE_CURRENCY || 'eur').toLowerCase(),
        metadata: {
          invoiceId: String(invoice.id),
          userId: String(user.id),
        },
      });

      // Track the intent via a processing Payment record
      const existing = await strapi.query('api::payment.payment').findOne({
        where: { transactionId: intent.id },
      });
      if (!existing) {
        await strapi.entityService.create('api::payment.payment', {
          data: {
            invoiceId: invoice.id,
            patientId: invoice.patient?.id || user.id,
            amount: invoice.amount,
            method: 'card',
            status: 'processing',
            transactionId: intent.id,
          },
        });
      }

      return ctx.send({
        data: {
          clientSecret: intent.client_secret,
          paymentIntentId: intent.id,
        },
      });
    } catch (err) {
      strapi.log.error('[stripe-engine] createIntent failed:', err.message);
      return ctx.badRequest('Impossible de créer le paiement Stripe.');
    }
  },

  // POST /api/stripe-engine/confirm
  // Body: { invoiceId, paymentIntentId }
  async confirmPayment(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { invoiceId, paymentIntentId } = ctx.request.body || {};
    if (!invoiceId || !paymentIntentId) {
      return ctx.badRequest('invoiceId et paymentIntentId sont requis.');
    }

    try {
      const intent = await service.retrievePaymentIntent(paymentIntentId);
      if (intent.status === 'succeeded') {
        await markInvoicePaid(invoiceId, paymentIntentId, Number(intent.amount) / 100, user.id);

        // Notify patient
        try {
          await strapi.entityService.create('api::notification.notification', {
            data: {
              title: 'Paiement par carte confirmé ✓',
              body: `Votre paiement a été validé avec succès.`,
              type: 'invoice',
              userId: user.id,
              read: false,
              data: { invoiceId },
            },
          });
        } catch (_) {}

        return ctx.send({ data: { success: true } });
      }
      return ctx.send({ data: { success: false, status: intent.status } });
    } catch (err) {
      strapi.log.error('[stripe-engine] confirmPayment failed:', err.message);
      return ctx.badRequest('Impossible de confirmer le paiement.');
    }
  },

  // POST /api/stripe-engine/webhook (no auth — called by Stripe)
  async webhook(ctx) {
    const signature = ctx.request.headers['stripe-signature'];

    // Try to access the raw body. Strapi v5 (Koa-body) does not expose it by default,
    // so we fall back to the parsed JSON which still works when no webhook secret is set.
    const rawBody =
      ctx.request.body?.[Symbol.for('unparsedBody')] ||
      ctx.request.rawBody ||
      JSON.stringify(ctx.request.body || {});

    let event;
    try {
      event = service.constructWebhookEvent(rawBody, signature);
    } catch (err) {
      strapi.log.warn('[stripe-engine] webhook signature verification failed:', err.message);
      return ctx.badRequest('Signature invalide.');
    }

    try {
      switch (event.type) {
        case 'payment_intent.succeeded': {
          const intent = event.data.object;
          const invoiceId = intent.metadata?.invoiceId;
          const userId = intent.metadata?.userId;
          if (invoiceId) {
            await markInvoicePaid(invoiceId, intent.id, Number(intent.amount) / 100, Number(userId) || null);
          }
          break;
        }
        case 'payment_intent.payment_failed': {
          const intent = event.data.object;
          strapi.log.warn(`[stripe-engine] payment_intent.payment_failed for intent ${intent.id}`);
          try {
            const existing = await strapi.query('api::payment.payment').findOne({
              where: { transactionId: intent.id },
            });
            if (existing) {
              await strapi.query('api::payment.payment').update({
                where: { id: existing.id },
                data: { status: 'failed' },
              });
            }
          } catch (_) {}
          break;
        }
        default:
          // Ignore other event types
          break;
      }
    } catch (err) {
      strapi.log.error('[stripe-engine] webhook handler error:', err.message);
    }

    return ctx.send({ received: true });
  },
};
