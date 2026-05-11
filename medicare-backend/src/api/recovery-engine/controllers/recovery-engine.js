'use strict';

module.exports = {
  // ── GET /recovery-engine/stats ────────────────────────────────────────────
  async getStats(ctx) {
    try {
      const [
        openCases,
        inProgressCases,
        recoveredCases,
        escalatedCases,
        pendingTasks,
        overdueTasks,
        criticalScores,
        highScores,
      ] = await Promise.all([
        strapi.db.query('api::recovery-case.recovery-case').count({ where: { status: 'open' } }),
        strapi.db.query('api::recovery-case.recovery-case').count({ where: { status: 'inProgress' } }),
        strapi.db.query('api::recovery-case.recovery-case').count({ where: { status: 'recovered' } }),
        strapi.db.query('api::recovery-case.recovery-case').count({ where: { status: 'escalated' } }),
        strapi.db.query('api::staff-task.staff-task').count({ where: { status: 'pending' } }),
        strapi.db.query('api::staff-task.staff-task').count({
          where: { status: 'pending', dueDate: { $lt: new Date().toISOString() } },
        }),
        strapi.db.query('api::risk-score.risk-score').count({ where: { level: 'critical' } }),
        strapi.db.query('api::risk-score.risk-score').count({ where: { level: 'high' } }),
      ]);

      // Today no-shows
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const todayEnd = new Date();
      todayEnd.setHours(23, 59, 59, 999);
      const todayNoShows = await strapi.db.query('api::recovery-case.recovery-case').count({
        where: {
          type: 'noShow',
          triggerDate: { $gte: todayStart.toISOString(), $lte: todayEnd.toISOString() },
        },
      });

      // Recovery rate (last 7 days)
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const [totalRecent, recoveredRecent] = await Promise.all([
        strapi.db.query('api::recovery-case.recovery-case').count({
          where: { triggerDate: { $gte: sevenDaysAgo.toISOString() } },
        }),
        strapi.db.query('api::recovery-case.recovery-case').count({
          where: { status: 'recovered', triggerDate: { $gte: sevenDaysAgo.toISOString() } },
        }),
      ]);
      const recoveryRate = totalRecent > 0 ? Math.round((recoveredRecent / totalRecent) * 100) : 0;

      // Revenue recovered (estimated value of recovered cases)
      const recoveredWithValue = await strapi.db
        .query('api::recovery-case.recovery-case')
        .findMany({
          where: { status: 'recovered', triggerDate: { $gte: sevenDaysAgo.toISOString() } },
          select: ['estimatedValue'],
        });
      const revenueRecovered = recoveredWithValue.reduce(
        (sum, c) => sum + (parseFloat(c.estimatedValue) || 0),
        0
      );

      ctx.body = {
        data: {
          openCases,
          inProgressCases,
          recoveredCases,
          escalatedCases,
          todayNoShows,
          pendingTasks,
          overdueTasks,
          criticalScores,
          highScores,
          recoveryRate,
          revenueRecovered: Math.round(revenueRecovered * 100) / 100,
          totalActiveCases: openCases + inProgressCases + escalatedCases,
        },
      };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── GET /recovery-engine/cases ────────────────────────────────────────────
  async getCases(ctx) {
    try {
      const { status, type, priority, page = 1, pageSize = 20 } = ctx.query;
      const where = {};
      if (status) where.status = status;
      if (type) where.type = type;
      if (priority) where.priority = priority;

      const [cases, total] = await Promise.all([
        strapi.db.query('api::recovery-case.recovery-case').findMany({
          where,
          orderBy: { triggerDate: 'desc' },
          limit: parseInt(pageSize),
          offset: (parseInt(page) - 1) * parseInt(pageSize),
        }),
        strapi.db.query('api::recovery-case.recovery-case').count({ where }),
      ]);

      ctx.body = {
        data: cases,
        meta: { total, page: parseInt(page), pageSize: parseInt(pageSize) },
      };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── PUT /recovery-engine/cases/:id ────────────────────────────────────────
  async updateCase(ctx) {
    try {
      const { id } = ctx.params;
      const { status, notes, channel } = ctx.request.body;
      const updateData = {};
      if (status) {
        updateData.status = status;
        if (status === 'recovered') updateData.recoveredAt = new Date().toISOString();
        if (status === 'closed') updateData.closedAt = new Date().toISOString();
      }
      if (notes !== undefined) updateData.notes = notes;
      if (channel) updateData.channel = channel;

      const updated = await strapi.db
        .query('api::recovery-case.recovery-case')
        .update({ where: { id }, data: updateData });

      ctx.body = { data: updated };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── GET /recovery-engine/staff-tasks ─────────────────────────────────────
  async getStaffTasks(ctx) {
    try {
      const { status = 'pending', page = 1, pageSize = 30 } = ctx.query;
      const where = {};
      if (status !== 'all') where.status = status;

      const [tasks, total] = await Promise.all([
        strapi.db.query('api::staff-task.staff-task').findMany({
          where,
          orderBy: [{ priority: 'desc' }, { dueDate: 'asc' }],
          limit: parseInt(pageSize),
          offset: (parseInt(page) - 1) * parseInt(pageSize),
        }),
        strapi.db.query('api::staff-task.staff-task').count({ where }),
      ]);

      ctx.body = { data: tasks, meta: { total } };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── PUT /recovery-engine/staff-tasks/:id ─────────────────────────────────
  async updateStaffTask(ctx) {
    try {
      const { id } = ctx.params;
      const { status } = ctx.request.body;
      const updateData = { status };
      if (status === 'done') updateData.completedAt = new Date().toISOString();

      const updated = await strapi.db
        .query('api::staff-task.staff-task')
        .update({ where: { id }, data: updateData });

      ctx.body = { data: updated };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── GET /recovery-engine/risk-scores ─────────────────────────────────────
  async getRiskScores(ctx) {
    try {
      const { level, page = 1, pageSize = 20 } = ctx.query;
      const where = {};
      if (level) where.level = level;

      const scores = await strapi.db.query('api::risk-score.risk-score').findMany({
        where,
        orderBy: { score: 'desc' },
        limit: parseInt(pageSize),
        offset: (parseInt(page) - 1) * parseInt(pageSize),
      });

      ctx.body = { data: scores };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── GET /recovery-engine/doctor-view ─────────────────────────────────────
  // Returns open recovery cases for patients of the requesting doctor
  async getDoctorView(ctx) {
    try {
      const userId = ctx.state?.user?.id;
      if (!userId) {
        ctx.status = 401;
        ctx.body = { error: { message: 'Unauthorized' } };
        return;
      }

      // Get appointments for this doctor to find their patient IDs
      // patient is a relation → must populate, not select
      const appointments = await strapi.db
        .query('api::appointment.appointment')
        .findMany({
          where: { doctor: userId },
          populate: { patient: { select: ['id'] } },
        });

      const patientIds = [...new Set(appointments.map((a) => a.patient?.id).filter(Boolean))];

      if (patientIds.length === 0) {
        ctx.body = { data: { cases: [], riskScores: [] } };
        return;
      }

      const [cases, riskScores] = await Promise.all([
        strapi.db.query('api::recovery-case.recovery-case').findMany({
          where: {
            patientId: { $in: patientIds },
            status: { $in: ['open', 'inProgress', 'escalated'] },
          },
          orderBy: { triggerDate: 'desc' },
          limit: 10,
        }),
        strapi.db.query('api::risk-score.risk-score').findMany({
          where: {
            patientId: { $in: patientIds },
            level: { $in: ['high', 'critical'] },
          },
          orderBy: { score: 'desc' },
          limit: 10,
        }),
      ]);

      ctx.body = { data: { cases, riskScores } };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },

  // ── GET /recovery-engine/patient-risk/:patientId ──────────────────────────
  async getPatientRisk(ctx) {
    try {
      const { patientId } = ctx.params;

      const [riskScore, openCases] = await Promise.all([
        strapi.db.query('api::risk-score.risk-score').findOne({
          where: { patientId: parseInt(patientId) },
          orderBy: { calculatedAt: 'desc' },
        }),
        strapi.db.query('api::recovery-case.recovery-case').findMany({
          where: {
            patientId: parseInt(patientId),
            status: { $in: ['open', 'inProgress'] },
          },
          orderBy: { triggerDate: 'desc' },
        }),
      ]);

      ctx.body = { data: { riskScore, openCases } };
    } catch (err) {
      ctx.status = 500;
      ctx.body = { error: { message: err.message } };
    }
  },
};
