import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/prescription_model.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../providers/prescription_provider.dart';
import '../../../ai_doctor/data/models/prescription_draft_model.dart';
import '../../../ai_doctor/presentation/widgets/ai_prescription_helper.dart';

class CreatePrescriptionScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const CreatePrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState
    extends ConsumerState<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<_MedEntry> _medications = [_MedEntry()];

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _instructionsCtrl.dispose();
    for (final m in _medications) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate medications
    for (final m in _medications) {
      if (m.nameCtrl.text.trim().isEmpty) {
        _showError('Remplissez le nom de chaque médicament.');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final meds = _medications
          .map((m) => Medication(
                name: m.nameCtrl.text.trim(),
                dosage: m.dosageCtrl.text.trim(),
                frequency: m.freqCtrl.text.trim(),
                duration: m.durationCtrl.text.trim().isEmpty
                    ? null
                    : m.durationCtrl.text.trim(),
              ))
          .toList();

      final data = <String, dynamic>{
        'patient': widget.patientId,
        'issuedDate': DateTime.now().toIso8601String(),
        'status': 'active',
        'medications': meds.map((m) => m.toJson()).toList(),
        if (_diagnosisCtrl.text.trim().isNotEmpty)
          'diagnosis': _diagnosisCtrl.text.trim(),
        if (_instructionsCtrl.text.trim().isNotEmpty)
          'instructions': _instructionsCtrl.text.trim(),
        if (_expiryDate != null)
          'expiryDate': _expiryDate!.toIso8601String(),
      };

      await ref
          .read(prescriptionRepositoryProvider)
          .createPrescription(data);

      ref.invalidate(prescriptionsByPatientProvider(widget.patientId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ordonnance créée avec succès',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── AI helper ──────────────────────────────────────────────────────────────

  void _showAiHelper(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiPrescriptionHelper(
        patientName: widget.patientName,
        onAccept: _applyDraft,
      ),
    );
  }

  void _applyDraft(PrescriptionDraftModel draft) {
    // Pre-fill diagnosis
    if (draft.diagnosis.isNotEmpty) {
      _diagnosisCtrl.text = draft.diagnosis;
    }

    // Pre-fill instructions (notes + suivi)
    final notesParts = [
      if (draft.notes.isNotEmpty) draft.notes,
      if (draft.followUp.isNotEmpty) 'Suivi recommandé : ${draft.followUp}',
    ];
    if (notesParts.isNotEmpty) {
      _instructionsCtrl.text = notesParts.join('\n');
    }

    // Replace medications list
    if (draft.medications.isNotEmpty) {
      setState(() {
        for (final m in _medications) {
          m.dispose();
        }
        _medications.clear();
        for (final dm in draft.medications) {
          final entry = _MedEntry();
          entry.nameCtrl.text    = dm.name;
          entry.dosageCtrl.text  = dm.dosage;
          entry.freqCtrl.text    = dm.frequency;
          entry.durationCtrl.text = dm.duration;
          _medications.add(entry);
        }
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle ordonnance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Aide IA — brouillon automatique',
            child: IconButton(
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF059669)),
              onPressed: () => _showAiHelper(context),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Patient badge
            _PatientBadge(name: widget.patientName),
            const SizedBox(height: 24),

            // Diagnosis
            _SectionTitle(title: 'Diagnostic'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _diagnosisCtrl,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDecoration('Ex: Hypertension artérielle'),
            ),
            const SizedBox(height: 24),

            // Medications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'Médicaments'),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _medications.add(_MedEntry())),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.doctorColor),
                  label: Text('Ajouter',
                      style: GoogleFonts.poppins(
                          color: AppColors.doctorColor, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._medications.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return _MedicationCard(
                entry: m,
                index: i,
                canDelete: _medications.length > 1,
                onDelete: () => setState(() {
                  m.dispose();
                  _medications.removeAt(i);
                }),
              );
            }),
            const SizedBox(height: 24),

            // Instructions
            _SectionTitle(title: 'Instructions / Conseils'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDecoration(
                  'Ex: Prendre avec de la nourriture, éviter l\'alcool…'),
            ),
            const SizedBox(height: 24),

            // Expiry date
            _SectionTitle(title: "Date d'expiration (facultatif)"),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickExpiry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate != null
                          ? DateFormat('d MMMM yyyy', 'fr_FR')
                              .format(_expiryDate!)
                          : 'Sélectionner une date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _expiryDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? 'Enregistrement…' : 'Créer l\'ordonnance',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.doctorColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.doctorColor, width: 1.5),
        ),
      );
}

// ── Medication card ────────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final _MedEntry entry;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.entry,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.doctorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.doctorColor)),
                ),
              ),
              const SizedBox(width: 8),
              Text('Médicament',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldRow(
            ctrl: entry.nameCtrl,
            label: 'Nom *',
            hint: 'Ex: Amoxicilline',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FieldRow(
                  ctrl: entry.dosageCtrl,
                  label: 'Dosage *',
                  hint: '500mg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldRow(
                  ctrl: entry.freqCtrl,
                  label: 'Fréquence *',
                  hint: '3x/jour',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FieldRow(
            ctrl: entry.durationCtrl,
            label: 'Durée',
            hint: 'Ex: 7 jours',
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _FieldRow(
      {required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.doctorColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _PatientBadge extends StatelessWidget {
  final String name;
  const _PatientBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.doctorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.doctorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded,
              color: AppColors.doctorColor, size: 20),
          const SizedBox(width: 10),
          Text(
            'Patient : $name',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.doctorColor,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary));
  }
}

// ── Data holder ────────────────────────────────────────────────────────────────

class _MedEntry {
  final nameCtrl = TextEditingController();
  final dosageCtrl = TextEditingController();
  final freqCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    dosageCtrl.dispose();
    freqCtrl.dispose();
    durationCtrl.dispose();
  }
}
