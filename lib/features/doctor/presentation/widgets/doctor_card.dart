import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medicare/core/constants/api_constants.dart';
import 'package:medicare/core/constants/app_colors.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onBook;

  const DoctorCard({super.key, required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo()),
            _buildBookButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Avatar URLs from Strapi are relative paths — strip /api suffix from baseUrl
    final serverBase = ApiConstants.baseUrl.replaceAll('/api', '');
    final url = doctor.avatarUrl != null ? '$serverBase${doctor.avatarUrl}' : null;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.doctorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: url != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => _initialsWidget(),
                errorWidget: (context, url, err) => _initialsWidget(),
              ),
            )
          : _initialsWidget(),
    );
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        doctor.initials,
        style: TextStyle(
          color: AppColors.doctorColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dr. ${doctor.fullName}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          doctor.displaySpecialty,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _StatusBadge(available: doctor.isAvailable),
            if (doctor.consultationFee != null) ...[
              const SizedBox(width: 8),
              Text(
                '${doctor.consultationFee!.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return ElevatedButton(
      onPressed: doctor.isAvailable ? onBook : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: const Text('Réserver'),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool available;
  const _StatusBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (available ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: available ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            available ? 'Disponible' : 'Indisponible',
            style: TextStyle(
              color: available ? AppColors.success : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
