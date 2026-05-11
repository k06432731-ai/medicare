'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/ai-doctor/prescription-draft',
      handler: 'ai-doctor.prescriptionDraft',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/ai-doctor/summarize-patient',
      handler: 'ai-doctor.summarizePatient',
      config: { policies: [] },
    },
    {
      method: 'POST',
      path: '/ai-doctor/diagnostic-suggestions',
      handler: 'ai-doctor.diagnosticSuggestions',
      config: { policies: [] },
    },
  ],
};
