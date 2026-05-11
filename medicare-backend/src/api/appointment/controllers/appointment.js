'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::appointment.appointment', ({ strapi }) => ({
  // Create appointment — auto-assign patient from JWT
  async create(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { doctor, appointmentDate, reason, type, notes } = ctx.request.body.data ?? ctx.request.body;

    if (!doctor || !appointmentDate || !reason) {
      return ctx.badRequest('doctor, appointmentDate and reason are required');
    }

    const appointment = await strapi.entityService.create('api::appointment.appointment', {
      data: {
        appointmentDate,
        reason,
        type: type ?? 'in_person',
        status: 'pending',
        notes: notes ?? null,
        patient: user.id,
        doctor: Number(doctor),
      },
      populate: ['doctor', 'patient'],
    });

    return ctx.send({ data: appointment });
  },

  // Find appointments — filtered by current user automatically
  async find(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const fullUser = await strapi.entityService.findOne(
      'plugin::users-permissions.user', user.id
    );
    const appRole = fullUser?.appRole ?? 'patient';

    // Support both ?status=pending and ?filters[status][$eq]=pending
    const statusFilter =
      ctx.query?.filters?.status?.['$eq'] ??
      ctx.query?.['filters[status][$eq]'] ??
      ctx.query?.status ??
      null;

    const where = {};
    if (appRole === 'doctor') {
      where.doctor = { id: { $eq: user.id } };
    } else {
      where.patient = { id: { $eq: user.id } };
    }
    if (statusFilter) {
      where.status = statusFilter;
    }

    const appointments = await strapi.entityService.findMany('api::appointment.appointment', {
      filters: where,
      populate: {
        doctor: { populate: { avatar: true } },
        patient: true,
      },
      sort: { appointmentDate: 'desc' },
      limit: 50,
    });

    return ctx.send({
      data: appointments,
      meta: { total: appointments.length },
    });
  },

  // Update appointment — only owner (patient) or assigned doctor can update
  async update(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { id } = ctx.params;

    const existing = await strapi.entityService.findOne('api::appointment.appointment', id, {
      populate: ['patient', 'doctor'],
    });

    if (!existing) return ctx.notFound('Appointment not found');

    const isPatient = existing.patient?.id === user.id;
    const isDoctor = existing.doctor?.id === user.id;
    if (!isPatient && !isDoctor) return ctx.forbidden('Not your appointment');

    const updateData = ctx.request.body.data ?? ctx.request.body;

    // Patients can only cancel — doctors can change status and add notes
    const fullUser = await strapi.entityService.findOne('plugin::users-permissions.user', user.id);
    const allowedFields = fullUser?.appRole === 'doctor'
      ? ['status', 'doctorNotes', 'endTime']
      : ['status'];

    const safeUpdate = {};
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) safeUpdate[field] = updateData[field];
    }
    if (isPatient && safeUpdate.status && safeUpdate.status !== 'cancelled') {
      return ctx.badRequest('Patients can only cancel appointments');
    }

    const updated = await strapi.entityService.update('api::appointment.appointment', id, {
      data: safeUpdate,
      populate: ['doctor', 'patient'],
    });

    return ctx.send({ data: updated });
  },
}));
