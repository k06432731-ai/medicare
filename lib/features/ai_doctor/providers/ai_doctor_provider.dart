import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/ai_doctor_repository.dart';
import '../data/models/prescription_draft_model.dart';

// ── Brouillon ordonnance ──────────────────────────────────────────────────────

class PrescriptionDraftState {
  final PrescriptionDraftModel? draft;
  final bool isLoading;
  final String? error;
  const PrescriptionDraftState({this.draft, this.isLoading = false, this.error});

  PrescriptionDraftState copyWith({
    PrescriptionDraftModel? draft,
    bool? isLoading,
    String? error,
    bool clearDraft = false,
  }) =>
      PrescriptionDraftState(
        draft: clearDraft ? null : (draft ?? this.draft),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PrescriptionDraftNotifier
    extends StateNotifier<PrescriptionDraftState> {
  final AiDoctorRepository _repo;
  PrescriptionDraftNotifier(this._repo)
      : super(const PrescriptionDraftState());

  Future<void> generate({
    required String symptoms,
    String? diagnosis,
    String? patientAge,
    String? allergies,
    String? patientName,
  }) async {
    state = state.copyWith(isLoading: true, error: null, clearDraft: true);
    try {
      final draft = await _repo.prescriptionDraft(
        symptoms: symptoms,
        diagnosis: diagnosis,
        patientAge: patientAge,
        allergies: allergies,
        patientName: patientName,
      );
      state = state.copyWith(draft: draft, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const PrescriptionDraftState();
}

final prescriptionDraftProvider =
    StateNotifierProvider.autoDispose<PrescriptionDraftNotifier,
        PrescriptionDraftState>((ref) {
  return PrescriptionDraftNotifier(ref.watch(aiDoctorRepositoryProvider));
});

// ── Résumé patient ────────────────────────────────────────────────────────────

class PatientSummaryState {
  final String? summary;
  final bool isLoading;
  final String? error;
  const PatientSummaryState(
      {this.summary, this.isLoading = false, this.error});

  PatientSummaryState copyWith(
          {String? summary,
          bool? isLoading,
          String? error,
          bool clearSummary = false}) =>
      PatientSummaryState(
        summary: clearSummary ? null : (summary ?? this.summary),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PatientSummaryNotifier extends StateNotifier<PatientSummaryState> {
  final AiDoctorRepository _repo;
  PatientSummaryNotifier(this._repo) : super(const PatientSummaryState());

  Future<void> summarize(int patientId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, clearSummary: true);
    try {
      final summary = await _repo.summarizePatient(patientId);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const PatientSummaryState();
}

final patientSummaryProvider =
    StateNotifierProvider.autoDispose<PatientSummaryNotifier,
        PatientSummaryState>((ref) {
  return PatientSummaryNotifier(ref.watch(aiDoctorRepositoryProvider));
});

// ── Suggestions diagnostiques ─────────────────────────────────────────────────

class DiagnosticState {
  final DiagnosticSuggestionsModel? result;
  final bool isLoading;
  final String? error;
  const DiagnosticState({this.result, this.isLoading = false, this.error});

  DiagnosticState copyWith(
          {DiagnosticSuggestionsModel? result,
          bool? isLoading,
          String? error,
          bool clearResult = false}) =>
      DiagnosticState(
        result: clearResult ? null : (result ?? this.result),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class DiagnosticNotifier extends StateNotifier<DiagnosticState> {
  final AiDoctorRepository _repo;
  DiagnosticNotifier(this._repo) : super(const DiagnosticState());

  Future<void> suggest({
    required String symptoms,
    String? patientAge,
    String? medicalHistory,
  }) async {
    state = state.copyWith(isLoading: true, error: null, clearResult: true);
    try {
      final result = await _repo.diagnosticSuggestions(
        symptoms: symptoms,
        patientAge: patientAge,
        medicalHistory: medicalHistory,
      );
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const DiagnosticState();
}

final diagnosticProvider =
    StateNotifierProvider.autoDispose<DiagnosticNotifier, DiagnosticState>(
        (ref) {
  return DiagnosticNotifier(ref.watch(aiDoctorRepositoryProvider));
});
