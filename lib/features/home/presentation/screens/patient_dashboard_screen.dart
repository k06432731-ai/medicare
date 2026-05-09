import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../../../features/appointment/data/models/appointment_model.dart';
import '../../../../features/appointment/providers/appointment_provider.dart';
import '../../../../features/prescription/providers/prescription_provider.dart';
import '../../../../features/invoice/providers/invoice_provider.dart';
import '../../../../features/invoice/data/models/invoice_model.dart';
import '../../../../features/recovery/presentation/widgets/risk_score_badge.dart';
import '../../../../features/notification/providers/notification_provider.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(invoicesProvider);
    ref.invalidate(appointmentsProvider);
    ref.invalidate(prescriptionsProvider);
    // Attendre que la future factures soit résolue (la plus utile)
    await ref.read(invoicesProvider.future).catchError((_) => <InvoiceModel>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.firstName ?? user?.username ?? 'Utilisateur';
    final patientId = user?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        color: AppColors.primary,
        child: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(firstName: firstName),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // Recovery banner — shown only when there is an open case
                if (patientId > 0) PatientRecoveryBanner(patientId: patientId),

                // Stats row
                const _StatsRow(),

                const SizedBox(height: 28),

                // Quick actions
                _SectionHeader(title: 'Actions rapides'),
                const SizedBox(height: 16),
                const _QuickActionsGrid(),

                const SizedBox(height: 28),

                // Carte MediCare AI
                const _AiAssistantCard(),

                const SizedBox(height: 28),

                // Next appointment
                _SectionHeader(title: 'Prochain rendez-vous'),
                const SizedBox(height: 16),
                const _NextAppointmentCard(),

                const SizedBox(height: 28),

                // Health tips
                _SectionHeader(title: 'Conseil du jour'),
                const SizedBox(height: 16),
                const _HealthTipCard(),

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

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends ConsumerWidget {
  final String firstName;
  const _DashboardHeader({required this.firstName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadCountProvider).whenOrNull(data: (c) => c) ?? 0;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Bonjour'
        : now.hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $firstName 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 24),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
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
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push(Routes.doctorsList),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded,
                          color: Colors.white70, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Rechercher un médecin, spécialité...',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — données réelles
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentsProvider);
    final rxAsync = ref.watch(prescriptionsProvider);
    final invoicesAsync = ref.watch(invoicesProvider);

    final upcomingCount = apptAsync.whenOrNull(
          data: (list) => list.where((a) => a.isUpcoming).length,
        ) ??
        0;

    final activeRxCount = rxAsync.whenOrNull(
          data: (list) => list.where((p) => p.isActive).length,
        ) ??
        0;

    final pendingInvoicesCount = invoicesAsync.whenOrNull(
          data: (list) =>
              list.where((i) => i.status == InvoiceStatus.pending).length,
        ) ??
        0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: apptAsync.isLoading ? '…' : '$upcomingCount',
            label: 'Rendez-vous\nà venir',
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            value: rxAsync.isLoading ? '…' : '$activeRxCount',
            label: 'Prescriptions\nactives',
            icon: Icons.medication_rounded,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            value: invoicesAsync.isLoading ? '…' : '$pendingInvoicesCount',
            label: 'Factures\nen attente',
            icon: Icons.receipt_long_rounded,
            color: AppColors.error,
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
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
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    _QuickAction(
      icon: Icons.add_circle_outline_rounded,
      label: 'Nouveau\nrendez-vous',
      color: AppColors.primary,
      route: Routes.doctorsList,
    ),
    _QuickAction(
      icon: Icons.people_outline_rounded,
      label: 'Mes\nmédecins',
      color: AppColors.secondary,
      route: Routes.doctorsList,
    ),
    _QuickAction(
      icon: Icons.receipt_long_rounded,
      label: 'Mes\nfactures',
      color: Color(0xFFF59E0B),
      route: Routes.patientInvoices,
    ),
    _QuickAction(
      icon: Icons.science_outlined,
      label: 'Mes\nanalyses',
      color: Color(0xFF06B6D4),
      route: Routes.patientLabOrders,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children:
          _actions.map((action) => _QuickActionItem(action: action)).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      this.route});
}

class _QuickActionItem extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (action.route != null) context.push(action.route!);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next appointment card — données réelles
// ─────────────────────────────────────────────────────────────────────────────

class _NextAppointmentCard extends ConsumerWidget {
  const _NextAppointmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentsProvider);

    return apptAsync.when(
      loading: () => _buildSkeleton(),
      error: (e, _) => _buildEmpty(context),
      data: (list) {
        final upcoming = list
            .where((a) => a.isUpcoming)
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        if (upcoming.isEmpty) return _buildEmpty(context);
        return _buildCard(context, upcoming.first);
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucun rendez-vous prévu',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Prenez rendez-vous avec un médecin',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.doctorsList),
            child: Text('Prendre RDV',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppointmentModel appt) {
    final now = DateTime.now();
    final apptDate = appt.appointmentDate;

    String whenLabel;
    if (apptDate.year == now.year &&
        apptDate.month == now.month &&
        apptDate.day == now.day) {
      whenLabel = "Aujourd'hui";
    } else if (apptDate.year == now.year &&
        apptDate.month == now.month &&
        apptDate.day == now.day + 1) {
      whenLabel = 'Demain';
    } else {
      whenLabel = DateFormat('d MMM', 'fr_FR').format(apptDate);
    }

    final timeStr = DateFormat('HH:mm').format(apptDate);
    final doctor = appt.doctor;
    final doctorName = doctor != null
        ? 'Dr. ${doctor.firstName} ${doctor.lastName}'
        : 'Médecin';
    final specialty = doctor?.specialty ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  whenLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.medical_services_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  appt.type.label,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(Routes.patientHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Voir détails',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health tip card
// ─────────────────────────────────────────────────────────────────────────────

class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard();

  static const _tips = [
    _Tip('Hydratation',
        'Buvez au moins 1,5L d\'eau par jour pour maintenir votre énergie.'),
    _Tip('Activité physique',
        '30 minutes de marche par jour réduisent le risque cardiovasculaire.'),
    _Tip('Sommeil',
        'Un sommeil de 7 à 8 heures améliore la mémoire et l\'immunité.'),
    _Tip('Alimentation',
        'Privilégiez les fruits et légumes de saison pour un apport optimal.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: AppColors.secondary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip.body,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  final String title;
  final String body;
  const _Tip(this.title, this.body);
}

// ─────────────────────────────────────────────────────────────────────────────
// MediCare AI card
// ─────────────────────────────────────────────────────────────────────────────

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.aiAssistant),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MediCare AI',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    'Conseils santé · Triage symptômes',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Démarrer',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
