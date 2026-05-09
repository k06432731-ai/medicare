import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/availability_model.dart';
import '../../data/models/schedule_block_model.dart';
import '../../providers/schedule_provider.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mon Agenda',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.doctorColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.doctorColor,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Calendrier'),
            Tab(icon: Icon(Icons.access_time_rounded), text: 'Disponibilités'),
            Tab(icon: Icon(Icons.block_rounded), text: 'Blocages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _CalendarTab(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected, focused) =>
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
          ),
          const _AvailabilityTab(),
          const _BlocksTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Calendar ───────────────────────────────────────────────────────────

class _CalendarTab extends ConsumerWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime, DateTime) onDaySelected;

  const _CalendarTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockState = ref.watch(scheduleBlockProvider);
    final availState = ref.watch(availabilityProvider);
    final blockedDates =
        (ref.read(scheduleBlockProvider.notifier)).blockedDates;

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            onDaySelected: onDaySelected,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
            // Mark blocked days
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, focDay) {
                final isBlocked = blockedDates.any((d) => isSameDay(d, day));
                if (isBlocked) {
                  return _DayCell(day: day, color: AppColors.error.withValues(alpha: 0.15), textColor: AppColors.error);
                }
                // Check if doctor is available on this weekday
                final dayIdx = day.weekday - 1; // 0=Mon
                if (availState.slots.isNotEmpty) {
                  final slot = availState.slots.firstWhere(
                    (s) => s.dayOfWeek == dayIdx,
                    orElse: () => AvailabilityModel(doctorId: 0, dayOfWeek: dayIdx, startTime: '08:00', endTime: '18:00', isActive: false),
                  );
                  if (slot.isActive) {
                    return _DayCell(
                      day: day,
                      color: AppColors.success.withValues(alpha: 0.1),
                      textColor: AppColors.textPrimary,
                    );
                  }
                }
                return null;
              },
              selectedBuilder: (ctx, day, _) =>
                  _DayCell(day: day, color: AppColors.doctorColor, textColor: Colors.white, bold: true),
              todayBuilder: (ctx, day, _) =>
                  _DayCell(day: day, color: AppColors.doctorColor.withValues(alpha: 0.2), textColor: AppColors.doctorColor, bold: true),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _LegendDot(color: AppColors.success.withValues(alpha: 0.5), label: 'Disponible'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.error.withValues(alpha: 0.5), label: 'Bloqué'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.doctorColor, label: "Aujourd'hui"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Selected day info
        if (selectedDay != null)
          Expanded(
            child: _SelectedDayPanel(
              day: selectedDay!,
              blocks: blockState.blocks
                  .where((b) => isSameDay(b.blockDate, selectedDay!))
                  .toList(),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Text(
                'Sélectionnez un jour pour voir les détails',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color color;
  final Color textColor;
  final bool bold;

  const _DayCell({
    required this.day,
    required this.color,
    required this.textColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}

class _SelectedDayPanel extends StatelessWidget {
  final DateTime day;
  final List<ScheduleBlockModel> blocks;

  const _SelectedDayPanel({required this.day, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(fmt.format(day),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        if (blocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success),
                const SizedBox(width: 8),
                Text('Journée disponible',
                    style: GoogleFonts.poppins(color: AppColors.success)),
              ],
            ),
          )
        else
          ...blocks.map(
            (b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.isFullDay ? 'Journée bloquée' : '${b.startTime} – ${b.endTime}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: AppColors.error)),
                        if (b.reason != null && b.reason!.isNotEmpty)
                          Text(b.reason!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tab 2: Weekly Availability ────────────────────────────────────────────────

class _AvailabilityTab extends ConsumerWidget {
  const _AvailabilityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availabilityProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.slots.length,
            itemBuilder: (context, i) {
              final slot = state.slots[i];
              return _SlotCard(
                slot: slot,
                onChanged: (updated) => ref
                    .read(availabilityProvider.notifier)
                    .updateSlot(slot.dayOfWeek, updated),
                onTimeTap: () =>
                    _pickTimes(context, ref, slot),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final ok = await ref
                          .read(availabilityProvider.notifier)
                          .save();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Disponibilités enregistrées ✓'
                              : 'Erreur d\'enregistrement'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
              icon: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(state.isSaving ? 'Enregistrement…' : 'Enregistrer',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTimes(
      BuildContext context, WidgetRef ref, AvailabilityModel slot) async {
    TimeOfDay? start = _parseTime(slot.startTime);
    TimeOfDay? end = _parseTime(slot.endTime);

    start = await showTimePicker(
      context: context,
      initialTime: start,
      helpText: 'Heure de début',
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (start == null || !context.mounted) return;

    end = await showTimePicker(
      context: context,
      initialTime: end,
      helpText: 'Heure de fin',
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (end == null) return;

    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    ref
        .read(availabilityProvider.notifier)
        .updateSlot(slot.dayOfWeek, slot.copyWith(startTime: startStr, endTime: endStr));
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }
}

class _SlotCard extends StatelessWidget {
  final AvailabilityModel slot;
  final ValueChanged<AvailabilityModel> onChanged;
  final VoidCallback onTimeTap;

  const _SlotCard({
    required this.slot,
    required this.onChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = AvailabilityModel.dayLabelsFull[slot.dayOfWeek];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: slot.isActive
              ? AppColors.doctorColor.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Day indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: slot.isActive
                    ? AppColors.doctorColor
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                AvailabilityModel.dayLabels[slot.dayOfWeek],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: slot.isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayLabel,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: slot.isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
                  if (slot.isActive)
                    GestureDetector(
                      onTap: onTimeTap,
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.doctorColor),
                          const SizedBox(width: 4),
                          Text(
                            '${slot.startTime} – ${slot.endTime}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.doctorColor),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_rounded,
                              size: 12, color: AppColors.doctorColor),
                        ],
                      ),
                    )
                  else
                    Text('Fermé',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: slot.isActive,
              onChanged: (v) => onChanged(slot.copyWith(isActive: v)),
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.doctorColor
                    : null,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.doctorColor.withValues(alpha: 0.3)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 3: Blocks ─────────────────────────────────────────────────────────────

class _BlocksTab extends ConsumerStatefulWidget {
  const _BlocksTab();

  @override
  ConsumerState<_BlocksTab> createState() => _BlocksTabState();
}

class _BlocksTabState extends ConsumerState<_BlocksTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleBlockProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Add block button
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _showAddBlockSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un blocage'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (state.blocks.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 56,
                      color: AppColors.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Aucun blocage planifié',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Votre agenda est entièrement disponible',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.blocks.length,
              itemBuilder: (context, i) => _BlockTile(
                block: state.blocks[i],
                onDelete: () => _confirmDelete(context, state.blocks[i]),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddBlockSheet(BuildContext context) async {
    DateTime? picked;
    final startCtrl = TextEditingController(text: '00:00');
    final endCtrl = TextEditingController(text: '23:59');
    final reasonCtrl = TextEditingController(text: 'Indisponible');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Text('Ajouter un blocage',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setSheet(() => picked = d);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: picked != null
                            ? AppColors.doctorColor
                            : AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18,
                          color: picked != null
                              ? AppColors.doctorColor
                              : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                          picked != null
                              ? DateFormat('dd/MM/yyyy').format(picked!)
                              : 'Choisir une date *',
                          style: TextStyle(
                              color: picked != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Début (HH:mm)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Fin (HH:mm)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Motif',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: picked == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final ok = await ref
                              .read(scheduleBlockProvider.notifier)
                              .addBlock(
                                date: picked!,
                                startTime: startCtrl.text.isNotEmpty
                                    ? startCtrl.text
                                    : '00:00',
                                endTime: endCtrl.text.isNotEmpty
                                    ? endCtrl.text
                                    : '23:59',
                                reason: reasonCtrl.text.isNotEmpty
                                    ? reasonCtrl.text
                                    : 'Indisponible',
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  ok ? 'Blocage ajouté ✓' : 'Erreur'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirmer le blocage',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ScheduleBlockModel block) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce blocage ?'),
        content: Text(
            '${DateFormat('dd/MM/yyyy').format(block.blockDate)} — ${block.reason ?? ''}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true && block.id != null) {
      await ref
          .read(scheduleBlockProvider.notifier)
          .removeBlock(block.id!);
    }
  }
}

class _BlockTile extends StatelessWidget {
  final ScheduleBlockModel block;
  final VoidCallback onDelete;

  const _BlockTile({required this.block, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM yyyy', 'fr_FR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.block_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmt.format(block.blockDate),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                Row(
                  children: [
                    Text(
                      block.isFullDay
                          ? 'Journée entière'
                          : '${block.startTime} – ${block.endTime}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                    if (block.reason != null && block.reason!.isNotEmpty) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text(block.reason!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
            onPressed: onDelete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}
