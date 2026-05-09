import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/laboratory_model.dart';
import '../data/repositories/laboratory_repository.dart';
import '../data/repositories/lab_order_repository.dart';
import '../data/models/lab_order_model.dart';

final laboratoriesProvider =
    FutureProvider<List<LaboratoryModel>>((ref) {
  return ref.read(laboratoryRepositoryProvider).getLaboratories();
});

final labOrdersProvider =
    FutureProvider<List<LabOrderModel>>((ref) {
  return ref.read(labOrderRepositoryProvider).getMyOrders();
});

final labOrdersByPatientProvider =
    FutureProvider.family<List<LabOrderModel>, int>((ref, patientId) {
  return ref
      .read(labOrderRepositoryProvider)
      .getByPatient(patientId);
});
