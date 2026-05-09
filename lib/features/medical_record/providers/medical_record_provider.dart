import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/features/medical_record/data/models/medical_record_model.dart';
import 'package:medicare/features/medical_record/data/repositories/medical_record_repository.dart';

final medicalRecordsProvider = FutureProvider<List<MedicalRecordModel>>((ref) {
  return ref.read(medicalRecordRepositoryProvider).getMyRecords();
});

final medicalRecordsByPatientProvider =
    FutureProvider.family<List<MedicalRecordModel>, int>((ref, patientId) {
  return ref.read(medicalRecordRepositoryProvider).getByPatient(patientId);
});
