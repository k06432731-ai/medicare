import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/risk_score_model.dart';
import '../../providers/recovery_provider.dart';

/// Small badge showing a patient's risk level.
/// Used in patient lists, appointment cards, etc.
class RiskScoreBadge extends ConsumerWidget {
  final int patientId;
  const RiskScoreBadge({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskAsync = ref.watch(patientRiskProvider(patientId));

    return riskAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (data) {
        final scoreData = data['riskScore'];
        if (scoreData == null) return const SizedBox.shrink();
        final score = RiskScoreModel.fromJson(scoreData as Map<String, dynamic>);
        if (score.level == RiskLevel.low) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: score.level.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 10, color: score.level.color),
              const SizedBox(width: 3),
              Text(
                score.level.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: score.level.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Inline patient recovery banner shown in the patient's own dashboard
/// when they have an open recovery case (no-show or inactivity).
class PatientRecoveryBanner extends ConsumerWidget {
  final int patientId;
  const PatientRecoveryBanner({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskAsync = ref.watch(patientRiskProvider(patientId));

    return riskAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (data) {
        final openCasesData = data['openCases'] as List?;
        if (openCasesData == null || openCasesData.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show the most relevant case (first = most recent)
        final caseData =
            openCasesData.first as Map<String, dynamic>;
        final type = caseData['type'] as String? ?? '';
        final String message;
        final IconData icon;
        final Color color;

        switch (type) {
          case 'noShow':
            message = 'Vous avez manqué un rendez-vous. Souhaitez-vous le reprogrammer ?';
            icon = Icons.event_busy_rounded;
            color = AppColors.error;
            break;
          case 'inactivePatient':
            message = 'Vous n\'avez pas eu de consultation récente. Pensez à prendre rendez-vous.';
            icon = Icons.person_off_rounded;
            color = AppColors.warning;
            break;
          case 'interruptedChronic':
            message = 'Votre traitement arrive à échéance. N\'oubliez pas de le renouveler.';
            icon = Icons.medication_liquid_rounded;
            color = AppColors.tertiary;
            break;
          default:
            return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
