import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/appointment_model.dart';
import '../../providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFmt = DateFormat('HH:mm', 'fr_FR');
    final statusColor = appointment.status.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Détail du rendez-vous',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(appointment.status),
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.status.label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          _statusSubtitle(appointment.status),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Date & time ──────────────────────────────────────────────────
            _SectionCard(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppColors.primary,
                  label: 'Date',
                  value: fmt.format(appointment.appointmentDate),
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.primary,
                  label: 'Heure',
                  value: timeFmt.format(appointment.appointmentDate),
                ),
                if (appointment.endTime != null) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.timer_off_rounded,
                    iconColor: AppColors.textSecondary,
                    label: 'Fin',
                    value: timeFmt.format(appointment.endTime!),
                  ),
                ],
                const Divider(height: 24),
                _InfoRow(
                  icon: appointment.type == AppointmentType.teleconsultation
                      ? Icons.videocam_rounded
                      : Icons.local_hospital_rounded,
                  iconColor: appointment.type == AppointmentType.teleconsultation
                      ? const Color(0xFF4F46E5)
                      : AppColors.doctorColor,
                  label: 'Type',
                  value: appointment.type.label,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Doctor info ──────────────────────────────────────────────────
            if (appointment.doctor != null) ...[
              _SectionCard(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    iconColor: AppColors.doctorColor,
                    label: 'Médecin',
                    value: 'Dr. ${appointment.doctor!.fullName}',
                  ),
                  if (appointment.doctor!.specialty != null) ...[
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.medical_services_outlined,
                      iconColor: AppColors.doctorColor,
                      label: 'Spécialité',
                      value: appointment.doctor!.specialty!,
                    ),
                  ],
                  if (appointment.doctor!.phone != null) ...[
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      iconColor: AppColors.doctorColor,
                      label: 'Téléphone',
                      value: appointment.doctor!.phone!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Reason & notes ───────────────────────────────────────────────
            _SectionCard(
              children: [
                _InfoRow(
                  icon: Icons.notes_rounded,
                  iconColor: AppColors.primary,
                  label: 'Motif',
                  value: appointment.reason,
                ),
                if (appointment.notes != null &&
                    appointment.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.comment_outlined,
                    iconColor: AppColors.textSecondary,
                    label: 'Notes du médecin',
                    value: appointment.notes!,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────────
            if (appointment.status == AppointmentStatus.confirmed &&
                appointment.type == AppointmentType.teleconsultation)
              _ActionButton(
                icon: Icons.videocam_rounded,
                label: 'Rejoindre la téléconsultation',
                color: const Color(0xFF4F46E5),
                onPressed: () => context.push(
                  Routes.teleconsultation,
                  extra: {
                    'appointmentId': appointment.id,
                    'doctorName':
                        appointment.doctor?.fullName ?? 'Médecin',
                    'patientName': 'Moi',
                    'scheduledAt': appointment.appointmentDate,
                  },
                ),
              ),

            if (appointment.isUpcoming) ...[
              if (appointment.type == AppointmentType.teleconsultation)
                const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.cancel_outlined,
                label: 'Annuler ce rendez-vous',
                color: AppColors.error,
                outlined: true,
                onPressed: () => _confirmCancel(context, ref),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Annuler le rendez-vous ?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cette action est irréversible.',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Non',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Oui, annuler',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(appointmentsProvider.notifier).cancel(appointment.id);
      if (context.mounted) context.pop();
    }
  }

  IconData _statusIcon(AppointmentStatus s) => switch (s) {
        AppointmentStatus.pending => Icons.schedule_rounded,
        AppointmentStatus.confirmed => Icons.check_circle_rounded,
        AppointmentStatus.cancelled => Icons.cancel_rounded,
        AppointmentStatus.completed => Icons.task_alt_rounded,
        AppointmentStatus.noShow => Icons.person_off_rounded,
      };

  String _statusSubtitle(AppointmentStatus s) => switch (s) {
        AppointmentStatus.pending => 'En attente de confirmation du médecin',
        AppointmentStatus.confirmed => 'Votre rendez-vous est confirmé',
        AppointmentStatus.cancelled => 'Ce rendez-vous a été annulé',
        AppointmentStatus.completed => 'Consultation terminée',
        AppointmentStatus.noShow => 'Vous étiez absent à ce rendez-vous',
      };
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: color),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
