import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';
import 'package:medicare/features/doctor/data/repositories/doctor_repository.dart';

final selectedSpecialtyProvider = StateProvider<String?>((ref) => null);

final doctorsProvider = FutureProvider.family<List<DoctorModel>, String?>((ref, specialty) {
  final repo = ref.read(doctorRepositoryProvider);
  return repo.getDoctors(specialty: specialty);
});

final specialtiesProvider = FutureProvider<List<String>>((ref) {
  final repo = ref.read(doctorRepositoryProvider);
  return repo.getSpecialties();
});

final doctorDetailProvider = FutureProvider.family<DoctorModel, int>((ref, id) {
  final repo = ref.read(doctorRepositoryProvider);
  return repo.getDoctorById(id);
});
