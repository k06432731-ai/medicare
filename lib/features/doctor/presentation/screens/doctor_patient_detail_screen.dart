import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/router.dart';
import '../../../prescription/data/models/prescription_model.dart';
import '../../../prescription/providers/prescription_provider.dart';
import '../../../medical_record/data/models/medical_record_model.dart';
import '../../../medical_record/providers/medical_record_provider.dart';
import '../../../invoice/data/models/invoice_model.dart';
import '../../../invoice/data/repositories/invoice_repository.dart';
import '../../../invoice/providers/invoice_provider.dart';
import '../../../laboratory/providers/laboratory_provider.dart';
import '../../../ai_doctor/presentation/widgets/ai_patient_summary_widget.dart';
import '../../../../core/services/prescription_pdf_service.dart';

class DoctorPatientDetailScreen extends ConsumerWidget {
  final int patientId;
  final String patientName;
  final String? patientPhone;

  const DoctorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patientName,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              if (patientPhone != null)
                Text(patientPhone!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            labelColor: AppColors.doctorColor,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.doctorColor,
            indicatorWeight: 3,
            labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Ordonnances'),
              Tab(text: 'Dossier médical'),
              Tab(text: 'Analyses'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.doctorColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Ajouter',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          onPressed: () => _showAddMenu(context, ref),
        ),
        body: Column(
          children: [
            // AI summary card — persists across tab switches
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AiPatientSummaryWidget(patientId: patientId),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PrescriptionsTab(
                      patientId: patientId, patientName: patientName),
                  _RecordsTab(
                      patientId: patientId, patientName: patientName),
                  _LabOrdersTab(
                      patientId: patientId, patientName: patientName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createConsultationInvoice(
      BuildContext context, WidgetRef ref) async {
    double? amount;
    await showDialog(
      context: context,
      builder: (_) => _InvoiceAmountDialog(
        onConfirm: (a) => amount = a,
      ),
    );
    if (amount == null || amount! <= 0) return;
    try {
      await ref.read(invoiceRepositoryProvider).createInvoice({
        'patient': patientId,
        'amount': amount,
        'type': InvoiceType.consultation.apiValue,
        'status': InvoiceStatus.pending.apiValue,
        'description': 'Consultation — $patientName',
      });
      ref.invalidate(invoicesByPatientProvider(patientId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Facture créée avec succès',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary),
                ),
                title: Text('Nouvelle ordonnance',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Prescrire des médicaments',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.createPrescription, extra: {
                    'patientId': patientId,
                    'patientName': patientName,
                  }).then((_) {
                    ref.invalidate(prescriptionsByPatientProvider(patientId));
                  });
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_special_rounded,
                      color: AppColors.tertiary),
                ),
                title: Text('Nouveau document médical',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Analyse, imagerie, consultation…',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.createMedicalRecord, extra: {
                    'patientId': patientId,
                    'patientName': patientName,
                  }).then((_) {
                    ref.invalidate(medicalRecordsByPatientProvider(patientId));
                  });
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.labColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science_rounded,
                      color: AppColors.labColor),
                ),
                title: Text('Bon d\'analyses',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Prescrire des analyses ou examens',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.createLabOrder, extra: {
                    'patientId': patientId,
                    'patientName': patientName,
                  }).then((_) {
                    ref.invalidate(labOrdersByPatientProvider(patientId));
                  });
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.warning),
                ),
                title: Text('Créer une facture',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Facturer une consultation',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _createConsultationInvoice(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Prescriptions tab ──────────────────────────────────────────────────────────

class _PrescriptionsTab extends ConsumerWidget {
  final int patientId;
  final String patientName;
  const _PrescriptionsTab(
      {required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsByPatientProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(prescriptionsByPatientProvider(patientId))),
      data: (list) {
        if (list.isEmpty) {
          return _Empty(
            icon: Icons.receipt_long_outlined,
            message: 'Aucune ordonnance',
            actionLabel: 'Créer une ordonnance',
            onAction: () => context
                .push(Routes.createPrescription,
                    extra: {'patientId': patientId, 'patientName': patientName})
                .then((_) =>
                    ref.invalidate(prescriptionsByPatientProvider(patientId))),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(prescriptionsByPatientProvider(patientId)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PrescriptionCard(
                  p: list[i], patientName: patientName),
          ),
        );
      },
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel p;
  final String patientName;
  const _PrescriptionCard({required this.p, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');
    final statusColor = switch (p.status) {
      PrescriptionStatus.active => AppColors.success,
      PrescriptionStatus.expired => AppColors.textSecondary,
      PrescriptionStatus.cancelled => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.diagnosis ?? 'Ordonnance',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              _Badge(label: p.status.label, color: statusColor),
            ],
          ),
          if (p.medications.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...p.medications.take(3).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m.name} — ${m.dosage}, ${m.frequency}'
                          '${m.duration != null ? ', ${m.duration}' : ''}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
            if (p.medications.length > 3)
              Text('+${p.medications.length - 3} médicament(s)',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Émise le ${fmt.format(p.issuedDate)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint)),
              // PDF export
              GestureDetector(
                onTap: () async {
                  try {
                    await PrescriptionPdfService.share(
                      prescription: p,
                      patientName: patientName,
                      doctorName: p.doctorName,
                    );
                  } catch (e) {
                    // ignore
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text('PDF',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Medical records tab ────────────────────────────────────────────────────────

class _RecordsTab extends ConsumerWidget {
  final int patientId;
  final String patientName;
  const _RecordsTab({required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicalRecordsByPatientProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(medicalRecordsByPatientProvider(patientId))),
      data: (list) {
        if (list.isEmpty) {
          return _Empty(
            icon: Icons.folder_open_outlined,
            message: 'Aucun document médical',
            actionLabel: 'Créer un document',
            onAction: () => context
                .push(Routes.createMedicalRecord,
                    extra: {'patientId': patientId, 'patientName': patientName})
                .then((_) =>
                    ref.invalidate(medicalRecordsByPatientProvider(patientId))),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(medicalRecordsByPatientProvider(patientId)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = list[i];
              return _RecordCard(record: r, color: r.type.color, icon: r.type.icon);
            },
          ),
        );
      },
    );
  }
}

// ── Lab orders tab ─────────────────────────────────────────────────────────────

class _LabOrdersTab extends ConsumerWidget {
  final int patientId;
  final String patientName;
  const _LabOrdersTab({required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labOrdersByPatientProvider(patientId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(labOrdersByPatientProvider(patientId))),
      data: (list) {
        if (list.isEmpty) {
          return _Empty(
            icon: Icons.science_outlined,
            message: 'Aucun bon d\'analyses',
            actionLabel: 'Créer un bon d\'analyses',
            onAction: () => context
                .push(Routes.createLabOrder,
                    extra: {'patientId': patientId, 'patientName': patientName})
                .then((_) => ref.invalidate(labOrdersByPatientProvider(patientId))),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(labOrdersByPatientProvider(patientId)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LabCard(order: list[i]),
          ),
        );
      },
    );
  }
}

class _LabCard extends StatelessWidget {
  final dynamic order;
  const _LabCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.labColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science_rounded, color: AppColors.labColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.laboratory?.name ?? 'Laboratoire',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${order.tests.length} analyse(s) · ${order.totalAmount.toStringAsFixed(0)} FCFA',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(fmt.format(order.orderedAt),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          _Badge(label: order.status.label, color: _statusColor(order.status)),
        ],
      ),
    );
  }

  Color _statusColor(dynamic status) {
    final s = status.toString();
    if (s.contains('completed')) return AppColors.success;
    if (s.contains('cancelled')) return AppColors.error;
    if (s.contains('progress')) return AppColors.primary;
    return AppColors.warning;
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecordModel record;
  final Color color;
  final IconData icon;
  const _RecordCard(
      {required this.record, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (record.description != null)
                  Text(record.description!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(fmt.format(record.date),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Badge(label: record.type.label, color: color),
        ],
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _Empty(
      {required this.icon,
      required this.message,
      required this.actionLabel,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: Text(actionLabel,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.doctorColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _InvoiceAmountDialog extends StatefulWidget {
  final ValueChanged<double> onConfirm;
  const _InvoiceAmountDialog({required this.onConfirm});

  @override
  State<_InvoiceAmountDialog> createState() => _InvoiceAmountDialogState();
}

class _InvoiceAmountDialogState extends State<_InvoiceAmountDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Montant de la facture',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Ex: 15000',
          hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
          suffixText: 'FCFA',
          suffixStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.warning, width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final v = double.tryParse(_ctrl.text.trim());
            if (v != null && v > 0) {
              widget.onConfirm(v);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Créer',
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}
