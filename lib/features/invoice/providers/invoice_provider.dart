import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) {
  return ref.read(invoiceRepositoryProvider).getMyInvoices();
});

final invoicesByPatientProvider =
    FutureProvider.family<List<InvoiceModel>, int>((ref, patientId) {
  return ref.read(invoiceRepositoryProvider).getByPatient(patientId);
});
