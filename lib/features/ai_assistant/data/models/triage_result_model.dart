import 'dart:convert';
import 'package:flutter/material.dart';

enum TriageUrgency { low, medium, high, emergency }

extension TriageUrgencyX on TriageUrgency {
  static TriageUrgency fromApi(String? v) => switch (v) {
        'medium'    => TriageUrgency.medium,
        'high'      => TriageUrgency.high,
        'emergency' => TriageUrgency.emergency,
        _           => TriageUrgency.low,
      };

  String get label => switch (this) {
        TriageUrgency.low       => 'Peut attendre 2-3 jours',
        TriageUrgency.medium    => 'Consultation dans les 24h',
        TriageUrgency.high      => 'Consultation aujourd\'hui',
        TriageUrgency.emergency => '🚨 Appelez le SAMU — 190',
      };

  Color get color => switch (this) {
        TriageUrgency.low       => const Color(0xFF22C55E),
        TriageUrgency.medium    => const Color(0xFFF59E0B),
        TriageUrgency.high      => const Color(0xFFEF4444),
        TriageUrgency.emergency => const Color(0xFF7C3AED),
      };

  Color get surface => color.withValues(alpha: 0.1);

  IconData get icon => switch (this) {
        TriageUrgency.low       => Icons.check_circle_rounded,
        TriageUrgency.medium    => Icons.schedule_rounded,
        TriageUrgency.high      => Icons.warning_amber_rounded,
        TriageUrgency.emergency => Icons.emergency_rounded,
      };
}

class TriageResultModel {
  final TriageUrgency urgency;
  final String specialty;
  final String recommendation;
  final String disclaimer;

  const TriageResultModel({
    required this.urgency,
    required this.specialty,
    required this.recommendation,
    required this.disclaimer,
  });

  /// Parse depuis la réponse brute du LLM (extrait le JSON même si entouré de markdown)
  static TriageResultModel? tryParse(String raw) {
    try {
      // Extrait {...} même si GPT ajoute du texte autour
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (match == null) return null;
      final data = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return TriageResultModel(
        urgency: TriageUrgencyX.fromApi(data['urgency'] as String?),
        specialty: data['specialty'] as String? ?? 'Médecin généraliste',
        recommendation: data['recommendation'] as String? ?? '',
        disclaimer: data['disclaimer'] as String? ??
            'Consultez un médecin pour un diagnostic précis.',
      );
    } catch (_) {
      return null;
    }
  }
}
