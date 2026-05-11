'use strict';

function randomRef() {
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}

module.exports = {
  // POST /api/payment-engine/init
  // Body: { invoiceId, method }
  async initPayment(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { invoiceId, method } = ctx.request.body;
    if (!invoiceId || !method) return ctx.badRequest('invoiceId et method sont requis.');

    const invoice = await strapi
      .query('api::invoice.invoice')
      .findOne({ where: { id: Number(invoiceId) } });

    if (!invoice) return ctx.notFound('Facture introuvable.');
    if (invoice.status === 'paid') return ctx.badRequest('Cette facture est déjà payée.');

    const transactionId = `MED-${randomRef()}`;

    // ── Cash / bank_transfer / mobile_money → direct confirmation ───────────────
    if (['cash', 'bank_transfer', 'mobile_money'].includes(method)) {
      await strapi.query('api::invoice.invoice').update({
        where: { id: Number(invoiceId) },
        data: {
          status: 'paid',
          paymentMethod: method,
          paidAt: new Date().toISOString(),
        },
      });

      // Notification patient
      try {
        await strapi.entityService.create('api::notification.notification', {
          data: {
            title: 'Paiement confirmé ✓',
            body: `Paiement de ${invoice.amount} DT enregistré avec succès.`,
            type: 'invoice',
            userId: user.id,
            read: false,
            data: { invoiceId },
          },
        });
      } catch (_) {}

      return ctx.send({ data: { status: 'completed', transactionId, method } });
    }

    // ── Sobflous / D17 → redirect URL ────────────────────────────────────────────
    const callbackBase = process.env.PAYMENT_CALLBACK_URL || 'http://localhost:1337/api';

    const paymentUrl =
      method === 'sobflous'
        ? `https://dev.sobflous.tn/payer?montant=${invoice.amount}&ref=${transactionId}&retour=${callbackBase}/payment-engine/callback&success=true`
        : `https://paiement.poste.tn/d17?amount=${invoice.amount}&ref=${transactionId}&redirect=${callbackBase}/payment-engine/callback&success=true`;

    await strapi.entityService.create('api::payment.payment', {
      data: {
        invoiceId: Number(invoiceId),
        patientId: user.id,
        amount: invoice.amount,
        method,
        status: 'processing',
        transactionId,
        paymentUrl,
      },
    });

    return ctx.send({ data: { status: 'processing', paymentUrl, transactionId } });
  },

  // POST /api/payment-engine/verify
  // Body: { invoiceId, transactionId }
  async verifyPayment(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { invoiceId, transactionId } = ctx.request.body;

    // In production: call Sobflous/D17 verify API with transactionId
    // For now: trust the client callback and mark as paid
    const payment = await strapi
      .query('api::payment.payment')
      .findOne({ where: { transactionId, invoiceId: Number(invoiceId) } });

    if (!payment) return ctx.notFound('Transaction introuvable.');

    await strapi.query('api::payment.payment').update({
      where: { id: payment.id },
      data: { status: 'completed' },
    });

    await strapi.query('api::invoice.invoice').update({
      where: { id: Number(invoiceId) },
      data: {
        status: 'paid',
        paymentMethod: payment.method,
        paidAt: new Date().toISOString(),
      },
    });

    // Notification
    try {
      await strapi.entityService.create('api::notification.notification', {
        data: {
          title: 'Paiement en ligne confirmé ✓',
          body: `Votre paiement de ${payment.amount} DT via ${payment.method === 'sobflous' ? 'Sobflous' : 'D17'} a été validé.`,
          type: 'invoice',
          userId: user.id,
          read: false,
          data: { invoiceId },
        },
      });
    } catch (_) {}

    return ctx.send({ data: { status: 'completed', invoiceId } });
  },

  // GET /api/payment-engine/callback  (no auth — called by payment gateway)
  // Query: { ref, success, invoiceId }
  async handleCallback(ctx) {
    const { ref: transactionId, success, invoiceId } = ctx.query;

    if (!transactionId || !invoiceId) return ctx.badRequest('Paramètres manquants.');

    const payment = await strapi
      .query('api::payment.payment')
      .findOne({ where: { transactionId, invoiceId: Number(invoiceId) } });

    if (!payment) return ctx.notFound('Transaction introuvable.');

    const isSuccess = String(success).toLowerCase() === 'true';
    const newStatus = isSuccess ? 'completed' : 'failed';

    await strapi.query('api::payment.payment').update({
      where: { id: payment.id },
      data: { status: newStatus },
    });

    if (isSuccess) {
      await strapi.query('api::invoice.invoice').update({
        where: { id: Number(invoiceId) },
        data: {
          status: 'paid',
          paymentMethod: payment.method,
          paidAt: new Date().toISOString(),
        },
      });
    }

    // Redirect the mobile WebView back to a deep-link or a simple HTML page
    const redirectUrl = isSuccess
      ? `medicare://payment/success?invoiceId=${invoiceId}`
      : `medicare://payment/failed?invoiceId=${invoiceId}`;

    return ctx.redirect(redirectUrl);
  },

  // GET /api/payment-engine/status/:invoiceId
  async getStatus(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const invoiceId = Number(ctx.params.invoiceId);
    const payment = await strapi
      .query('api::payment.payment')
      .findOne({
        where: { invoiceId, patientId: user.id },
        orderBy: { createdAt: 'desc' },
      });

    return ctx.send({ data: payment });
  },
};
