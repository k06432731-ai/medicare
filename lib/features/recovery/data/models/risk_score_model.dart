import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum RiskLevel { low, medium, high, critical }

extension RiskLevelExt on RiskLevel {
  String get apiValue => switch (this) {
        RiskLevel.low => 'low',
        RiskLevel.medium => 'medium',
        RiskLevel.high => 'high',
        RiskLevel.critical => 'critical',
      };

  String get label => switch (this) {
        RiskLevel.low => 'Faible',
        RiskLevel.medium => 'Modéré',
        RiskLevel.high => 'Élevé',
        RiskLevel.critical => 'Critique',
      };

  Color get color => switch (this) {
        RiskLevel.low => AppColors.success,
        RiskLevel.medium => AppColors.warning,
        RiskLevel.high => AppColors.error,
        RiskLevel.critical => const Color(0xFF7C3AED),
      };

  Color get surface => switch (this) {
        RiskLevel.low => AppColors.success.withValues(alpha: 0.1),
        RiskLevel.medium => AppColors.warning.withValues(alpha: 0.1),
        RiskLevel.high => AppColors.error.withValues(alpha: 0.1),
        RiskLevel.critical => const Color(0x1A7C3AED),
      };

  static RiskLevel fromApi(String v) => switch (v) {
        'medium' => RiskLevel.medium,
        'high' => RiskLevel.high,
        'critical' => RiskLevel.critical,
        _ => RiskLevel.low,
      };
}

class RiskScoreModel {
  final int id;
  final int patientId;
  final String patientName;
  final int score;
  final RiskLevel level;
  final int noShowCount;
  final int daysSinceLastVisit;
  final int openCasesCount;
  final bool hasExpiredPrescription;
  final DateTime calculatedAt;

  const RiskScoreModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.score,
    required this.level,
    required this.noShowCount,
    required this.daysSinceLastVisit,
    required this.openCasesCount,
    required this.hasExpiredPrescription,
    required this.calculatedAt,
  });

  factory RiskScoreModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    return RiskScoreModel(
      id: (json['id'] as num?)?.toInt() ?? (d['id'] as num?)?.toInt() ?? 0,
      patientId: (d['patientId'] as num?)?.toInt() ?? 0,
      patientName: d['patientName'] as String? ?? 'Patient',
      score: (d['score'] as num?)?.toInt() ?? 0,
      level: RiskLevelExt.fromApi(d['level'] as String? ?? ''),
      noShowCount: (d['noShowCount'] as num?)?.toInt() ?? 0,
      daysSinceLastVisit: (d['daysSinceLastVisit'] as num?)?.toInt() ?? 0,
      openCasesCount: (d['openCasesCount'] as num?)?.toInt() ?? 0,
      hasExpiredPrescription: d['hasExpiredPrescription'] as bool? ?? false,
      calculatedAt:
          DateTime.tryParse(d['calculatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
