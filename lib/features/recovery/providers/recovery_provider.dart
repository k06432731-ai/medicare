import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/recovery_repository.dart';
import '../data/models/recovery_case_model.dart';
import '../data/models/recovery_stats_model.dart';
import '../data/models/risk_score_model.dart';
import '../data/models/staff_task_model.dart';

// ── Stats ─────────────────────────────────────────────────────────────────────

final recoveryStatsProvider = FutureProvider<RecoveryStats>((ref) async {
  return ref.watch(recoveryRepositoryProvider).getStats();
});

// ── Cases ─────────────────────────────────────────────────────────────────────

final recoveryCasesProvider =
    FutureProvider.family<List<RecoveryCaseModel>, String?>((ref, status) async {
  return ref.watch(recoveryRepositoryProvider).getCases(status: status);
});

final activeCasesProvider = FutureProvider<List<RecoveryCaseModel>>((ref) async {
  final repo = ref.watch(recoveryRepositoryProvider);
  final open = await repo.getCases(status: 'open');
  final inProgress = await repo.getCases(status: 'inProgress');
  final escalated = await repo.getCases(status: 'escalated');
  return [...escalated, ...open, ...inProgress];
});

// ── Staff Tasks ────────────────────────────────────────────────────────────────

final staffTasksProvider = FutureProvider<List<StaffTaskModel>>((ref) async {
  return ref.watch(recoveryRepositoryProvider).getStaffTasks();
});

// ── Risk Scores ────────────────────────────────────────────────────────────────

final criticalRiskScoresProvider = FutureProvider<List<RiskScoreModel>>((ref) async {
  return ref.watch(recoveryRepositoryProvider).getRiskScores(level: 'critical');
});

final highRiskScoresProvider = FutureProvider<List<RiskScoreModel>>((ref) async {
  return ref.watch(recoveryRepositoryProvider).getRiskScores(level: 'high');
});

// ── Doctor View ────────────────────────────────────────────────────────────────

class DoctorRecoveryView {
  final List<RecoveryCaseModel> cases;
  final List<RiskScoreModel> riskScores;
  const DoctorRecoveryView({required this.cases, required this.riskScores});
}

final doctorRecoveryViewProvider = FutureProvider<DoctorRecoveryView>((ref) async {
  final raw = await ref.watch(recoveryRepositoryProvider).getDoctorView();
  final casesData = raw['cases'] as List? ?? [];
  final scoresData = raw['riskScores'] as List? ?? [];
  return DoctorRecoveryView(
    cases: casesData
        .map((e) => RecoveryCaseModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    riskScores: scoresData
        .map((e) => RiskScoreModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});

// ── Patient Risk ───────────────────────────────────────────────────────────────

final patientRiskProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, patientId) async {
  return ref.watch(recoveryRepositoryProvider).getPatientRisk(patientId);
});

// ── Case update notifier ──────────────────────────────────────────────────────

class RecoveryCaseNotifier extends StateNotifier<AsyncValue<void>> {
  final RecoveryRepository _repo;
  RecoveryCaseNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> closeCase(int id, {String? notes}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCase(id, 'closed', notes: notes);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRecovered(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCase(id, 'recovered');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recoveryCaseNotifierProvider =
    StateNotifierProvider<RecoveryCaseNotifier, AsyncValue<void>>((ref) {
  return RecoveryCaseNotifier(ref.watch(recoveryRepositoryProvider));
});

// ── Task notifier ─────────────────────────────────────────────────────────────

class StaffTaskNotifier extends StateNotifier<AsyncValue<void>> {
  final RecoveryRepository _repo;
  final Ref _ref;
  StaffTaskNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> markDone(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.markTaskDone(id);
      _ref.invalidate(staffTasksProvider);
      _ref.invalidate(recoveryStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final staffTaskNotifierProvider =
    StateNotifierProvider<StaffTaskNotifier, AsyncValue<void>>((ref) {
  return StaffTaskNotifier(ref.watch(recoveryRepositoryProvider), ref);
});
