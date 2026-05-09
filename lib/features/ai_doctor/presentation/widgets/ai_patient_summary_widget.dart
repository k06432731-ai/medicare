import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/ai_doctor_provider.dart';

const _kAiColor = Color(0xFF059669);

/// Carte collapsible affichant le résumé IA du dossier patient.
/// À placer dans DoctorPatientDetailScreen au-dessus des onglets.
class AiPatientSummaryWidget extends ConsumerStatefulWidget {
  final int patientId;
  const AiPatientSummaryWidget({super.key, required this.patientId});

  @override
  ConsumerState<AiPatientSummaryWidget> createState() =>
      _AiPatientSummaryWidgetState();
}

class _AiPatientSummaryWidgetState
    extends ConsumerState<AiPatientSummaryWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Auto-expand when summary just arrives
    ref.listen<PatientSummaryState>(patientSummaryProvider, (prev, next) {
      if ((prev?.summary == null) && next.summary != null) {
        setState(() => _expanded = true);
      }
    });

    final state = ref.watch(patientSummaryProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAiColor.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: _kAiColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: state.summary != null
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kAiColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        color: _kAiColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résumé IA du dossier',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          state.summary != null
                              ? 'Appuyez pour ${_expanded ? 'réduire' : 'afficher'}'
                              : 'Analyse automatique du dossier',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right-side controls
                  if (state.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kAiColor),
                    )
                  else if (state.summary != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              ref.read(patientSummaryProvider.notifier).reset(),
                          child: const Tooltip(
                            message: 'Réinitialiser',
                            child: Icon(Icons.refresh_rounded,
                                size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    )
                  else
                    _AnalyzeButton(
                      onTap: () => ref
                          .read(patientSummaryProvider.notifier)
                          .summarize(widget.patientId),
                    ),
                ],
              ),
            ),
          ),

          // ── Error banner ───────────────────────────────────────────────
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.error!,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Summary body ───────────────────────────────────────────────
          if (state.summary != null && _expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kAiColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _kAiColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.summary!,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.55),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Résumé généré par IA — à titre indicatif uniquement.',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Small pill button ──────────────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AnalyzeButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kAiColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 13, color: _kAiColor),
              const SizedBox(width: 4),
              Text('Analyser',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kAiColor)),
            ],
          ),
        ),
      );
}
