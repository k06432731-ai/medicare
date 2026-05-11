'use strict';

module.exports = {
  register(/*{ strapi }*/) {},

  async bootstrap({ strapi }) {
    await configurePermissions(strapi);
    await seedLaboratories(strapi);
  },
};

async function configurePermissions(strapi) {
  const publicActions = [
    'plugin::users-permissions.auth.callback',
    'plugin::users-permissions.auth.register',
    'plugin::users-permissions.auth.forgotpassword',
    'plugin::users-permissions.auth.resetpassword',
    'api::payment-engine.payment-engine.handlecallback',
    'api::stripe-engine.stripe-engine.webhook',
  ];

  const authenticatedActions = [
    'plugin::users-permissions.user.me',
    'plugin::users-permissions.user.updateme',
    'plugin::users-permissions.user.find',
    'plugin::users-permissions.user.findone',
    'plugin::users-permissions.user.update',
    'api::appointment.appointment.find',
    'api::appointment.appointment.findone',
    'api::appointment.appointment.create',
    'api::appointment.appointment.update',
    'api::appointment.appointment.delete',
    'api::prescription.prescription.find',
    'api::prescription.prescription.findone',
    'api::prescription.prescription.create',
    'api::prescription.prescription.update',
    'api::medical-record.medical-record.find',
    'api::medical-record.medical-record.findone',
    'api::medical-record.medical-record.create',
    'api::medical-record.medical-record.update',
    'api::invoice.invoice.find',
    'api::invoice.invoice.findone',
    'api::invoice.invoice.create',
    'api::invoice.invoice.update',
    'api::laboratory.laboratory.find',
    'api::laboratory.laboratory.findone',
    'api::lab-order.lab-order.find',
    'api::lab-order.lab-order.findone',
    'api::lab-order.lab-order.create',
    'api::lab-order.lab-order.update',
    'api::admin-stats.admin-stats.getstats',
    'plugin::users-permissions.auth.changepassword',
    // Recovery Engine
    'api::recovery-case.recovery-case.find',
    'api::recovery-case.recovery-case.findone',
    'api::recovery-case.recovery-case.create',
    'api::recovery-case.recovery-case.update',
    'api::risk-score.risk-score.find',
    'api::risk-score.risk-score.findone',
    'api::staff-task.staff-task.find',
    'api::staff-task.staff-task.findone',
    'api::staff-task.staff-task.update',
    'api::recovery-engine.recovery-engine.getstats',
    'api::recovery-engine.recovery-engine.getcases',
    'api::recovery-engine.recovery-engine.updatecase',
    'api::recovery-engine.recovery-engine.getstafftasks',
    'api::recovery-engine.recovery-engine.updatestafftask',
    'api::recovery-engine.recovery-engine.getriskscores',
    'api::recovery-engine.recovery-engine.getdoctorview',
    'api::recovery-engine.recovery-engine.getpatientrisk',
    // Notification Engine
    'api::notification.notification.find',
    'api::notification.notification.findone',
    'api::notification-engine.notification-engine.getmynotifications',
    'api::notification-engine.notification-engine.getunreadcount',
    'api::notification-engine.notification-engine.markread',
    'api::notification-engine.notification-engine.markallread',
    // AI Doctor
    'api::ai-doctor.ai-doctor.prescriptiondraft',
    'api::ai-doctor.ai-doctor.summarizepatient',
    'api::ai-doctor.ai-doctor.diagnosticsuggestions',
    // Messaging Engine
    'api::conversation.conversation.find',
    'api::conversation.conversation.findone',
    'api::message.message.find',
    'api::message.message.findone',
    'api::messaging-engine.messaging-engine.getconversations',
    'api::messaging-engine.messaging-engine.findorcreate',
    'api::messaging-engine.messaging-engine.getmessages',
    'api::messaging-engine.messaging-engine.sendmessage',
    'api::messaging-engine.messaging-engine.markread',
    // Schedule Engine (Sprint 17)
    'api::schedule-engine.schedule-engine.getavailability',
    'api::schedule-engine.schedule-engine.setavailability',
    'api::schedule-engine.schedule-engine.getblocks',
    'api::schedule-engine.schedule-engine.addblock',
    'api::schedule-engine.schedule-engine.removeblock',
    'api::doctor-availability.doctor-availability.find',
    'api::doctor-availability.doctor-availability.findone',
    'api::doctor-availability.doctor-availability.create',
    'api::doctor-availability.doctor-availability.update',
    'api::doctor-availability.doctor-availability.delete',
    'api::schedule-block.schedule-block.find',
    'api::schedule-block.schedule-block.findone',
    'api::schedule-block.schedule-block.create',
    'api::schedule-block.schedule-block.delete',
    // Payment Engine — méthodes directes (Sprint 18)
    'api::payment-engine.payment-engine.initpayment',
    'api::payment-engine.payment-engine.verifypayment',
    'api::payment-engine.payment-engine.getstatus',
    'api::payment.payment.find',
    'api::payment.payment.findone',
    'api::payment.payment.create',
    'api::payment.payment.update',
    // Stripe Engine (Sprint 18)
    'api::stripe-engine.stripe-engine.createintent',
    'api::stripe-engine.stripe-engine.confirmpayment',
    // Upload (Sprint 16 — avatar)
    'plugin::upload.content-api.upload',
    'plugin::upload.content-api.find',
    'plugin::upload.content-api.findone',
  ];

  try {
    const [publicRole] = await strapi.query('plugin::users-permissions.role').findMany({
      where: { type: 'public' },
    });
    const [authRole] = await strapi.query('plugin::users-permissions.role').findMany({
      where: { type: 'authenticated' },
    });

    if (publicRole) {
      await enablePermissions(strapi, publicRole.id, publicActions);
    }
    if (authRole) {
      await enablePermissions(strapi, authRole.id, authenticatedActions);
    }

    strapi.log.info('✅ Medicare permissions configured');
  } catch (err) {
    strapi.log.warn('⚠️  Could not configure permissions:', err.message);
  }
}

async function enablePermissions(strapi, roleId, actions) {
  for (const action of actions) {
    const existing = await strapi.query('plugin::users-permissions.permission').findOne({
      where: { action, role: roleId },
    });

    if (!existing) {
      await strapi.query('plugin::users-permissions.permission').create({
        data: { action, role: roleId, enabled: true },
      });
    } else if (!existing.enabled) {
      await strapi.query('plugin::users-permissions.permission').update({
        where: { id: existing.id },
        data: { enabled: true },
      });
    }
  }
}

async function seedLaboratories(strapi) {
  try {
    const count = await strapi.query('api::laboratory.laboratory').count();
    if (count > 0) return;

    const labs = [
      {
        name: 'Laboratoire Pasteur',
        type: 'laboratory',
        address: '13 Avenue Habib Bourguiba, Tunis',
        phone: '+216 71 340 220',
        email: 'contact@labo-pasteur.tn',
        description: 'Laboratoire d\'analyses médicales polyvalent — hématologie, biochimie, microbiologie.',
        openingHours: 'Lun–Sam : 07h00–18h00',
        isActive: true,
      },
      {
        name: 'Clinique Les Oliviers',
        type: 'clinic',
        address: '28 Rue de Marseille, Tunis',
        phone: '+216 71 792 600',
        email: 'contact@clinique-oliviers.tn',
        description: 'Clinique médicale avec plateau technique complet : analyses, imagerie et consultations spécialisées.',
        openingHours: 'Lun–Dim : 08h00–20h00',
        isActive: true,
      },
      {
        name: 'Centre d\'Imagerie Ibn Khaldoun',
        type: 'radiology',
        address: '5 Rue Ibn Khaldoun, Sousse',
        phone: '+216 73 220 410',
        email: 'rdv@imagerie-ibnkhaldoun.tn',
        description: 'Centre de radiologie numérique : radiographie, échographie, scanner et IRM.',
        openingHours: 'Lun–Ven : 08h00–17h00',
        isActive: true,
      },
      {
        name: 'CHU Habib Bourguiba',
        type: 'hospital',
        address: 'Avenue Farhat Hached, Sfax',
        phone: '+216 74 241 833',
        email: 'labo@chu-sfax.tn',
        description: 'Laboratoire hospitalier universitaire — urgences et analyses spécialisées 24h/24.',
        openingHours: '24h/24 — 7j/7',
        isActive: true,
      },
    ];

    for (const lab of labs) {
      await strapi.entityService.create('api::laboratory.laboratory', { data: lab });
    }

    strapi.log.info('✅ Laboratories seeded (4 entries)');
  } catch (err) {
    strapi.log.warn('⚠️  Could not seed laboratories:', err.message);
  }
}
