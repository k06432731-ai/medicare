import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../appointment/providers/appointment_provider.dart';
import '../../../appointment/data/models/appointment_model.dart';
import 'doctor_shell_screen.dart' show doctorTabProvider;
import '../../../recovery/presentation/widgets/doctor_recovery_widget.dart';
import '../../../notification/providers/notification_provider.dart';
import '../../../../app/router.dart' show Routes;

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final appointmentsAsync = ref.watch(appointmentsProvider);

    final today = DateTime.now();
    final todayAppts = appointmentsAsync.whenOrNull(
          data: (list) => list
              .where((a) => DateUtils.isSameDay(a.appointmentDate, today))
              .toList(),
        ) ??
        [];
    final pendingCount = appointmentsAsync.whenOrNull(
          data: (list) =>
              list.where((a) => a.status == AppointmentStatus.pending).length,
        ) ??
        0;
    final totalPatients = appointmentsAsync.whenOrNull(
          data: (list) => list.map((a) => a.patientId).whereType<int>().toSet().length,
        ) ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(appointmentsProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DoctorHeader(
                name: user?.fullName ?? 'Médecin',
                isAvailable: user?.isAvailable ?? true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _DoctorStatsRow(
                    todayCount: todayAppts.length,
                    pendingCount: pendingCount,
                    totalPatients: totalPatients,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Consultations d'aujourd'hui",
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      if (todayAppts.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              ref.read(doctorTabProvider.notifier).state = 1,
                          child: Text('Voir tout',
                              style: GoogleFonts.poppins(
                                  color: AppColors.doctorColor, fontSize: 13)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  appointmentsAsync.when(
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Text(e.toString(),
                        style: const TextStyle(color: AppColors.error)),
                    data: (_) => todayAppts.isEmpty
                        ? _EmptyTodayCard()
                        : Column(
                            children: todayAppts
                                .take(3)
                                .map((a) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _TodayAppointmentCard(
                                        appointment: a,
                                        onConfirm: () => ref
                                            .read(appointmentsProvider.notifier)
                                            .updateStatus(a.id, 'confirmed'),
                                        onComplete: () => ref
                                            .read(appointmentsProvider.notifier)
                                            .updateStatus(a.id, 'completed'),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 28),
                  const DoctorRecoveryWidget(),
                  const SizedBox(height: 28),
                  Text('Patients récents',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  appointmentsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (list) {
                      final seen = <int>{};
                      final patients = <Map<String, dynamic>>[];
                      for (final a in list) {
                        final p = a.patient;
                        if (p == null) continue;
                        final pid = p['id'] as int? ?? 0;
                        if (seen.contains(pid)) continue;
                        seen.add(pid);
                        patients.add(p);
                        if (patients.length >= 4) break;
                      }
                      if (patients.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Aucun patient pour l\'instant',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: patients.asMap().entries.map((entry) {
                            final i = entry.key;
                            final p = entry.value;
                            final first = p['firstName'] as String? ?? '';
                            final last = p['lastName'] as String? ?? '';
                            final name = (first.isNotEmpty || last.isNotEmpty)
                                ? '$first $last'.trim()
                                : p['username'] as String? ?? 'Patient';
                            final initials = first.isNotEmpty && last.isNotEmpty
                                ? '${first[0]}${last[0]}'.toUpperCase()
                                : name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?';
                            return Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primarySurface,
                                    child: Text(initials,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ),
                                  title: Text(name,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  subtitle: p['phone'] != null
                                      ? Text(p['phone'] as String,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12))
                                      : null,
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textHint),
                                  onTap: () => ref
                                      .read(doctorTabProvider.notifier)
                                      .state = 2,
                                ),
                                if (i < patients.length - 1)
                                  const Divider(height: 1, indent: 72),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHeader extends ConsumerWidget {
  final String name;
  final bool isAvailable;
  const _DoctorHeader({required this.name, required this.isAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final unreadCount =
        ref.watch(unreadCountProvider).whenOrNull(data: (c) => c) ?? 0;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.doctorGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $name',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  // Cloche notifications
                  GestureDetector(
                    onTap: () => context.push(Routes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 20),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Statut disponibilité
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.secondaryLight
                                : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(isAvailable ? 'Disponible' : 'Indisponible',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorStatsRow extends StatelessWidget {
  final int todayCount;
  final int pendingCount;
  final int totalPatients;
  const _DoctorStatsRow(
      {required this.todayCount,
      required this.pendingCount,
      required this.totalPatients});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: '$todayCount',
            label: "Consultations\naujourd'hui",
            icon: Icons.medical_services_rounded,
            color: AppColors.doctorColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _Stat(
            value: '$pendingCount',
            label: 'En attente\nde confirmation',
            icon: Icons.hourglass_empty_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _Stat(
            value: '$totalPatients',
            label: 'Patients\ndistincts',
            icon: Icons.people_rounded,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _TodayAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  const _TodayAppointmentCard(
      {required this.appointment,
      required this.onConfirm,
      required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('HH:mm').format(appointment.appointmentDate);
    final statusColor = appointment.status.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(time,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          Container(
              width: 1,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.patientName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(appointment.reason,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
              if (appointment.status == AppointmentStatus.pending) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: onConfirm,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.doctorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Confirmer',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else if (appointment.status == AppointmentStatus.confirmed) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: onComplete,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Terminé',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 40,
                color: AppColors.doctorColor.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text("Aucune consultation aujourd'hui",
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
