import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medicare/core/constants/app_colors.dart';
import 'package:medicare/features/appointment/data/models/appointment_model.dart';
import 'package:medicare/features/appointment/providers/appointment_provider.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';
import 'package:medicare/features/doctor/providers/doctor_provider.dart';
import 'package:medicare/shared/widgets/medicare_button.dart';
import 'package:medicare/app/router.dart' show Routes;
import 'package:medicare/features/home/presentation/screens/patient_shell_screen.dart' show patientTabProvider;
import 'package:medicare/features/schedule/providers/schedule_provider.dart'
    show PublicAvailabilityParams, publicAvailabilityProvider;

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final int doctorId;
  final DoctorModel? doctor;
  const BookAppointmentScreen({super.key, required this.doctorId, this.doctor});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  AppointmentType _selectedType = AppointmentType.inPerson;
  // Slots already booked for the selected day (fetched from backend)
  Set<String> _bookedSlots = {};
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _timeSlots = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 8, minute: 30),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 15, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 16, minute: 30),
    TimeOfDay(hour: 17, minute: 0),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    ref.listen<BookingState>(bookingProvider, (prev, next) {
      if (next.success) {
        ref.read(appointmentsProvider.notifier).load();
        _showSuccessDialog();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
        ref.read(bookingProvider.notifier).reset();
      }
    });

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prendre un RDV'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );

    // Use passed doctor model directly if available
    if (widget.doctor != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: scaffold.appBar,
        body: _buildBody(widget.doctor!, bookingState),
      );
    }

    // Fallback: fetch from API
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: scaffold.appBar,
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (doctor) => _buildBody(doctor, bookingState),
      ),
    );
  }

  Widget _buildBody(DoctorModel doctor, BookingState bookingState) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DoctorSummaryCard(doctor: doctor),
          const SizedBox(height: 20),
          _buildTypeSelector(),
          const SizedBox(height: 20),
          _buildCalendar(),
          const SizedBox(height: 20),
          if (_selectedDay != null) ...[
            _buildTimeSlots(),
            const SizedBox(height: 20),
          ],
          _buildReasonField(),
          const SizedBox(height: 12),
          _buildNotesField(),
          const SizedBox(height: 24),
          MedicareButton(
            label: 'Confirmer le rendez-vous',
            isLoading: bookingState.isLoading,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      _selectedDay != null &&
      _selectedTime != null &&
      _reasonController.text.trim().isNotEmpty;

  Widget _buildTypeSelector() {
    return _SectionCard(
      title: 'Type de consultation',
      child: Row(
        children: AppointmentType.values.map((t) {
          final selected = _selectedType == t;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t == AppointmentType.inPerson ? Icons.local_hospital : Icons.videocam,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendar() {
    return _SectionCard(
      title: 'Choisir une date',
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 60)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
            _selectedTime = null;
            _bookedSlots = {};
          });
          // Fetch real booked slots for this day from backend
          final dateStr =
              '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
          ref
              .read(publicAvailabilityProvider(PublicAvailabilityParams(
                  doctorId: widget.doctorId, date: dateStr))
                  .future)
              .then((data) {
            if (mounted) {
              final raw = data['bookedSlots'];
              if (raw is List) {
                setState(() => _bookedSlots = raw.map((e) => e.toString()).toSet());
              }
            }
          }).catchError((_) {}); // graceful degradation
        },
        enabledDayPredicate: (day) {
          return day.weekday != DateTime.saturday && day.weekday != DateTime.sunday;
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          disabledTextStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4)),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return _SectionCard(
      title: 'Choisir un créneau',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _timeSlots.map((slot) {
          final selected = _selectedTime == slot;
          // Format as HH:mm to match backend booked slots
          final slotKey =
              '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
          final isBooked = _bookedSlots.contains(slotKey);
          final label = slot.format(context);
          return GestureDetector(
            onTap: isBooked ? null : () => setState(() => _selectedTime = slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isBooked
                    ? AppColors.border
                    : selected
                        ? AppColors.primary
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBooked
                      ? AppColors.border
                      : selected
                          ? AppColors.primary
                          : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isBooked
                      ? AppColors.textHint
                      : selected
                          ? Colors.white
                          : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                  decoration: isBooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReasonField() {
    return _SectionCard(
      title: 'Motif de la consultation *',
      child: TextFormField(
        controller: _reasonController,
        maxLines: 2,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Décrivez brièvement le motif...',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
      ),
    );
  }

  Widget _buildNotesField() {
    return _SectionCard(
      title: 'Notes supplémentaires (optionnel)',
      child: TextFormField(
        controller: _notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'Informations utiles pour le médecin...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final date = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    ref.read(bookingProvider.notifier).book(
          doctorId: widget.doctorId,
          appointmentDate: date,
          reason: _reasonController.text.trim(),
          type: _selectedType,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Rendez-vous confirmé !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Votre RDV du ${DateFormat('d MMM yyyy', 'fr_FR').format(_selectedDay!)} '
              'à ${_selectedTime!.format(context)} a été enregistré.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).reset();
              ref.read(patientTabProvider.notifier).state = 1;
              Navigator.pop(context);
              context.go(Routes.patientHome);
            },
            child: const Text('Voir mes RDV'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DoctorSummaryCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorSummaryCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              doctor.initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. ${doctor.fullName}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(doctor.displaySpecialty,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
