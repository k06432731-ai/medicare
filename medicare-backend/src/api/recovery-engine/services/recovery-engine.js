'use strict';

/**
 * Recovery Engine — Core orchestration service
 * Called by cron tasks and lifecycle hooks.
 */
module.exports = {
  // ── No-show Detection ──────────────────────────────────────────────────────
  async detectNoShows() {
    const now = new Date();
    const windowStart = new Date(now - 90 * 60 * 1000); // 90 min ago
    const windowEnd = new Date(now - 10 * 60 * 1000);   // 10 min ago (grace period)

    // Find confirmed appointments in the window that haven't been completed/cancelled
    const appointments = await strapi.db
      .query('api::appointment.appointment')
      .findMany({
        where: {
          status: 'confirmed',
          appointmentDate: {
            $gte: windowStart.toISOString(),
            $lte: windowEnd.toISOString(),
          },
        },
        populate: ['patient', 'doctor'],
      });

    for (const appt of appointments) {
      // Check if a recovery case already exists for this appointment
      const existing = await strapi.db
        .query('api::recovery-case.recovery-case')
        .findOne({
          where: { appointmentId: appt.id, type: 'noShow' },
        });
      if (existing) continue;

      const patient = appt.patient || {};
      const doctor = appt.doctor || {};
      const firstName = patient.firstName || '';
      const lastName = patient.lastName || '';
      const patientName = `${firstName} ${lastName}`.trim() || patient.username || 'Patient';
      const doctorFirst = doctor.firstName || '';
      const doctorLast = doctor.lastName || '';
      const doctorName = `Dr. ${doctorFirst} ${doctorLast}`.trim();

      // Create recovery case
      const recoveryCase = await strapi.db
        .query('api::recovery-case.recovery-case')
        .create({
          data: {
            type: 'noShow',
            status: 'open',
            priority: 'high',
            patientId: patient.id || appt.patientId,
            patientName,
            patientPhone: patient.phone || null,
            appointmentId: appt.id,
            appointmentDate: appt.appointmentDate,
            doctorName,
            triggerDate: now.toISOString(),
            estimatedValue: 2500, // DA — configurable per clinic
          },
        });

      // Mark appointment as no-show
      await strapi.db.query('api::appointment.appointment').update({
        where: { id: appt.id },
        data: { status: 'no_show' },
      });

      strapi.log.info(
        `[RecoveryEngine] No-show detected: patient ${patientName} (case #${recoveryCase.id})`
      );
    }
  },

  // ── Escalate Stale Cases (no response after 24h) ──────────────────────────
  async escalateStaleCases() {
    const threshold = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const staleCases = await strapi.db
      .query('api::recovery-case.recovery-case')
      .findMany({
        where: {
          status: { $in: ['open', 'inProgress'] },
          triggerDate: { $lt: threshold.toISOString() },
          attempts: { $gte: 1 },
        },
      });

    for (const recoveryCase of staleCases) {
      // Escalate to staff
      await strapi.db.query('api::recovery-case.recovery-case').update({
        where: { id: recoveryCase.id },
        data: { status: 'escalated' },
      });

      // Create staff task
      const existing = await strapi.db.query('api::staff-task.staff-task').findOne({
        where: { recoveryCaseId: recoveryCase.id },
      });
      if (!existing) {
        const dueDate = new Date(Date.now() + 4 * 60 * 60 * 1000); // Due in 4h
        await strapi.db.query('api::staff-task.staff-task').create({
          data: {
            recoveryCaseId: recoveryCase.id,
            patientName: recoveryCase.patientName,
            patientPhone: recoveryCase.patientPhone,
            title: `Contacter ${recoveryCase.patientName} — ${_caseTypeLabel(recoveryCase.type)}`,
            description: `Relance manuelle requise. Type: ${recoveryCase.type}. Déclenchée le ${new Date(recoveryCase.triggerDate).toLocaleString('fr-FR')}.`,
            status: 'pending',
            priority: recoveryCase.priority === 'critical' ? 'critical' : 'high',
            dueDate: dueDate.toISOString(),
            caseType: recoveryCase.type,
          },
        });

        strapi.log.info(
          `[RecoveryEngine] StaffTask created for stale case #${recoveryCase.id}`
        );
      }
    }
  },

  // ── Risk Score Calculation ────────────────────────────────────────────────
  async recalculateRiskScores() {
    // Get all patients (users with role patient)
    const [patientRole] = await strapi.db
      .query('plugin::users-permissions.role')
      .findMany({ where: { type: 'patient' } });

    if (!patientRole) return;

    const patients = await strapi.db
      .query('plugin::users-permissions.user')
      .findMany({ where: { role: patientRole.id }, select: ['id', 'firstName', 'lastName', 'username'] });

    const now = new Date();

    for (const patient of patients) {
      try {
        const signals = {};
        let score = 0;

        // Signal 1: No-shows
        const noShows = await strapi.db.query('api::appointment.appointment').count({
          where: { patientId: patient.id, status: 'no_show' },
        });
        if (noShows > 0) {
          const points = Math.min(noShows * 25, 45);
          score += points;
          signals.noShow = { count: noShows, points };
        }

        // Signal 2: Days since last completed appointment
        const lastCompletedAppt = await strapi.db
          .query('api::appointment.appointment')
          .findOne({
            where: { patientId: patient.id, status: 'completed' },
            orderBy: { appointmentDate: 'desc' },
          });
        const daysSinceLastVisit = lastCompletedAppt
          ? Math.floor((now - new Date(lastCompletedAppt.appointmentDate)) / (1000 * 60 * 60 * 24))
          : 999;

        if (daysSinceLastVisit > 60) {
          score += 15;
          signals.inactivePatient = { days: daysSinceLastVisit, points: 15 };
        } else if (daysSinceLastVisit > 30) {
          score += 8;
          signals.inactivePatient = { days: daysSinceLastVisit, points: 8 };
        }

        // Signal 3: Expired active prescriptions
        const expiredPrescriptions = await strapi.db
          .query('api::prescription.prescription')
          .count({
            where: {
              patientId: patient.id,
              isActive: true,
              endDate: { $lt: now.toISOString() },
            },
          });
        if (expiredPrescriptions > 0) {
          score += 20;
          signals.expiredPrescription = { count: expiredPrescriptions, points: 20 };
        }

        // Signal 4: Open recovery cases
        const openCases = await strapi.db.query('api::recovery-case.recovery-case').count({
          where: { patientId: patient.id, status: { $in: ['open', 'inProgress'] } },
        });
        if (openCases > 0) {
          score += openCases * 10;
          signals.openCases = { count: openCases, points: openCases * 10 };
        }

        score = Math.min(score, 100);
        const level =
          score >= 75 ? 'critical' : score >= 50 ? 'high' : score >= 25 ? 'medium' : 'low';

        const patientName =
          `${patient.firstName || ''} ${patient.lastName || ''}`.trim() ||
          patient.username ||
          'Patient';

        // Upsert risk score
        const existing = await strapi.db.query('api::risk-score.risk-score').findOne({
          where: { patientId: patient.id },
        });

        const scoreData = {
          patientId: patient.id,
          patientName,
          score,
          level,
          noShowCount: noShows,
          daysSinceLastVisit,
          openCasesCount: openCases,
          hasExpiredPrescription: expiredPrescriptions > 0,
          signals,
          calculatedAt: now.toISOString(),
        };

        if (existing) {
          await strapi.db
            .query('api::risk-score.risk-score')
            .update({ where: { id: existing.id }, data: scoreData });
        } else {
          await strapi.db.query('api::risk-score.risk-score').create({ data: scoreData });
        }
      } catch (err) {
        strapi.log.warn(
          `[RecoveryEngine] Risk score failed for patient ${patient.id}: ${err.message}`
        );
      }
    }

    strapi.log.info(`[RecoveryEngine] Risk scores recalculated for ${patients.length} patients`);
  },

  // ── Inactive Patient Detection ────────────────────────────────────────────
  async detectInactivePatients() {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const [patientRole] = await strapi.db
      .query('plugin::users-permissions.role')
      .findMany({ where: { type: 'patient' } });
    if (!patientRole) return;

    const patients = await strapi.db
      .query('plugin::users-permissions.user')
      .findMany({ where: { role: patientRole.id }, select: ['id', 'firstName', 'lastName', 'username', 'phone'] });

    for (const patient of patients) {
      // Check if last activity (appointment/prescription) is older than 30 days
      const lastAppt = await strapi.db.query('api::appointment.appointment').findOne({
        where: { patientId: patient.id },
        orderBy: { appointmentDate: 'desc' },
      });

      const lastActivity = lastAppt ? new Date(lastAppt.appointmentDate) : null;
      if (lastActivity && lastActivity > thirtyDaysAgo) continue;

      // Check if an inactivePatient case already exists in the last 30 days
      const existing = await strapi.db.query('api::recovery-case.recovery-case').findOne({
        where: {
          patientId: patient.id,
          type: 'inactivePatient',
          triggerDate: { $gte: thirtyDaysAgo.toISOString() },
        },
      });
      if (existing) continue;

      const patientName =
        `${patient.firstName || ''} ${patient.lastName || ''}`.trim() ||
        patient.username || 'Patient';

      await strapi.db.query('api::recovery-case.recovery-case').create({
        data: {
          type: 'inactivePatient',
          status: 'open',
          priority: 'medium',
          patientId: patient.id,
          patientName,
          patientPhone: patient.phone || null,
          triggerDate: new Date().toISOString(),
          estimatedValue: 2500,
        },
      });
    }
  },

  // ── Chronic Follow-up Detection ───────────────────────────────────────────
  async detectChronicFollowups() {
    const sevenDaysFromNow = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const now = new Date();

    // Active prescriptions expiring in the next 7 days without a follow-up appointment
    const expiringPrescriptions = await strapi.db
      .query('api::prescription.prescription')
      .findMany({
        where: {
          isActive: true,
          endDate: {
            $gte: now.toISOString(),
            $lte: sevenDaysFromNow.toISOString(),
          },
        },
        select: ['id', 'patientId', 'doctorId', 'endDate'],
      });

    for (const prescription of expiringPrescriptions) {
      if (!prescription.patientId) continue;

      // Check for upcoming appointment
      const upcomingAppt = await strapi.db.query('api::appointment.appointment').findOne({
        where: {
          patientId: prescription.patientId,
          status: { $in: ['pending', 'confirmed'] },
          appointmentDate: { $gte: now.toISOString() },
        },
      });
      if (upcomingAppt) continue;

      // Check if a case already exists
      const existing = await strapi.db.query('api::recovery-case.recovery-case').findOne({
        where: {
          patientId: prescription.patientId,
          type: 'interruptedChronic',
          triggerDate: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString() },
        },
      });
      if (existing) continue;

      const patient = await strapi.db
        .query('plugin::users-permissions.user')
        .findOne({ where: { id: prescription.patientId } });
      if (!patient) continue;

      const patientName =
        `${patient.firstName || ''} ${patient.lastName || ''}`.trim() ||
        patient.username || 'Patient';

      await strapi.db.query('api::recovery-case.recovery-case').create({
        data: {
          type: 'interruptedChronic',
          status: 'open',
          priority: 'high',
          patientId: prescription.patientId,
          patientName,
          patientPhone: patient.phone || null,
          triggerDate: new Date().toISOString(),
          estimatedValue: 2500,
        },
      });
    }
  },
};

function _caseTypeLabel(type) {
  const labels = {
    noShow: 'No-show',
    abandonedBooking: 'Réservation abandonnée',
    inactivePatient: 'Patient inactif',
    interruptedChronic: 'Suivi chronique interrompu',
    incompletePreconsult: 'Pré-consultation incomplète',
    missedCall: 'Appel manqué',
  };
  return labels[type] || type;
}
