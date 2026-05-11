import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../prescription/data/models/prescription_model.dart';
import '../../prescription/data/repositories/prescription_repository.dart';
import '../../medical_record/data/models/medical_record_model.dart';
import '../../medical_record/data/repositories/medical_record_repository.dart';
import '../../laboratory/data/models/lab_order_model.dart';
import '../../laboratory/data/repositories/lab_order_repository.dart';

// ── Aggregate model ────────────────────────────────────────────────────────────

/// Représente l'intégralité du dossier d'un patient.
/// Agrège ordonnances + dossiers médicaux + analyses de labo.
class DossierData {
  final List<PrescriptionModel> prescriptions;
  final List<MedicalRecordModel> records;
  final List<LabOrderModel> labOrders;

  const DossierData({
    required this.prescriptions,
    required this.records,
    required this.labOrders,
  });

  bool get isEmpty =>
      prescriptions.isEmpty && records.isEmpty && labOrders.isEmpty;

  int get totalDocuments =>
      prescriptions.length + records.length + labOrders.length;

  /// Nombre d'ordonnances actives
  int get activePrescriptions =>
      prescriptions.where((p) => p.status == PrescriptionStatus.active).length;

  /// Résumé textuel pour l'UI
  String get summary =>
      '$totalDocuments document${totalDocuments > 1 ? 's' : ''} médical${totalDocuments > 1 ? 'aux' : ''}';
}

// ── Provider ───────────────────────────────────────────────────────────────────

/// Provider qui agrège prescriptions + dossiers médicaux + analyses labo.
/// Évite d'importer 3 features différentes dans le screen dossier.
/// autoDispose: les données restent fraîches à chaque ouverture de l'écran.
final dossierProvider = FutureProvider.autoDispose<DossierData>((ref) async {
  // Chargement parallèle des trois sources
  final results = await Future.wait([
    ref.watch(prescriptionRepositoryProvider).getMyPrescriptions(),
    ref.watch(medicalRecordRepositoryProvider).getMyRecords(),
    ref.watch(labOrderRepositoryProvider).getMyOrders(),
  ]);

  return DossierData(
    prescriptions: results[0] as List<PrescriptionModel>,
    records: results[1] as List<MedicalRecordModel>,
    labOrders: results[2] as List<LabOrderModel>,
  );
});

/// Provider filtré : dossier d'un patient donné (vue médecin).
final patientDossierProvider =
    FutureProvider.autoDispose.family<DossierData, int>((ref, patientId) async {
  final results = await Future.wait([
    ref
        .watch(prescriptionRepositoryProvider)
        .getByPatient(patientId),
    ref
        .watch(medicalRecordRepositoryProvider)
        .getByPatient(patientId),
    ref.watch(labOrderRepositoryProvider).getByPatient(patientId),
  ]);

  return DossierData(
    prescriptions: results[0] as List<PrescriptionModel>,
    records: results[1] as List<MedicalRecordModel>,
    labOrders: results[2] as List<LabOrderModel>,
  );
});
