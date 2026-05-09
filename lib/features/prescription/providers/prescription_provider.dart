import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/features/prescription/data/models/prescription_model.dart';
import 'package:medicare/features/prescription/data/repositories/prescription_repository.dart';

final prescriptionsProvider = FutureProvider<List<PrescriptionModel>>((ref) {
  return ref.read(prescriptionRepositoryProvider).getMyPrescriptions();
});

final prescriptionsByPatientProvider =
    FutureProvider.family<List<PrescriptionModel>, int>((ref, patientId) {
  return ref.read(prescriptionRepositoryProvider).getByPatient(patientId);
});
