import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../appointment/data/models/appointment_model.dart';
import '../../../appointment/providers/appointment_provider.dart';

class DoctorPlanningScreen extends ConsumerWidget {
  const DoctorPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mon Planning'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Gérer l\'agenda',
            onPressed: () => context.push(Routes.doctorSchedule),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(appointmentsProvider.notifier).load(),
          ),
        ],
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(appointmentsProvider.notifier).load(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Aucun rendez-vous',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          // Group by date
          final grouped = <String, List<AppointmentModel>>{};
          for (final a in appointments) {
            final key = DateFormat('yyyy-MM-dd').format(a.appointmentDate);
            grouped.putIfAbsent(key, () => []).add(a);
          }
          final sortedDates = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async => ref.read(appointmentsProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, i) {
                final dateKey = sortedDates[i];
                final dayAppts = grouped[dateKey]!;
                final date = DateTime.parse(dateKey);
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                final dateLabel = isToday
                    ? "Aujourd'hui"
                    : DateFormat('EEEE d MMMM', 'fr_FR').format(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 8),
                      child: Row(
                        children: [
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.doctorColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(dateLabel,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            )
                          else
                            Text(
                              dateLabel[0].toUpperCase() + dateLabel.substring(1),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                        ],
                      ),
                    ),
                    ...dayAppts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DoctorAppointmentCard(
                              appointment: a,
                              pageContext: context,
                              onConfirm: () => ref
                                  .read(appointmentsProvider.notifier)
                                  .updateStatus(a.id, 'confirmed'),
                              onComplete: () => ref
                                  .read(appointmentsProvider.notifier)
                                  .updateStatus(a.id, 'completed'),
                              onCancel: () => ref
                                  .read(appointmentsProvider.notifier)
                                  .updateStatus(a.id, 'cancelled'),
                              onNoShow: () => ref
                                  .read(appointmentsProvider.notifier)
                                  .updateStatus(a.id, 'no_show')),
                        )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onNoShow;
  final BuildContext pageContext;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
    required this.onNoShow,
    required this.pageContext,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm', 'fr_FR').format(appointment.appointmentDate);
    final patientName = _patientName;
    final statusColor = appointment.status.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.doctorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timeStr,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: AppColors.doctorColor,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              // Patient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    Text(appointment.reason,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(appointment.status.label,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          // Action buttons for pending appointments
          if (appointment.status == AppointmentStatus.pending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 16,
                        color: AppColors.error),
                    label: Text('Refuser',
                        style: GoogleFonts.poppins(
                            color: AppColors.error, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 16,
                        color: Colors.white),
                    label: Text('Confirmer',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.doctorColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Mark as complete for confirmed appointments
          if (appointment.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 10),
            // Teleconsultation join button (shown above action row)
            if (appointment.type == AppointmentType.teleconsultation)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _joinTeleconsultation(pageContext),
                    icon: const Icon(Icons.video_call_rounded,
                        size: 16, color: Colors.white),
                    label: Text('Rejoindre la téléconsultation',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.task_alt_rounded,
                        size: 16, color: Colors.white),
                    label: Text('Terminé',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goCreatePrescription(pageContext),
                    icon: const Icon(Icons.receipt_long_rounded,
                        size: 16, color: AppColors.doctorColor),
                    label: Text('Ordonnance',
                        style: GoogleFonts.poppins(
                            color: AppColors.doctorColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.doctorColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            // No-show button: only for past appointments
            if (appointment.appointmentDate.isBefore(DateTime.now())) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onNoShow,
                  icon: const Icon(Icons.person_off_rounded,
                      size: 16, color: AppColors.textSecondary),
                  label: Text('Absent (no-show)',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],

          // Ordonnance button for completed appointments
          if (appointment.status == AppointmentStatus.completed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _goCreatePrescription(pageContext),
                icon: const Icon(Icons.receipt_long_rounded,
                    size: 16, color: AppColors.doctorColor),
                label: Text('Rédiger une ordonnance',
                    style: GoogleFonts.poppins(
                        color: AppColors.doctorColor, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.doctorColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _patientName {
    final p = appointment.patient;
    if (p == null) return 'Patient inconnu';
    final first = p['firstName'] as String? ?? '';
    final last = p['lastName'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return p['username'] as String? ?? 'Patient';
  }

  void _joinTeleconsultation(BuildContext ctx) {
    ctx.push(Routes.teleconsultation, extra: {
      'appointmentId': appointment.id,
      'doctorName': appointment.doctor?.fullName ?? 'Médecin',
      'patientName': _patientName,
      'scheduledAt': appointment.appointmentDate,
    });
  }

  void _goCreatePrescription(BuildContext ctx) {
    final pid = appointment.patientId;
    if (pid == null) return;
    ctx.push(Routes.createPrescription, extra: {
      'patientId': pid,
      'patientName': _patientName,
    });
  }
}
