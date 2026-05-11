'use strict';

module.exports = {
  routes: [
    {
      method: 'POST',
      path: '/auth/medicare-register',
      handler: 'auth.medicareRegister',
      config: {
        auth: false,
        policies: [],
        middlewares: [],
      },
    },
  ],
};
