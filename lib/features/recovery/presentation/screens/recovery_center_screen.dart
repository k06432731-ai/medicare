import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/recovery_case_model.dart';
import '../../data/models/staff_task_model.dart';
import '../../providers/recovery_provider.dart';

class RecoveryCenterScreen extends ConsumerStatefulWidget {
  const RecoveryCenterScreen({super.key});

  @override
  ConsumerState<RecoveryCenterScreen> createState() =>
      _RecoveryCenterScreenState();
}

class _RecoveryCenterScreenState extends ConsumerState<RecoveryCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(recoveryStatsProvider);
    ref.invalidate(activeCasesProvider);
    ref.invalidate(staffTasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(recoveryStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              title: Text('Recovery Engine',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              flexibleSpace: FlexibleSpaceBar(
                background: _StatsHeader(statsAsync: statsAsync),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'CAS ACTIFS'),
                  Tab(text: 'TÂCHES STAFF'),
                  Tab(text: 'À RISQUE'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: const [
              _ActiveCasesTab(),
              _StaffTasksTab(),
              _RiskScoresTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats Header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final AsyncValue<dynamic> statsAsync;
  const _StatsHeader({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.adminColor, AppColors.adminColor.withValues(alpha: 0.7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 56),
          child: statsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => const SizedBox.shrink(),
            data: (stats) => Row(
              children: [
                _MiniStat(
                    value: '${stats.todayNoShows}',
                    label: 'No-shows\naujourd\'hui',
                    color: AppColors.error),
                _MiniStat(
                    value: '${stats.totalActiveCases}',
                    label: 'Cas\nactifs',
                    color: AppColors.warning),
                _MiniStat(
                    value: '${stats.recoveryRate}%',
                    label: 'Recovery\nrate 7j',
                    color: AppColors.success),
                _MiniStat(
                    value: '${stats.overdueTasks}',
                    label: 'Tâches\nen retard',
                    color: stats.overdueTasks > 0 ? AppColors.error : AppColors.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.white70, height: 1.3)),
        ],
      ),
    );
  }
}

// ── Active Cases Tab ──────────────────────────────────────────────────────────

class _ActiveCasesTab extends ConsumerWidget {
  const _ActiveCasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(activeCasesProvider);

    return casesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
          child: Text(err.toString(),
              style: const TextStyle(color: AppColors.error))),
      data: (cases) {
        if (cases.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Aucun cas actif',
            subtitle: 'Tous les patients sont suivis correctement.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cases.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _RecoveryCaseCard(recoveryCase: cases[i]),
        );
      },
    );
  }
}

class _RecoveryCaseCard extends ConsumerWidget {
  final RecoveryCaseModel recoveryCase;
  const _RecoveryCaseCard({required this.recoveryCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = recoveryCase;
    final typeColor = rc.type.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(rc.type.icon, color: typeColor, size: 20),
            ),
            title: Text(rc.patientName,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(rc.type.label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: rc.status),
                const SizedBox(height: 4),
                _PriorityBadge(priority: rc.priority),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _timeAgo(rc.triggerDate),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint),
                ),
                Row(
                  children: [
                    _ActionButton(
                      label: 'Récupéré',
                      color: AppColors.success,
                      onTap: () async {
                        await ref
                            .read(recoveryCaseNotifierProvider.notifier)
                            .markRecovered(rc.id);
                        ref.invalidate(activeCasesProvider);
                        ref.invalidate(recoveryStatsProvider);
                      },
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      label: 'Clore',
                      color: AppColors.textHint,
                      onTap: () async {
                        await ref
                            .read(recoveryCaseNotifierProvider.notifier)
                            .closeCase(rc.id);
                        ref.invalidate(activeCasesProvider);
                        ref.invalidate(recoveryStatsProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

// ── Staff Tasks Tab ───────────────────────────────────────────────────────────

class _StaffTasksTab extends ConsumerWidget {
  const _StaffTasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(staffTasksProvider);

    return tasksAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
          child: Text(err.toString(),
              style: const TextStyle(color: AppColors.error))),
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Aucune tâche en attente',
            subtitle: 'Toutes les tâches sont traitées.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _StaffTaskCard(task: tasks[i]),
        );
      },
    );
  }
}

class _StaffTaskCard extends ConsumerWidget {
  final StaffTaskModel task;
  const _StaffTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = task.isOverdue;
    final borderColor = isOverdue ? AppColors.error : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: borderColor, width: isOverdue ? 1.5 : 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isOverdue
                ? Icons.warning_amber_rounded
                : Icons.assignment_rounded,
            color: isOverdue ? AppColors.error : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(task.title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.patientPhone != null)
              Text(task.patientPhone!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
            Text(
              'Échéance : ${DateFormat('dd/MM HH:mm').format(task.dueDate)}',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isOverdue ? AppColors.error : AppColors.textHint),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () async {
            await ref
                .read(staffTaskNotifierProvider.notifier)
                .markDone(task.id);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Fait',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ── Risk Scores Tab ───────────────────────────────────────────────────────────

class _RiskScoresTab extends ConsumerWidget {
  const _RiskScoresTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalAsync = ref.watch(criticalRiskScoresProvider);
    final highAsync = ref.watch(highRiskScoresProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionLabel(title: '🔴 Critique', count: criticalAsync.whenOrNull(data: (d) => d.length) ?? 0),
        const SizedBox(height: 8),
        criticalAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => const SizedBox.shrink(),
          data: (scores) {
            if (scores.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Aucun patient critique',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13)),
              );
            }
            return Column(
              children: scores.map((s) => _RiskScoreCard(score: s)).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionLabel(title: '🟠 Élevé', count: highAsync.whenOrNull(data: (d) => d.length) ?? 0),
        const SizedBox(height: 8),
        highAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (scores) {
            if (scores.isEmpty) {
              return Text('Aucun patient à risque élevé',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13));
            }
            return Column(
              children: scores.map((s) => _RiskScoreCard(score: s)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;
  const _SectionLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _RiskScoreCard extends StatelessWidget {
  final dynamic score; // RiskScoreModel
  const _RiskScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: score.level.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${score.score}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: score.level.color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.patientName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  _buildSignals(score),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: score.level.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(score.level.label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: score.level.color)),
          ),
        ],
      ),
    );
  }

  String _buildSignals(dynamic score) {
    final parts = <String>[];
    if (score.noShowCount > 0) parts.add('${score.noShowCount} no-show(s)');
    if (score.daysSinceLastVisit > 0 && score.daysSinceLastVisit < 999) {
      parts.add('${score.daysSinceLastVisit}j sans visite');
    }
    if (score.hasExpiredPrescription) parts.add('ordonnance expirée');
    if (score.openCasesCount > 0) {
      parts.add('${score.openCasesCount} cas ouvert(s)');
    }
    return parts.isEmpty ? 'Aucun signal' : parts.join(' · ');
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final RecoveryCaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final RecoveryCasePriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(priority.apiValue.toUpperCase(),
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: priority.color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.success.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
