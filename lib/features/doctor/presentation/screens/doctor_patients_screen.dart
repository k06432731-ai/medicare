import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../appointment/providers/appointment_provider.dart';

class DoctorPatientsScreen extends ConsumerWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes Patients'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (appointments) {
          // Extract unique patients
          final seen = <int>{};
          final patients = <Map<String, dynamic>>[];
          for (final appt in appointments) {
            final p = appt.patient;
            if (p == null) continue;
            final pid = p['id'] as int? ?? 0;
            if (seen.contains(pid)) continue;
            seen.add(pid);

            // Count appointments for this patient
            final count = appointments.where((a) => a.patientId == pid).length;
            patients.add({...p, '_appointmentCount': count});
          }

          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Aucun patient pour l\'instant',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, i) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PatientCard(
              patient: patients[i],
              onTap: () => context.push(Routes.doctorPatientDetail, extra: {
                'patientId': patients[i]['id'] as int? ?? 0,
                'patientName': _resolveName(patients[i]),
                'patientPhone': patients[i]['phone'] as String?,
              }),
            ),
          );
        },
      ),
    );
  }
}

String _resolveName(Map<String, dynamic> p) {
  final first = p['firstName'] as String? ?? '';
  final last = p['lastName'] as String? ?? '';
  if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
  return p['username'] as String? ?? 'Patient';
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  String get _name {
    final first = patient['firstName'] as String? ?? '';
    final last = patient['lastName'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return patient['username'] as String? ?? 'Patient';
  }

  String get _initials {
    final first = patient['firstName'] as String? ?? '';
    final last = patient['lastName'] as String? ?? '';
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    final name = patient['username'] as String? ?? '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final count = patient['_appointmentCount'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySurface,
            child: Text(_initials,
                style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                if (patient['phone'] != null)
                  Text(patient['phone'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count RDV',
                style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
    );
  }
}
