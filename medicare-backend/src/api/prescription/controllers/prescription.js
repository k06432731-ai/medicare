'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::prescription.prescription', ({ strapi }) => ({
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    const appRole = fullUser?.appRole ?? 'patient';

    const where = {};
    if (appRole === 'doctor') {
      where.doctor = { id: { $eq: user.id } };
      // Allow doctor to filter by specific patient
      const patientId = ctx.query?.patientId;
      if (patientId) where.patient = { id: { $eq: Number(patientId) } };
    } else {
      where.patient = { id: { $eq: user.id } };
    }

    const statusFilter = ctx.query?.status ?? null;
    if (statusFilter) where.status = statusFilter;

    const prescriptions = await strapi.entityService.findMany('api::prescription.prescription', {
      filters: where,
      populate: { doctor: true, patient: true, appointment: true },
      sort: { issuedDate: 'desc' },
      limit: 50,
    });

    return ctx.send({ data: prescriptions, meta: { total: prescriptions.length } });
  },

  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    if (fullUser?.appRole !== 'doctor') return ctx.forbidden('Only doctors can create prescriptions');

    const { patient, medications, issuedDate, expiryDate, status, instructions, diagnosis, appointment } =
      ctx.request.body.data ?? ctx.request.body;

    if (!patient || !medications || !issuedDate) {
      return ctx.badRequest('patient, medications and issuedDate are required');
    }

    const prescription = await strapi.entityService.create('api::prescription.prescription', {
      data: {
        issuedDate,
        expiryDate: expiryDate ?? null,
        status: status ?? 'active',
        medications,
        instructions: instructions ?? null,
        diagnosis: diagnosis ?? null,
        patient: Number(patient),
        doctor: user.id,
        ...(appointment && { appointment: Number(appointment) }),
      },
      populate: { doctor: true, patient: true, appointment: true },
    });

    return ctx.send({ data: prescription });
  },
}));
