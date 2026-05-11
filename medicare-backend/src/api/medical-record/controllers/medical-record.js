'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::medical-record.medical-record', ({ strapi }) => ({
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

    const typeFilter = ctx.query?.type ?? null;
    if (typeFilter) where.type = typeFilter;

    const records = await strapi.entityService.findMany('api::medical-record.medical-record', {
      filters: where,
      populate: { doctor: true, patient: true },
      sort: { date: 'desc' },
      limit: 50,
    });

    return ctx.send({ data: records, meta: { total: records.length } });
  },

  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    if (fullUser?.appRole !== 'doctor') return ctx.forbidden('Only doctors can create medical records');

    const { patient, title, type, date, description, results, isPrivate } =
      ctx.request.body.data ?? ctx.request.body;

    if (!patient || !title || !type || !date) {
      return ctx.badRequest('patient, title, type and date are required');
    }

    const record = await strapi.entityService.create('api::medical-record.medical-record', {
      data: {
        title,
        type,
        date,
        description: description ?? null,
        results: results ?? null,
        isPrivate: isPrivate ?? false,
        patient: Number(patient),
        doctor: user.id,
      },
      populate: { doctor: true, patient: true },
    });

    return ctx.send({ data: record });
  },
}));
