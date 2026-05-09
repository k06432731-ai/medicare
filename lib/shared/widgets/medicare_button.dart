import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum MedicareButtonVariant { primary, secondary, outline, ghost, danger }

class MedicareButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MedicareButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final double height;
  final Color? color;

  const MedicareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MedicareButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height = 54,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _resolveColor();

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: switch (variant) {
        MedicareButtonVariant.primary => _buildElevated(effectiveColor),
        MedicareButtonVariant.secondary => _buildSecondary(effectiveColor),
        MedicareButtonVariant.outline => _buildOutlined(effectiveColor),
        MedicareButtonVariant.ghost => _buildGhost(effectiveColor),
        MedicareButtonVariant.danger => _buildElevated(AppColors.error),
      },
    );
  }

  Color _resolveColor() {
    return switch (variant) {
      MedicareButtonVariant.secondary => AppColors.secondary,
      MedicareButtonVariant.danger => AppColors.error,
      _ => AppColors.primary,
    };
  }

  Widget _buildChild(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(foreground),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: 20, color: foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: 20, color: foreground),
        ],
      ],
    );
  }

  Widget _buildElevated(Color bgColor) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: AppColors.border,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _buildChild(AppColors.textOnPrimary),
    );
  }

  Widget _buildSecondary(Color bgColor) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor.withValues(alpha:0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _buildChild(bgColor),
    );
  }

  Widget _buildOutlined(Color borderColor) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _buildChild(borderColor),
    );
  }

  Widget _buildGhost(Color textColor) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _buildChild(textColor),
    );
  }
}
