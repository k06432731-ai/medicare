import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Call State ─────────────────────────────────────────────────────────────────

enum CallStatus { idle, joining, inCall, ended, error }

class TeleconsultationState {
  final CallStatus status;
  final String? errorMessage;

  const TeleconsultationState({
    this.status = CallStatus.idle,
    this.errorMessage,
  });

  bool get isJoining => status == CallStatus.joining;
  bool get isInCall => status == CallStatus.inCall;
  bool get hasError => status == CallStatus.error;

  TeleconsultationState copyWith({
    CallStatus? status,
    String? errorMessage,
  }) =>
      TeleconsultationState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class TeleconsultationNotifier
    extends StateNotifier<TeleconsultationState> {
  TeleconsultationNotifier() : super(const TeleconsultationState());

  void setJoining() => state = state.copyWith(status: CallStatus.joining);

  void setInCall() =>
      state = state.copyWith(status: CallStatus.inCall, errorMessage: null);

  void setEnded() => state = state.copyWith(status: CallStatus.ended);

  void setError(String message) => state = state.copyWith(
        status: CallStatus.error,
        errorMessage: message,
      );

  void reset() => state = const TeleconsultationState();
}

// ── Provider ───────────────────────────────────────────────────────────────────

/// Scoped per-screen — use with ProviderScope override if multiple meetings
/// could be open simultaneously (unlikely but possible).
final teleconsultationProvider =
    StateNotifierProvider.autoDispose<TeleconsultationNotifier, TeleconsultationState>(
  (ref) => TeleconsultationNotifier(),
);
