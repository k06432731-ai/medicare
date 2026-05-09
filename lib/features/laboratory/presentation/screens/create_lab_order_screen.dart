import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/laboratory_model.dart';
import '../../data/models/lab_order_model.dart';
import '../../data/repositories/lab_order_repository.dart';
import '../../providers/laboratory_provider.dart';

class CreateLabOrderScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const CreateLabOrderScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<CreateLabOrderScreen> createState() =>
      _CreateLabOrderScreenState();
}

class _CreateLabOrderScreenState
    extends ConsumerState<CreateLabOrderScreen> {
  final _notesCtrl = TextEditingController();
  LaboratoryModel? _selectedLab;
  final List<_TestEntry> _tests = [_TestEntry()];
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final t in _tests) { t.dispose(); }
    super.dispose();
  }

  double get _total =>
      _tests.fold(0, (sum, t) => sum + (double.tryParse(t.priceCtrl.text) ?? 0));

  Future<void> _submit() async {
    if (_selectedLab == null) {
      _showError('Sélectionnez un laboratoire / clinique.');
      return;
    }
    for (final t in _tests) {
      if (t.nameCtrl.text.trim().isEmpty) {
        _showError('Remplissez le nom de chaque analyse.');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final tests = _tests
          .map((t) => LabTest(
                name: t.nameCtrl.text.trim(),
                price:
                    double.tryParse(t.priceCtrl.text.trim()) ?? 0,
                notes: t.notesCtrl.text.trim().isEmpty
                    ? null
                    : t.notesCtrl.text.trim(),
              ))
          .toList();

      final data = {
        'patient': widget.patientId,
        'laboratory': _selectedLab!.id,
        'tests': tests.map((t) => t.toJson()).toList(),
        'totalAmount': _total,
        'orderedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
      };

      await ref.read(labOrderRepositoryProvider).createOrder(data);

      ref.invalidate(labOrdersByPatientProvider(widget.patientId));
      ref.invalidate(labOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bon d\'analyse créé avec succès',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final labsAsync = ref.watch(laboratoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bon d\'analyses'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Patient badge
          _PatientBadge(name: widget.patientName),
          const SizedBox(height: 24),

          // Lab selector
          _Label('Laboratoire / Clinique *'),
          const SizedBox(height: 8),
          labsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString(),
                style: const TextStyle(color: AppColors.error)),
            data: (labs) {
              if (labs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Aucun laboratoire disponible dans le système.',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                );
              }
              return _LabSelector(
                labs: labs,
                selected: _selectedLab,
                onChanged: (lab) => setState(() => _selectedLab = lab),
              );
            },
          ),
          const SizedBox(height: 24),

          // Tests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label('Analyses prescrites'),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _tests.add(_TestEntry())),
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: Color(0xFF06B6D4)),
                label: Text('Ajouter',
                    style: GoogleFonts.poppins(
                        color: AppColors.labColor, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._tests.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return _TestCard(
              entry: t,
              index: i,
              canDelete: _tests.length > 1,
              onDelete: () => setState(() {
                t.dispose();
                _tests.removeAt(i);
              }),
              onChanged: () => setState(() {}),
            );
          }),

          // Total
          if (_tests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.labColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.labColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total estimé',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.labColor)),
                  Text('${_total.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.labColor)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Notes
          _Label('Notes / Instructions'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _inputDeco('Ex: Jeûn de 12h requis avant la prise de sang…'),
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
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _isLoading ? 'Envoi…' : 'Émettre le bon d\'analyses',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.labColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textHint),
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
          borderSide: const BorderSide(
              color: Color(0xFF06B6D4), width: 1.5),
        ),
      );
}

// ── Lab Selector ───────────────────────────────────────────────────────────────

class _LabSelector extends StatelessWidget {
  final List<LaboratoryModel> labs;
  final LaboratoryModel? selected;
  final ValueChanged<LaboratoryModel> onChanged;

  const _LabSelector(
      {required this.labs,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: labs.asMap().entries.map((entry) {
          final i = entry.key;
          final lab = entry.value;
          final isSelected = selected?.id == lab.id;
          final color = lab.type.color;
          final icon = lab.type.icon;

          return Column(
            children: [
              ListTile(
                onTap: () => onChanged(lab),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(lab.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Row(
                  children: [
                    _Badge(label: lab.type.label, color: color),
                    if (lab.address != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(lab.address!,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.labColor, size: 22)
                    : const Icon(Icons.radio_button_unchecked_rounded,
                        color: AppColors.border, size: 22),
              ),
              if (i < labs.length - 1)
                const Divider(height: 1, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Test Card ──────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final _TestEntry entry;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _TestCard({
    required this.entry,
    required this.index,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  color: AppColors.labColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.labColor)),
                ),
              ),
              const SizedBox(width: 8),
              Text('Analyse',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _MiniField(
                  ctrl: entry.nameCtrl,
                  label: 'Nom de l\'analyse *',
                  hint: 'Ex: NFS, Glycémie…',
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _MiniField(
                  ctrl: entry.priceCtrl,
                  label: 'Prix (FCFA)',
                  hint: '5000',
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MiniField(
            ctrl: entry.notesCtrl,
            label: 'Remarque',
            hint: 'Ex: Jeûn requis',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final VoidCallback onChanged;

  const _MiniField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 13),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
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
              borderSide: const BorderSide(
                  color: Color(0xFF06B6D4), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────────

class _PatientBadge extends StatelessWidget {
  final String name;
  const _PatientBadge({required this.name});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.labColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.labColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded,
                color: Color(0xFF06B6D4), size: 20),
            const SizedBox(width: 10),
            Text('Patient : $name',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.labColor,
                    fontSize: 14)),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary));
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _TestEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    notesCtrl.dispose();
  }
}
