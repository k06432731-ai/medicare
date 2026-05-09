import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/prescription/data/models/prescription_model.dart';

/// Génère et partage un PDF d'ordonnance médicale.
class PrescriptionPdfService {
  PrescriptionPdfService._();

  static Future<void> share({
    required PrescriptionModel prescription,
    required String patientName,
    required String doctorName,
  }) async {
    final pdf = pw.Document();
    final fmt = DateFormat('d MMMM yyyy', 'fr_FR');
    final dateStr = fmt.format(prescription.issuedDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ORDONNANCE MÉDICALE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo800,
                        ),
                      ),
                      pw.Text(
                        // doctorName from PrescriptionModel already includes "Dr."
                        doctorName,
                        style: pw.TextStyle(
                            fontSize: 13, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Medicare',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.indigo200, thickness: 2),
              pw.SizedBox(height: 16),

              // ── Patient & date ───────────────────────────────────────
              pw.Row(
                children: [
                  _infoBox('Patient', patientName),
                  pw.SizedBox(width: 20),
                  _infoBox('Date', dateStr),
                  pw.SizedBox(width: 20),
                  _infoBox('Statut', prescription.status.label),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── Diagnosis ────────────────────────────────────────────
              if (prescription.diagnosis != null &&
                  prescription.diagnosis!.isNotEmpty) ...[
                _sectionTitle('Diagnostic'),
                pw.SizedBox(height: 6),
                _box(prescription.diagnosis!),
                pw.SizedBox(height: 16),
              ],

              // ── Medications ──────────────────────────────────────────
              _sectionTitle('Médicaments prescrits'),
              pw.SizedBox(height: 8),
              ...prescription.medications.asMap().entries.map(
                    (e) => _medicationRow(e.key + 1, e.value),
                  ),
              pw.SizedBox(height: 16),

              // ── Instructions ─────────────────────────────────────────
              if (prescription.instructions != null &&
                  prescription.instructions!.isNotEmpty) ...[
                _sectionTitle('Instructions / Conseils'),
                pw.SizedBox(height: 6),
                _box(prescription.instructions!),
                pw.SizedBox(height: 16),
              ],

              // ── Expiry ───────────────────────────────────────────────
              if (prescription.expiryDate != null) ...[
                pw.Text(
                  'Valable jusqu\'au : ${fmt.format(prescription.expiryDate!)}',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── Footer ───────────────────────────────────────────────
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Document généré par Medicare · $dateStr',
                    style: pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    '⚠ Ordonnance médicale — à usage unique',
                    style: pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final filename =
        'ordonnance_${patientName.replaceAll(' ', '_')}_$dateStr.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static pw.Widget _infoBox(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.indigo100),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
              pw.SizedBox(height: 2),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

  static pw.Widget _sectionTitle(String title) => pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo800,
        ),
      );

  static pw.Widget _box(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.indigo300, width: 3),
          ),
        ),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
      );

  static pw.Widget _medicationRow(int index, Medication med) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 22,
              height: 22,
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo700,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Center(
                child: pw.Text(
                  '$index',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(med.name,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(
                    [
                      if (med.dosage.isNotEmpty) med.dosage,
                      if (med.frequency.isNotEmpty) med.frequency,
                      if (med.duration != null && med.duration!.isNotEmpty)
                        med.duration!,
                    ].join('  ·  '),
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
