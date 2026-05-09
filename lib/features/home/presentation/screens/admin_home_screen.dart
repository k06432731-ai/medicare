import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../providers/admin_stats_provider.dart';
import '../../../recovery/providers/recovery_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AdminHeader(
                name: user?.firstName ?? 'Admin',
                email: user?.email ?? '',
                onLogout: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(Routes.roleSelection);
                },
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats grid ──────────────────────────────────────────
                  statsAsync.when(
                    loading: () => const _StatsGridShimmer(),
                    error: (e, _) => _ErrorBanner(message: e.toString()),
                    data: (stats) => _StatsGrid(stats: stats),
                  ),

                  const SizedBox(height: 28),

                  // ── Appointment breakdown ───────────────────────────────
                  Text('Rendez-vous',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (stats) => _AppointmentBreakdown(stats: stats),
                  ),

                  const SizedBox(height: 28),

                  // ── Recovery Engine ──────────────────────────────────────
                  _RecoveryEngineCard(),

                  const SizedBox(height: 28),

                  // ── Finance ─────────────────────────────────────────────
                  Text('Finance',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (stats) => _FinanceCard(stats: stats),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onLogout;

  const _AdminHeader({
    required this.name,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.adminColor, AppColors.adminColor.withValues(alpha: 0.75)],
        ),
      ),
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
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text('Administrateur',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (email.isNotEmpty)
                    Text(email,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70)),
                ],
              ),
              IconButton(
                onPressed: onLogout,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                ),
                tooltip: 'Se déconnecter',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${stats.totalPatients}',
                label: 'Patients',
                icon: Icons.people_rounded,
                color: AppColors.patientColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: '${stats.totalDoctors}',
                label: 'Médecins',
                icon: Icons.medical_services_rounded,
                color: AppColors.doctorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${stats.totalAppointments}',
                label: 'Rendez-vous',
                icon: Icons.calendar_today_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: '${stats.todayAppointments}',
                label: "Aujourd'hui",
                icon: Icons.today_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${stats.totalPrescriptions}',
                label: 'Ordonnances',
                icon: Icons.medication_rounded,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: '${stats.pendingInvoices}',
                label: 'Factures\nen attente',
                icon: Icons.receipt_long_rounded,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment breakdown ─────────────────────────────────────────────────────

class _AppointmentBreakdown extends StatelessWidget {
  final AdminStats stats;
  const _AppointmentBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalAppointments;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'En attente',
            count: stats.pendingAppointments,
            total: total,
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Confirmés',
            count: stats.confirmedAppointments,
            total: total,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: 'Terminés',
            count: stats.completedAppointments,
            total: total,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            Text('$count',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Finance card ──────────────────────────────────────────────────────────────

class _FinanceCard extends StatelessWidget {
  final AdminStats stats;
  const _FinanceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenus totaux (factures payées)',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    '${stats.totalRevenue.toStringAsFixed(2)} DA',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FinanceStat(
                  label: 'Total factures',
                  value: '${stats.totalInvoices}',
                  color: AppColors.primary),
              _FinanceStat(
                  label: 'En attente',
                  value: '${stats.pendingInvoices}',
                  color: AppColors.warning),
              _FinanceStat(
                  label: 'Payées',
                  value:
                      '${stats.totalInvoices - stats.pendingInvoices}',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Shimmer / Error ───────────────────────────────────────────────────────────

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Impossible de charger les statistiques: $message',
              style: GoogleFonts.poppins(
                  color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recovery Engine Card ──────────────────────────────────────────────────────

class _RecoveryEngineCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(recoveryStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recovery Engine',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            TextButton.icon(
              onPressed: () => context.push(Routes.recoveryCenter),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text('Ouvrir',
                  style: GoogleFonts.poppins(
                      color: AppColors.adminColor, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const SizedBox.shrink(),
          data: (stats) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _RecoveryMiniStat(
                      value: '${stats.todayNoShows}',
                      label: 'No-shows\naujourd\'hui',
                      color: AppColors.error,
                      icon: Icons.event_busy_rounded,
                    ),
                    _RecoveryMiniStat(
                      value: '${stats.totalActiveCases}',
                      label: 'Cas\nactifs',
                      color: AppColors.warning,
                      icon: Icons.folder_open_rounded,
                    ),
                    _RecoveryMiniStat(
                      value: '${stats.recoveryRate}%',
                      label: 'Recovery\nrate 7j',
                      color: AppColors.success,
                      icon: Icons.trending_up_rounded,
                    ),
                    _RecoveryMiniStat(
                      value: '${stats.overdueTasks}',
                      label: 'Tâches\nen retard',
                      color: stats.overdueTasks > 0
                          ? AppColors.error
                          : AppColors.success,
                      icon: Icons.assignment_late_rounded,
                    ),
                  ],
                ),
                if (stats.criticalScores > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.criticalScores} patient(s) en score critique',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _RecoveryMiniStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  height: 1.3)),
        ],
      ),
    );
  }
}
