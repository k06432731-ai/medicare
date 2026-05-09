import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/recovery_case_model.dart';
import '../../data/models/risk_score_model.dart';
import '../../providers/recovery_provider.dart';

/// Compact widget embedded in the doctor's dashboard.
/// Shows at-risk patients and open recovery cases for this doctor's patients.
class DoctorRecoveryWidget extends ConsumerWidget {
  const DoctorRecoveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(doctorRecoveryViewProvider);

    return viewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (view) {
        if (view.cases.isEmpty && view.riskScores.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Patients à surveiller',
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push(Routes.recoveryCenter),
                  child: Text('Voir tout',
                      style: GoogleFonts.poppins(
                          color: AppColors.doctorColor, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Risk scores (high/critical)
            if (view.riskScores.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: view.riskScores
                      .take(3)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final i = entry.key;
                    final score = entry.value;
                    return Column(
                      children: [
                        _RiskPatientTile(score: score),
                        if (i < view.riskScores.take(3).length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Open cases
            if (view.cases.isNotEmpty)
              ...view.cases.take(2).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DoctorCaseCard(recoveryCase: c),
                  )),
          ],
        );
      },
    );
  }
}

class _RiskPatientTile extends StatelessWidget {
  final RiskScoreModel score;
  const _RiskPatientTile({required this.score});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: score.level.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text('${score.score}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: score.level.color)),
        ),
      ),
      title: Text(score.patientName,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        _signals(score),
        style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: score.level.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(score.level.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: score.level.color)),
      ),
    );
  }

  String _signals(RiskScoreModel s) {
    final parts = <String>[];
    if (s.noShowCount > 0) parts.add('${s.noShowCount} no-show(s)');
    if (s.daysSinceLastVisit > 30 && s.daysSinceLastVisit < 999) {
      parts.add('${s.daysSinceLastVisit}j inactif');
    }
    if (s.hasExpiredPrescription) parts.add('ordonnance expirée');
    return parts.isEmpty ? 'Risque détecté' : parts.join(' · ');
  }
}

class _DoctorCaseCard extends StatelessWidget {
  final RecoveryCaseModel recoveryCase;
  const _DoctorCaseCard({required this.recoveryCase});

  @override
  Widget build(BuildContext context) {
    final rc = recoveryCase;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rc.status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(rc.type.icon, color: rc.type.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rc.patientName,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(rc.type.label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: rc.status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(rc.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: rc.status.color)),
          ),
        ],
      ),
    );
  }
}
