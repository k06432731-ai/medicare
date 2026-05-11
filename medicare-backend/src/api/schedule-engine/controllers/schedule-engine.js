'use strict';

module.exports = {
  // GET /api/schedule-engine/availability
  async getAvailability(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const slots = await strapi
      .query('api::doctor-availability.doctor-availability')
      .findMany({
        where: { doctorId: user.id },
        orderBy: { dayOfWeek: 'asc' },
      });

    return ctx.send({ data: slots });
  },

  // POST /api/schedule-engine/availability
  // Body: { slots: [{ dayOfWeek, startTime, endTime, isActive }] }
  async setAvailability(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { slots = [] } = ctx.request.body;

    // Replace all existing slots for this doctor
    await strapi
      .query('api::doctor-availability.doctor-availability')
      .deleteMany({ where: { doctorId: user.id } });

    const created = [];
    for (const slot of slots) {
      const entry = await strapi.entityService.create(
        'api::doctor-availability.doctor-availability',
        {
          data: {
            doctorId: user.id,
            dayOfWeek: Number(slot.dayOfWeek),
            startTime: slot.startTime,
            endTime: slot.endTime,
            isActive: slot.isActive !== false,
          },
        }
      );
      created.push(entry);
    }

    return ctx.send({ data: created });
  },

  // GET /api/schedule-engine/blocks
  async getBlocks(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const today = new Date().toISOString().split('T')[0];
    const blocks = await strapi
      .query('api::schedule-block.schedule-block')
      .findMany({
        where: { doctorId: user.id, blockDate: { $gte: today } },
        orderBy: { blockDate: 'asc' },
      });

    return ctx.send({ data: blocks });
  },

  // POST /api/schedule-engine/blocks
  // Body: { blockDate, startTime?, endTime?, reason? }
  async addBlock(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const { blockDate, startTime = '00:00', endTime = '23:59', reason = 'Indisponible' } =
      ctx.request.body;

    if (!blockDate) return ctx.badRequest('blockDate est requis.');

    const block = await strapi.entityService.create(
      'api::schedule-block.schedule-block',
      {
        data: { doctorId: user.id, blockDate, startTime, endTime, reason },
      }
    );

    return ctx.send({ data: block });
  },

  // GET /api/schedule-engine/public-availability?doctorId=X&date=YYYY-MM-DD
  // Returns a doctor's available time slots for a given date (for patient booking).
  // Subtracts existing appointments and blocked periods.
  async getPublicAvailability(ctx) {
    const { doctorId, date } = ctx.query;
    if (!doctorId) return ctx.badRequest('doctorId est requis.');

    const targetDate = date ? new Date(date) : new Date();
    const dayOfWeek = targetDate.getDay(); // 0 = dimanche ... 6 = samedi
    const dateStr = targetDate.toISOString().split('T')[0];

    // 1. Weekly availability slots for this day
    const weeklySlots = await strapi
      .query('api::doctor-availability.doctor-availability')
      .findMany({
        where: {
          doctorId: Number(doctorId),
          dayOfWeek,
          isActive: true,
        },
      });

    if (weeklySlots.length === 0) {
      return ctx.send({ data: { available: false, slots: [] } });
    }

    // 2. Blocks for this date
    const blocks = await strapi
      .query('api::schedule-block.schedule-block')
      .findMany({
        where: { doctorId: Number(doctorId), blockDate: dateStr },
      });

    // If any block covers the whole day, the doctor is unavailable
    const fullDayBlock = blocks.some(
      (b) => b.startTime === '00:00' && b.endTime === '23:59'
    );
    if (fullDayBlock) {
      return ctx.send({ data: { available: false, slots: [] } });
    }

    // 3. Existing confirmed/pending appointments for this date
    const dayStart = new Date(dateStr + 'T00:00:00.000Z').toISOString();
    const dayEnd = new Date(dateStr + 'T23:59:59.999Z').toISOString();
    const bookedAppointments = await strapi.db
      .query('api::appointment.appointment')
      .findMany({
        where: {
          doctor: Number(doctorId),
          appointmentDate: { $gte: dayStart, $lte: dayEnd },
          status: { $in: ['pending', 'confirmed'] },
        },
        select: ['appointmentDate'],
      });

    const bookedTimes = new Set(
      bookedAppointments.map((a) => {
        const d = new Date(a.appointmentDate);
        return `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`;
      })
    );

    // 4. Generate 30-min slots from weekly availability
    const generatedSlots = [];
    for (const slot of weeklySlots) {
      const [startH, startM] = slot.startTime.split(':').map(Number);
      const [endH, endM] = slot.endTime.split(':').map(Number);
      let cur = startH * 60 + startM;
      const end = endH * 60 + endM;

      while (cur + 30 <= end) {
        const hh = String(Math.floor(cur / 60)).padStart(2, '0');
        const mm = String(cur % 60).padStart(2, '0');
        const timeLabel = `${hh}:${mm}`;

        // Skip if blocked or already booked
        const isBlocked = blocks.some(
          (b) => timeLabel >= b.startTime && timeLabel < b.endTime
        );
        if (!isBlocked && !bookedTimes.has(timeLabel)) {
          generatedSlots.push({
            time: timeLabel,
            datetime: `${dateStr}T${timeLabel}:00.000Z`,
          });
        }
        cur += 30;
      }
    }

    return ctx.send({
      data: {
        available: generatedSlots.length > 0,
        date: dateStr,
        doctorId: Number(doctorId),
        slots: generatedSlots,
      },
    });
  },

  // DELETE /api/schedule-engine/blocks/:id
  async removeBlock(ctx) {
    const user = ctx.state.user;
    if (!user) return ctx.unauthorized();

    const blockId = Number(ctx.params.id);
    const block = await strapi
      .query('api::schedule-block.schedule-block')
      .findOne({ where: { id: blockId } });

    if (!block) return ctx.notFound('Blocage introuvable.');
    if (block.doctorId !== user.id) return ctx.forbidden('Accès refusé.');

    await strapi
      .query('api::schedule-block.schedule-block')
      .delete({ where: { id: blockId } });

    return ctx.send({ data: { id: blockId } });
  },
};
