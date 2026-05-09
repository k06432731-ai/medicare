import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/availability_model.dart';
import '../data/models/schedule_block_model.dart';
import '../data/repositories/schedule_repository.dart';

// ── Availability ──────────────────────────────────────────────────────────────

class AvailabilityState {
  final List<AvailabilityModel> slots;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const AvailabilityState({
    this.slots = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  AvailabilityState copyWith({
    List<AvailabilityModel>? slots,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) =>
      AvailabilityState(
        slots: slots ?? this.slots,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
      );
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final ScheduleRepository _repo;
  AvailabilityNotifier(this._repo) : super(const AvailabilityState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final slots = await _repo.getAvailability();
      // If no slots yet, build a default 7-day template (all inactive)
      if (slots.isEmpty) {
        final defaults = List.generate(
          7,
          (i) => AvailabilityModel(
            doctorId: 0,
            dayOfWeek: i,
            startTime: '08:00',
            endTime: '18:00',
            isActive: i < 5, // Mon-Fri active by default
          ),
        );
        state = state.copyWith(isLoading: false, slots: defaults);
      } else {
        // Ensure we always have 7 slots (fill missing days)
        final filled = <AvailabilityModel>[];
        for (int d = 0; d < 7; d++) {
          final existing = slots.firstWhere(
            (s) => s.dayOfWeek == d,
            orElse: () => AvailabilityModel(
              doctorId: 0,
              dayOfWeek: d,
              startTime: '08:00',
              endTime: '18:00',
              isActive: false,
            ),
          );
          filled.add(existing);
        }
        state = state.copyWith(isLoading: false, slots: filled);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateSlot(int dayOfWeek, AvailabilityModel updated) {
    final newSlots = state.slots.map((s) {
      return s.dayOfWeek == dayOfWeek ? updated : s;
    }).toList();
    state = state.copyWith(slots: newSlots);
  }

  Future<bool> save() async {
    state = state.copyWith(isSaving: true);
    try {
      final saved = await _repo.setAvailability(state.slots);
      // Refill to 7 slots
      final filled = <AvailabilityModel>[];
      for (int d = 0; d < 7; d++) {
        final existing = saved.firstWhere(
          (s) => s.dayOfWeek == d,
          orElse: () => state.slots[d],
        );
        filled.add(existing);
      }
      state = state.copyWith(isSaving: false, slots: filled);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
  return AvailabilityNotifier(ref.watch(scheduleRepositoryProvider));
});

// ── Schedule Blocks ───────────────────────────────────────────────────────────

class ScheduleBlockState {
  final List<ScheduleBlockModel> blocks;
  final bool isLoading;
  final String? error;

  const ScheduleBlockState({
    this.blocks = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleBlockState copyWith({
    List<ScheduleBlockModel>? blocks,
    bool? isLoading,
    String? error,
  }) =>
      ScheduleBlockState(
        blocks: blocks ?? this.blocks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ScheduleBlockNotifier extends StateNotifier<ScheduleBlockState> {
  final ScheduleRepository _repo;
  ScheduleBlockNotifier(this._repo) : super(const ScheduleBlockState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final blocks = await _repo.getBlocks();
      state = state.copyWith(isLoading: false, blocks: blocks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addBlock({
    required DateTime date,
    String startTime = '00:00',
    String endTime = '23:59',
    String reason = 'Indisponible',
  }) async {
    try {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final block = await _repo.addBlock(
        blockDate: dateStr,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      state = state.copyWith(blocks: [...state.blocks, block]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeBlock(int id) async {
    try {
      await _repo.removeBlock(id);
      state =
          state.copyWith(blocks: state.blocks.where((b) => b.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Set<DateTime> get blockedDates => {
        for (final b in state.blocks)
          DateTime(b.blockDate.year, b.blockDate.month, b.blockDate.day),
      };
}

final scheduleBlockProvider =
    StateNotifierProvider<ScheduleBlockNotifier, ScheduleBlockState>((ref) {
  return ScheduleBlockNotifier(ref.watch(scheduleRepositoryProvider));
});
