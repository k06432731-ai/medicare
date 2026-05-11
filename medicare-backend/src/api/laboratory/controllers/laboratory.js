'use strict';
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::laboratory.laboratory', ({ strapi }) => ({

  // GET /laboratories — any authenticated user can browse active labs
  async find(ctx) {
    if (!ctx.state.user) return ctx.unauthorized();

    const typeFilter = ctx.query?.type ?? null;
    const where = { isActive: { $eq: true } };
    if (typeFilter) where.type = { $eq: typeFilter };

    const labs = await strapi.entityService.findMany('api::laboratory.laboratory', {
      filters: where,
      sort: { name: 'asc' },
      limit: 200,
    });

    return ctx.send({ data: labs, meta: { total: labs.length } });
  },

  // GET /laboratories/:id
  async findOne(ctx) {
    if (!ctx.state.user) return ctx.unauthorized();
    const { id } = ctx.params;
    const lab = await strapi.entityService.findOne('api::laboratory.laboratory', id);
    if (!lab) return ctx.notFound();
    return ctx.send({ data: lab });
  },
}));
