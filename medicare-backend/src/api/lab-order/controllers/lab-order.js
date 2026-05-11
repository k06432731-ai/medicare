'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::lab-order.lab-order', ({ strapi }) => ({

  // GET /lab-orders — patient sees own, doctor sees all theirs (optional ?patientId=X)
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

    const orders = await strapi.entityService.findMany('api::lab-order.lab-order', {
      filters: where,
      populate: { laboratory: true, patient: true, doctor: true },
      sort: { orderedAt: 'desc' },
      limit: 50,
    });

    return ctx.send({ data: orders, meta: { total: orders.length } });
  },

  // POST /lab-orders — only doctors
  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    if (fullUser?.appRole !== 'doctor') return ctx.forbidden('Only doctors can create lab orders');

    const body = ctx.request.body.data ?? ctx.request.body;
    const { patient, laboratory, tests, totalAmount, orderedAt, notes } = body;

    if (!patient || !laboratory || !tests || !orderedAt) {
      return ctx.badRequest('patient, laboratory, tests and orderedAt are required');
    }

    const order = await strapi.entityService.create('api::lab-order.lab-order', {
      data: {
        status: 'pending',
        tests,
        totalAmount: Number(totalAmount) || 0,
        orderedAt,
        notes: notes ?? null,
        patient: Number(patient),
        doctor: user.id,
        laboratory: Number(laboratory),
      },
      populate: { laboratory: true, patient: true, doctor: true },
    });

    // Auto-create invoice for lab order
    if (totalAmount && Number(totalAmount) > 0) {
      await strapi.entityService.create('api::invoice.invoice', {
        data: {
          amount: Number(totalAmount),
          type: 'lab_test',
          status: 'pending',
          description: `Analyses — ${order.laboratory?.name ?? 'Laboratoire'}`,
          patient: Number(patient),
          doctor: user.id,
          labOrder: order.id,
        },
      });
    }

    return ctx.send({ data: order });
  },

  // PUT /lab-orders/:id — doctor updates status/results
  async update(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { id } = ctx.params;
    const existing = await strapi.entityService.findOne('api::lab-order.lab-order', id, {
      populate: ['patient', 'doctor'],
    });

    if (!existing) return ctx.notFound('Lab order not found');

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    const appRole = fullUser?.appRole ?? 'patient';
    if (appRole !== 'doctor' || existing.doctor?.id !== user.id) {
      return ctx.forbidden('Only the prescribing doctor can update lab orders');
    }

    const body = ctx.request.body.data ?? ctx.request.body;
    const updateData = {};
    const allowed = ['status', 'results', 'completedAt', 'notes'];
    for (const f of allowed) {
      if (body[f] !== undefined) updateData[f] = body[f];
    }
    if (body.status === 'completed' && !updateData.completedAt) {
      updateData.completedAt = new Date().toISOString();
    }

    const updated = await strapi.entityService.update('api::lab-order.lab-order', id, {
      data: updateData,
      populate: { laboratory: true, patient: true, doctor: true },
    });

    return ctx.send({ data: updated });
  },
}));
