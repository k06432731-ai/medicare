import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/core/errors/exceptions.dart';
import 'package:medicare/features/appointment/data/models/appointment_model.dart';
import 'package:medicare/features/appointment/data/repositories/appointment_repository.dart';

// Appointments list
final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AsyncValue<List<AppointmentModel>>>((ref) {
  return AppointmentsNotifier(ref.read(appointmentRepositoryProvider));
});

class AppointmentsNotifier extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  final AppointmentRepository _repo;

  AppointmentsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getMyAppointments(status: status);
      state = AsyncValue.data(list);
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<bool> cancel(int id) async {
    try {
      final updated = await _repo.cancelAppointment(id);
      state = state.whenData((list) =>
          list.map((a) => a.id == id ? updated : a).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status, {String? doctorNotes}) async {
    try {
      final updated = await _repo.updateAppointmentStatus(id, status, doctorNotes: doctorNotes);
      state = state.whenData((list) =>
          list.map((a) => a.id == id ? updated : a).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Booking state
class BookingState {
  final bool isLoading;
  final String? error;
  final bool success;

  const BookingState({this.isLoading = false, this.error, this.success = false});

  BookingState copyWith({bool? isLoading, String? error, bool? success}) => BookingState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref.read(appointmentRepositoryProvider));
});

class BookingNotifier extends StateNotifier<BookingState> {
  final AppointmentRepository _repo;

  BookingNotifier(this._repo) : super(const BookingState());

  Future<void> book({
    required int doctorId,
    required DateTime appointmentDate,
    required String reason,
    required AppointmentType type,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createAppointment(
        doctorId: doctorId,
        appointmentDate: appointmentDate,
        reason: reason,
        type: type,
        notes: notes,
      );
      state = state.copyWith(isLoading: false, success: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const BookingState();
}
