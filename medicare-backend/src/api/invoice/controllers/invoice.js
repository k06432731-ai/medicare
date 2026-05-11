'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::invoice.invoice', ({ strapi }) => ({

  // GET /invoices — patient sees own, doctor sees patients' invoices
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    const appRole = fullUser?.appRole ?? 'patient';

    const where = {};
    if (appRole === 'doctor') {
      where.doctor = { id: { $eq: user.id } };
      const patientId = ctx.query?.patientId;
      if (patientId) where.patient = { id: { $eq: Number(patientId) } };
    } else {
      where.patient = { id: { $eq: user.id } };
    }

    const invoices = await strapi.entityService.findMany('api::invoice.invoice', {
      filters: where,
      populate: { doctor: true, patient: true, appointment: true, labOrder: true },
      sort: { createdAt: 'desc' },
      limit: 50,
    });

    return ctx.send({ data: invoices, meta: { total: invoices.length } });
  },

  // POST /invoices — doctor creates invoice for a patient
  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    if (fullUser?.appRole !== 'doctor') return ctx.forbidden('Only doctors can create invoices');

    const body = ctx.request.body.data ?? ctx.request.body;
    const { patient, amount, type, description, dueDate, appointment, labOrder } = body;

    if (!patient || !amount || !type) {
      return ctx.badRequest('patient, amount and type are required');
    }

    const invoice = await strapi.entityService.create('api::invoice.invoice', {
      data: {
        amount: Number(amount),
        type,
        status: 'pending',
        description: description ?? null,
        dueDate: dueDate ?? null,
        patient: Number(patient),
        doctor: user.id,
        ...(appointment && { appointment: Number(appointment) }),
        ...(labOrder && { labOrder: Number(labOrder) }),
      },
      populate: { doctor: true, patient: true },
    });

    return ctx.send({ data: invoice });
  },

  // PUT /invoices/:id — patient pays, doctor can cancel
  async update(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { id } = ctx.params;
    const existing = await strapi.entityService.findOne('api::invoice.invoice', id, {
      populate: ['patient', 'doctor'],
    });

    if (!existing) return ctx.notFound('Invoice not found');

    const isPatient = existing.patient?.id === user.id;
    const isDoctor = existing.doctor?.id === user.id;
    if (!isPatient && !isDoctor) return ctx.forbidden('Not your invoice');

    const body = ctx.request.body.data ?? ctx.request.body;

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    const appRole = fullUser?.appRole ?? 'patient';

    let updateData = {};
    if (appRole === 'patient') {
      // Patient can only mark as paid
      if (body.status === 'paid' && body.paymentMethod) {
        updateData = {
          status: 'paid',
          paymentMethod: body.paymentMethod,
          paidAt: new Date().toISOString(),
        };
      } else {
        return ctx.badRequest('Patient can only pay an invoice (status: paid + paymentMethod required)');
      }
    } else {
      // Doctor can update status, description
      const allowed = ['status', 'description', 'dueDate'];
      for (const f of allowed) {
        if (body[f] !== undefined) updateData[f] = body[f];
      }
    }

    const updated = await strapi.entityService.update('api::invoice.invoice', id, {
      data: updateData,
      populate: { doctor: true, patient: true },
    });

    return ctx.send({ data: updated });
  },
}));
