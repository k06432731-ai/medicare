import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/invoice_provider.dart';

class PatientInvoicesScreen extends ConsumerWidget {
  const PatientInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Factures'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(invoicesProvider)),
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Aucune facture',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          final pending =
              invoices.where((i) => i.isPending).toList();
          final others =
              invoices.where((i) => !i.isPending).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionTitle('À régler (${pending.length})'),
                  const SizedBox(height: 8),
                  ...pending.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InvoiceCard(
                          invoice: i,
                          onPay: () async {
                            // Cash is allowed only when the invoice covers
                            // an in-person event (lab test or in-person consult).
                            final isLab = i.type == InvoiceType.labTest;
                            final apptType =
                                i.appointment?['type'] as String?;
                            final isInPersonAppt = i.appointment != null &&
                                apptType != 'teleconsultation';
                            final allowCash = isLab || isInPersonAppt;
                            await context.push(
                              Routes.payment,
                              extra: {
                                'invoiceId': i.id,
                                'amount': i.amount,
                                'allowCash': allowCash,
                              },
                            );
                            // Refresh after returning from payment screen
                            ref.invalidate(invoicesProvider);
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                if (others.isNotEmpty) ...[
                  _SectionTitle('Historique'),
                  const SizedBox(height: 8),
                  ...others.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InvoiceCard(invoice: i),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

}

// ── Invoice Card ───────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onPay;
  const _InvoiceCard({required this.invoice, this.onPay});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');
    final statusColor = invoice.status.color;
    final typeColor = invoice.type.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: invoice.isPending
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.border),
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
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(invoice.type.icon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.type.label,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (invoice.description != null)
                      Text(invoice.description!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(invoice.amount)} FCFA',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(invoice.status.label,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(invoice.doctorName,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(fmt.format(invoice.createdAt),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
          if (invoice.isPending && onPay != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payment_rounded,
                    size: 16, color: Colors.white),
                label: Text('Régler cette facture',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          if (invoice.isPaid && invoice.paymentMethod != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(invoice.paymentMethod!.icon,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                    'Payé par ${invoice.paymentMethod!.label}'
                    '${invoice.paidAt != null ? ' le ${fmt.format(invoice.paidAt!)}' : ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textPrimary));
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
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
