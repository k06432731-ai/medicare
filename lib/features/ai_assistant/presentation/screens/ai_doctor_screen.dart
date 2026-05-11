import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../data/models/triage_result_model.dart';
import '../../../../app/router.dart';

/// Écran dédié au triage symptomatique IA.
/// Distinct de [AiAssistantScreen] (chat libre) — cet écran guide l'utilisateur
/// à travers une analyse structurée de ses symptômes et retourne un résultat
/// coloré avec le niveau d'urgence recommandé.
class AiDoctorScreen extends ConsumerStatefulWidget {
  const AiDoctorScreen({super.key});

  @override
  ConsumerState<AiDoctorScreen> createState() => _AiDoctorScreenState();
}

class _AiDoctorScreenState extends ConsumerState<AiDoctorScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    await ref.read(triageProvider.notifier).analyze(text);
  }

  void _reset() {
    ref.read(triageProvider.notifier).reset();
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Docteur IA',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (state.result != null)
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Réinitialiser',
                  style: GoogleFonts.poppins(fontSize: 13)),
              onPressed: _reset,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Analyse symptomatique IA',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Décrivez vos symptômes en détail. '
                    'Le Docteur IA vous indiquera le niveau d\'urgence '
                    'et les spécialistes à consulter.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'En cas d\'urgence : appelez le 190',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Formulaire ────────────────────────────────────────────────────
            if (state.result == null) ...[
              Text(
                'Vos symptômes',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  hintText:
                      'Ex : "Depuis 2 jours j\'ai de la fièvre à 38,5°C, des douleurs à la gorge et une fatigue intense..."',
                  hintStyle: GoogleFonts.poppins(
                      color: AppColors.textHint, fontSize: 13, height: 1.5),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              // Exemples de symptômes rapides
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Fièvre',
                  'Douleur thoracique',
                  'Maux de tête',
                  'Douleurs abdominales',
                  'Toux',
                  'Fatigue intense',
                ].map((s) => ActionChip(
                      label: Text(s,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.primary)),
                      backgroundColor: AppColors.primarySurface,
                      side: BorderSide.none,
                      onPressed: () {
                        _ctrl.text = _ctrl.text.isEmpty ? s : '${_ctrl.text}, $s';
                        _ctrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: _ctrl.text.length));
                      },
                    )).toList(),
              ),

              const SizedBox(height: 20),

              if (state.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, size: 20),
                  label: Text(
                    state.isLoading ? 'Analyse en cours…' : 'Analyser mes symptômes',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: state.isLoading ? null : _analyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            // ── Résultat triage ───────────────────────────────────────────────
            if (state.result != null)
              _TriageResultCard(result: state.result!),
          ],
        ),
      ),
    );
  }
}

// ── Carte résultat ────────────────────────────────────────────────────────────

class _TriageResultCard extends ConsumerWidget {
  final TriageResultModel result;
  const _TriageResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = result.urgency.color;
    final icon = result.urgency.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Niveau d'urgence
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                result.urgency.label.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                result.urgency.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Spécialiste recommandé
        _SectionTitle('Spécialiste recommandé'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.specialty,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recommandation détaillée
        _SectionTitle('Recommandation'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            result.recommendation,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.6),
          ),
        ),

        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.disclaimer,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CTA : prendre rendez-vous
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text('Prendre un rendez-vous',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            onPressed: () => context.push(Routes.doctorsList),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text('Discuter avec l\'assistant',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            onPressed: () => context.push(Routes.aiAssistant),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
      );
}
