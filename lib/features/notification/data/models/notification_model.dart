import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum NotificationType { appointment, prescription, invoice, recovery, message, system }

extension NotificationTypeX on NotificationType {
  static NotificationType fromApi(String? v) => switch (v) {
        'appointment'  => NotificationType.appointment,
        'prescription' => NotificationType.prescription,
        'invoice'      => NotificationType.invoice,
        'recovery'     => NotificationType.recovery,
        'message'      => NotificationType.message,
        _              => NotificationType.system,
      };

  IconData get icon => switch (this) {
        NotificationType.appointment  => Icons.calendar_month_rounded,
        NotificationType.prescription => Icons.medication_rounded,
        NotificationType.invoice      => Icons.receipt_long_rounded,
        NotificationType.recovery     => Icons.healing_rounded,
        NotificationType.message      => Icons.chat_bubble_rounded,
        NotificationType.system       => Icons.info_rounded,
      };

  Color get color => switch (this) {
        NotificationType.appointment  => AppColors.primary,
        NotificationType.prescription => AppColors.secondary,
        NotificationType.invoice      => AppColors.warning,
        NotificationType.recovery     => AppColors.error,
        NotificationType.message      => AppColors.tertiary,
        NotificationType.system       => AppColors.textSecondary,
      };

  Color get surface => color.withValues(alpha: 0.1);
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final int userId;
  final bool read;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.userId,
    required this.read,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Gère les deux formats Strapi (flat et attributes-wrapped)
    final Map<String, dynamic> d =
        json['attributes'] != null ? json['attributes'] as Map<String, dynamic> : json;
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: NotificationTypeX.fromApi(d['type'] as String?),
      userId: d['userId'] as int? ?? 0,
      read: d['read'] as bool? ?? false,
      data: d['data'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(d['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
