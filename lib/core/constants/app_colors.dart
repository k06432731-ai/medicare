import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Medical Blue (from design doc)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // Secondary - Health Green
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondarySurface = Color(0xFFECFDF5);

  // Tertiary - Appointment Purple
  static const Color tertiary = Color(0xFF8B5CF6);
  static const Color tertiarySurface = Color(0xFFF5F3FF);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFECFDF5);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // Shadows
  static const Color shadow = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);

  // Role-specific
  static const Color patientColor = Color(0xFF2563EB);
  static const Color doctorColor = Color(0xFF10B981);
  static const Color adminColor = Color(0xFF8B5CF6);

  // Lab / analyses
  static const Color labColor = Color(0xFF06B6D4);
  static const Color labSurface = Color(0xFFF0FDFE);

  // Medical record type colors
  static const Color mrLabResult = Color(0xFF3B82F6);
  static const Color mrImaging = Color(0xFF8B5CF6);
  static const Color mrConsultation = Color(0xFF10B981);
  static const Color mrVaccination = Color(0xFFF59E0B);
  static const Color mrSurgery = Color(0xFFEF4444);
  static const Color mrOther = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  static const LinearGradient doctorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
  );
}
