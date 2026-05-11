'use strict';

module.exports = {
  async getStats(ctx) {
    try {
      const [
        totalPatients,
        totalDoctors,
        totalAppointments,
        pendingAppointments,
        confirmedAppointments,
        completedAppointments,
        totalPrescriptions,
        totalInvoices,
        pendingInvoices,
      ] = await Promise.all([
        // Count users with appRole 'patient' (custom field, not Strapi role)
        strapi.db.query('plugin::users-permissions.user').count({
          where: { appRole: 'patient' },
        }),
        // Count users with appRole 'doctor' (custom field, not Strapi role)
        strapi.db.query('plugin::users-permissions.user').count({
          where: { appRole: 'doctor' },
        }),
        strapi.db.query('api::appointment.appointment').count({}),
        strapi.db.query('api::appointment.appointment').count({
          where: { status: 'pending' },
        }),
        strapi.db.query('api::appointment.appointment').count({
          where: { status: 'confirmed' },
        }),
        strapi.db.query('api::appointment.appointment').count({
          where: { status: 'completed' },
        }),
        strapi.db.query('api::prescription.prescription').count({}),
        strapi.db.query('api::invoice.invoice').count({}),
        strapi.db.query('api::invoice.invoice').count({
          where: { status: 'pending' },
        }),
      ]);

      // Today's appointments
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todayAppointments = await strapi.db
        .query('api::appointment.appointment')
        .count({
          where: {
            appointmentDate: {
              $gte: today.toISOString(),
              $lt: tomorrow.toISOString(),
            },
          },
        });

      // Revenue: sum of paid invoices
      const paidInvoices = await strapi.db
        .query('api::invoice.invoice')
        .findMany({
          where: { status: 'paid' },
          select: ['amount'],
        });
      const totalRevenue = paidInvoices.reduce(
        (sum, inv) => sum + (parseFloat(inv.amount) || 0),
        0
      );

      ctx.body = {
        data: {
          totalPatients,
          totalDoctors,
          totalAppointments,
          todayAppointments,
          pendingAppointments,
          confirmedAppointments,
          completedAppointments,
          totalPrescriptions,
          totalInvoices,
          pendingInvoices,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
        },
      };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },
};
