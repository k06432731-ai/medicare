import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Génère et partage un reçu de paiement PDF (format A4).
class PaymentReceiptService {
  PaymentReceiptService._();

  static Future<File> generateReceipt({
    required String invoiceNumber,
    required String patientName,
    required String doctorName,
    required double amount,
    required DateTime paidAt,
    required String paymentMethod,
    required String transactionId,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final dateStr = dateFmt.format(paidAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF2563EB),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('MEDICARE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text('Reçu de paiement',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── Numéro de facture et date ─────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _info('Facture N°', invoiceNumber),
                _info('Date de paiement', dateStr),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // ── Patient / Médecin ─────────────────────────────────
            _row('Patient', patientName),
            _row('Médecin', doctorName),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // ── Méthode et transaction ────────────────────────────
            _row('Méthode de paiement', paymentMethod),
            _row('ID de transaction', transactionId),
            pw.SizedBox(height: 24),

            // ── Bloc montant ──────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL RÉGLÉ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('${amount.toStringAsFixed(2)} TND',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                        color: const PdfColor.fromInt(0xFF2563EB),
                      )),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Footer ────────────────────────────────────────────
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Document généré automatiquement',
                style: const pw.TextStyle(
                    color: PdfColors.grey500, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeNumber = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/recu_$safeNumber.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Partage le reçu PDF via la feuille système (mail, drive, etc.).
  static Future<void> shareReceipt(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final filename = pdfFile.uri.pathSegments.last;
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static pw.Widget _info(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  color: PdfColors.grey600, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 13)),
        ],
      );

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(
                    color: PdfColors.grey600, fontSize: 12)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
      );
}
