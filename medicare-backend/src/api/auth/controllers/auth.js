'use strict';

module.exports = {
  async medicareRegister(ctx) {
    const {
      username,
      email,
      password,
      appRole = 'patient',
      firstName,
      lastName,
      phone,
      dateOfBirth,
      specialty,
      licenseNumber,
      bio,
      consultationFee,
      isAvailable,
    } = ctx.request.body;

    if (!username || !email || !password) {
      return ctx.badRequest('username, email and password are required');
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) return ctx.badRequest('Invalid email format');
    if (password.length < 6) return ctx.badRequest('Password must be at least 6 characters');
    if (!['patient', 'doctor', 'admin'].includes(appRole)) {
      return ctx.badRequest('appRole must be patient, doctor or admin');
    }

    // Use the users-permissions plugin service to register
    const pluginStore = strapi.store({ type: 'plugin', name: 'users-permissions' });
    const settings = await pluginStore.get({ key: 'advanced' });

    // Check email uniqueness
    const existing = await strapi.query('plugin::users-permissions.user').findOne({
      where: { email: email.toLowerCase() },
    });
    if (existing) {
      return ctx.badRequest('Email already taken');
    }

    // Get default role
    const defaultRole = await strapi.query('plugin::users-permissions.role').findOne({
      where: { type: settings.default_role ?? 'authenticated' },
    });

    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await strapi.query('plugin::users-permissions.user').create({
      data: {
        username,
        email: email.toLowerCase(),
        password: hashedPassword,
        provider: 'local',
        confirmed: true,
        role: defaultRole?.id,
        appRole,
        ...(firstName && { firstName }),
        ...(lastName && { lastName }),
        ...(phone && { phone }),
        ...(dateOfBirth && { dateOfBirth }),
        ...(specialty && { specialty }),
        ...(licenseNumber && { licenseNumber }),
        ...(bio && { bio }),
        ...(consultationFee !== undefined && { consultationFee }),
        ...(isAvailable !== undefined && { isAvailable }),
      },
    });

    const jwt = strapi.plugin('users-permissions').service('jwt').issue({ id: user.id });

    ctx.body = {
      jwt,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        confirmed: user.confirmed,
        appRole: user.appRole,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        specialty: user.specialty,
        isAvailable: user.isAvailable,
      },
    };
  },
};
