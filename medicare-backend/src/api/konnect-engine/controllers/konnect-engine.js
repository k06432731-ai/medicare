'use strict';

const {
  initKonnectPayment,
  getKonnectPayment,
} = require('../services/konnect-engine');

// Helper : vérifie le JWT et retourne l'utilisateur, ou null
async function getAuthUser(ctx) {
  try {
    const bearer = ctx.request.headers.authorization || '';
    const token = bearer.startsWith('Bearer ') ? bearer.slice(7) : null;
    if (!token) return null;

    const jwt = require('jsonwebtoken');
    const secret = process.env.JWT_SECRET;
    const payload = jwt.verify(token, secret);

    return await strapi.entityService.findOne(
      'plugin::users-permissions.user',
      payload.id
    );
  } catch (_) {
    return null;
  }
}

// Conversion TND → millimes (Konnect attend des millimes : 1 TND = 1000 millimes)
function toMillimes(amount) {
  return Math.round(Number(amount) * 1000);
}

// Marque une facture comme payée + crée un Payment record (idempotent).
async function markInvoicePaid({ invoice, paymentRef, amount, patientId }) {
  if (invoice.status === 'paid') return;

  await strapi.query('api::invoice.invoice').update({
    where: { id: invoice.id },
    data: {
      status: 'paid',
      paymentMethod: 'card',
      paidAt: new Date().toISOString(),
    },
  });

  // Éviter les doublons si déjà créé (webhook + verify peuvent arriver)
  const existing = await strapi
    .query('api::payment.payment')
    .findOne({ where: { transactionId: paymentRef } });

  if (existing) {
    if (existing.status !== 'completed') {
      await strapi.query('api::payment.payment').update({
        where: { id: existing.id },
        data: { status: 'completed' },
      });
    }
  } else {
    await strapi.entityService.create('api::payment.payment', {
      data: {
        invoiceId: invoice.id,
        patientId: patientId || 0,
        amount: amount || invoice.amount,
        method: 'konnect',
        status: 'completed',
        transactionId: paymentRef,
      },
    });
  }

  try {
    await strapi.entityService.create('api::notification.notification', {
      data: {
        title: 'Paiement Konnect confirmé ✓',
        body: `Votre paiement via Konnect a été validé pour la facture #${invoice.id}.`,
        type: 'invoice',
        userId: patientId || invoice.patient?.id || 0,
        read: false,
        data: { invoiceId: invoice.id },
      },
    });
  } catch (_) {}
}

module.exports = {

  // ── POST /api/konnect-engine/init-payment ───────────────────────────────────
  // Body: { invoiceId }
  // → { payUrl, paymentRef }
  async initPayment(ctx) {
    const user = await getAuthUser(ctx);
    if (!user) return ctx.unauthorized();

    const { invoiceId } = ctx.request.body;
    if (!invoiceId) return ctx.badRequest('invoiceId est requis.');

    const invoice = await strapi.query('api::invoice.invoice').findOne({
      where: { id: Number(invoiceId) },
      populate: { patient: true },
    });

    if (!invoice) return ctx.notFound('Facture introuvable.');
    if (invoice.status === 'paid') {
      return ctx.badRequest('Cette facture est déjà payée.');
    }

    const patient = invoice.patient || user;
    const publicUrl = process.env.PUBLIC_URL || 'https://medicare.fly.dev';

    let result;
    try {
      result = await initKonnectPayment({
        amount: toMillimes(invoice.amount),
        description: `Facture Medicare #${invoice.id}`,
        firstName: patient.firstName || patient.username || 'Patient',
        lastName: patient.lastName || '',
        phoneNumber: patient.phone || patient.phoneNumber || '',
        email: patient.email || '',
        orderId: `INVOICE_${invoice.id}`,
        webhook: `${publicUrl}/api/konnect-engine/webhook`,
        successUrl: 'medicare://payment/success?ref=',
        failUrl: 'medicare://payment/fail',
      });
    } catch (err) {
      strapi.log.error('Konnect init-payment error', err.response?.data || err.message);
      return ctx.badRequest(
        err.response?.data?.errors?.[0]?.message ||
          err.message ||
          'Erreur lors de l\'initialisation Konnect'
      );
    }

    // Enregistrer la référence + un Payment "processing"
    try {
      await strapi.entityService.create('api::payment.payment', {
        data: {
          invoiceId: invoice.id,
          patientId: user.id,
          amount: invoice.amount,
          method: 'konnect',
          status: 'processing',
          transactionId: result.paymentRef,
          paymentUrl: result.payUrl,
        },
      });
    } catch (e) {
      strapi.log.warn('Konnect — impossible d\'enregistrer payment processing', e.message);
    }

    return ctx.send({
      data: {
        payUrl: result.payUrl,
        paymentRef: result.paymentRef,
      },
    });
  },

  // ── GET /api/konnect-engine/verify/:paymentRef ──────────────────────────────
  async verifyPayment(ctx) {
    const user = await getAuthUser(ctx);
    if (!user) return ctx.unauthorized();

    const { paymentRef } = ctx.params;
    if (!paymentRef) return ctx.badRequest('paymentRef requis.');

    let payment;
    try {
      payment = await getKonnectPayment(paymentRef);
    } catch (err) {
      strapi.log.error('Konnect verify error', err.response?.data || err.message);
      return ctx.badRequest('Impossible de vérifier le paiement Konnect.');
    }

    const status = payment.status || 'pending';
    const orderId = payment.orderId || '';
    const invoiceId = orderId.startsWith('INVOICE_')
      ? Number(orderId.replace('INVOICE_', ''))
      : null;

    if (status === 'completed' && invoiceId) {
      const invoice = await strapi
        .query('api::invoice.invoice')
        .findOne({ where: { id: invoiceId } });
      if (invoice) {
        await markInvoicePaid({
          invoice,
          paymentRef,
          amount: invoice.amount,
          patientId: user.id,
        });
      }
    }

    return ctx.send({
      data: {
        status,
        invoiceId,
        paymentRef,
      },
    });
  },

  // ── GET/POST /api/konnect-engine/webhook ───────────────────────────────────
  // Konnect appelle en GET avec ?payment_ref=xxx
  async webhook(ctx) {
    const paymentRef =
      ctx.query?.payment_ref ||
      ctx.request.body?.payment_ref ||
      ctx.request.body?.paymentRef;

    if (!paymentRef) {
      strapi.log.warn('Konnect webhook reçu sans payment_ref');
      ctx.status = 200;
      return ctx.send({ received: true });
    }

    try {
      const payment = await getKonnectPayment(paymentRef);
      if (payment.status === 'completed') {
        const orderId = payment.orderId || '';
        const invoiceId = orderId.startsWith('INVOICE_')
          ? Number(orderId.replace('INVOICE_', ''))
          : null;

        if (invoiceId) {
          const invoice = await strapi
            .query('api::invoice.invoice')
            .findOne({ where: { id: invoiceId } });

          if (invoice) {
            await markInvoicePaid({
              invoice,
              paymentRef,
              amount: invoice.amount,
              patientId: invoice.patient?.id,
            });
            strapi.log.info(
              `✅ Konnect webhook — Facture #${invoiceId} marquée payée`
            );
          }
        }
      } else {
        strapi.log.info(
          `Konnect webhook — paiement ${paymentRef} status=${payment.status}`
        );
      }
    } catch (err) {
      strapi.log.error('Konnect webhook error', err.message);
    }

    ctx.status = 200;
    return ctx.send({ received: true });
  },
};
