'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/recovery-engine/stats',
      handler: 'recovery-engine.getStats',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'GET',
      path: '/recovery-engine/cases',
      handler: 'recovery-engine.getCases',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'PUT',
      path: '/recovery-engine/cases/:id',
      handler: 'recovery-engine.updateCase',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'GET',
      path: '/recovery-engine/staff-tasks',
      handler: 'recovery-engine.getStaffTasks',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'PUT',
      path: '/recovery-engine/staff-tasks/:id',
      handler: 'recovery-engine.updateStaffTask',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'GET',
      path: '/recovery-engine/risk-scores',
      handler: 'recovery-engine.getRiskScores',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'GET',
      path: '/recovery-engine/doctor-view',
      handler: 'recovery-engine.getDoctorView',
      config: { policies: [], middlewares: [] },
    },
    {
      method: 'GET',
      path: '/recovery-engine/patient-risk/:patientId',
      handler: 'recovery-engine.getPatientRisk',
      config: { policies: [], middlewares: [] },
    },
  ],
};
