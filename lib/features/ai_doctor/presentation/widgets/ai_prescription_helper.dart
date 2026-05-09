import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/prescription_draft_model.dart';
import '../../providers/ai_doctor_provider.dart';

const _kAiColor = Color(0xFF059669); // vert médecin IA

/// Bottom sheet appelée depuis CreatePrescriptionScreen.
/// Retourne via [onAccept] le brouillon validé par le médecin.
class AiPrescriptionHelper extends ConsumerStatefulWidget {
  final String patientName;
  final void Function(PrescriptionDraftModel draft) onAccept;

  const AiPrescriptionHelper({
    super.key,
    required this.patientName,
    required this.onAccept,
  });

  @override
  ConsumerState<AiPrescriptionHelper> createState() =>
      _AiPrescriptionHelperState();
}

class _AiPrescriptionHelperState extends ConsumerState<AiPrescriptionHelper> {
  final _symptomsCtrl   = TextEditingController();
  final _diagnosisCtrl  = TextEditingController();
  final _ageCtrl        = TextEditingController();
  final _allergiesCtrl  = TextEditingController();

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _ageCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(prescriptionDraftProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kAiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: _kAiColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IA — Brouillon d\'ordonnance',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Patient : ${widget.patientName}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (draftState.draft == null) ...[
                    // Formulaire de saisie clinique
                    _field(_symptomsCtrl,
                        label: 'Symptômes / motif *',
                        hint: 'Ex: Fièvre 38.5°C, toux sèche depuis 3 jours',
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _field(_diagnosisCtrl,
                        label: 'Diagnostic envisagé',
                        hint: 'Ex: Rhinopharyngite aiguë'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_ageCtrl,
                              label: 'Âge', hint: 'Ex: 35'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_allergiesCtrl,
                              label: 'Allergies',
                              hint: 'Ex: Pénicilline'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (draftState.error != null)
                      _errorBanner(draftState.error!),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: draftState.isLoading
                            ? null
                            : () => ref
                                .read(prescriptionDraftProvider.notifier)
                                .generate(
                                  symptoms: _symptomsCtrl.text,
                                  diagnosis: _diagnosisCtrl.text,
                                  patientAge: _ageCtrl.text,
                                  allergies: _allergiesCtrl.text,
                                  patientName: widget.patientName,
                                ),
                        icon: draftState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.auto_awesome_rounded,
                                size: 18),
                        label: Text(
                          draftState.isLoading
                              ? 'Génération en cours…'
                              : 'Générer le brouillon',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAiColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Affichage du brouillon
                    _DraftPreview(draft: draftState.draft!),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Régénérer
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(prescriptionDraftProvider.notifier)
                                .reset(),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text('Modifier',
                                style: GoogleFonts.poppins(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Utiliser
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.onAccept(draftState.draft!);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text('Utiliser ce brouillon',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kAiColor,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Ce brouillon est proposé à titre indicatif. Vérifiez et modifiez avant validation.',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl,
      {required String label, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: _kAiColor, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String msg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.error)),
            ),
          ],
        ),
      );
}

// ── Aperçu du brouillon ───────────────────────────────────────────────────────

class _DraftPreview extends StatelessWidget {
  final PrescriptionDraftModel draft;
  const _DraftPreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Diagnostic
        if (draft.diagnosis.isNotEmpty) ...[
          _Label('Diagnostic suggéré'),
          const SizedBox(height: 4),
          _InfoBox(draft.diagnosis),
          const SizedBox(height: 14),
        ],

        // Médicaments
        _Label('Médicaments (${draft.medications.length})'),
        const SizedBox(height: 8),
        ...draft.medications.asMap().entries.map(
              (e) => _MedTile(index: e.key + 1, med: e.value),
            ),

        // Notes
        if (draft.notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Label('Conseils'),
          const SizedBox(height: 4),
          _InfoBox(draft.notes),
        ],

        // Suivi
        if (draft.followUp.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Label('Suivi recommandé'),
          const SizedBox(height: 4),
          _InfoBox(draft.followUp,
              icon: Icons.event_repeat_rounded,
              color: _kAiColor),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

class _InfoBox extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const _InfoBox(this.text, {this.icon, this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? _kAiColor).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: (color ?? _kAiColor).withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color ?? _kAiColor),
              const SizedBox(width: 8),
            ],
            Expanded(
                child: Text(text,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4))),
          ],
        ),
      );
}

class _MedTile extends StatelessWidget {
  final int index;
  final DraftMedication med;
  const _MedTile({required this.index, required this.med});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _kAiColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text('$index',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kAiColor)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${med.dosage} · ${med.frequency} · ${med.duration}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (med.instructions.isNotEmpty)
                    Text(med.instructions,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      );
}
