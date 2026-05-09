import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart' show Routes;
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/medicare_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  static const _roles = [
    _RoleData(
      id: 'patient',
      title: 'Patient',
      description: 'Gérez votre santé, prenez des rendez-vous et accédez à votre dossier médical.',
      icon: Icons.person_rounded,
      color: AppColors.patientColor,
      stats: ['Rendez-vous', 'Ordonnances', 'Suivi santé'],
    ),
    _RoleData(
      id: 'doctor',
      title: 'Médecin',
      description: 'Gérez vos patients, votre agenda et rédigez vos ordonnances en ligne.',
      icon: Icons.medical_services_rounded,
      color: AppColors.doctorColor,
      stats: ['Patients', 'Planning', 'Consultations'],
    ),
    _RoleData(
      id: 'admin',
      title: 'Administrateur',
      description: 'Supervisez la plateforme, les utilisateurs et consultez les statistiques.',
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.adminColor,
      stats: ['Utilisateurs', 'Statistiques', 'Gestion'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MediCare',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Bienvenue !',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Sélectionnez votre profil pour continuer',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Role cards
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _RoleCard(
                    data: _roles[i],
                    isSelected: _selectedRole == _roles[i].id,
                    onTap: () => setState(() => _selectedRole = _roles[i].id),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              MedicareButton(
                label: 'Continuer',
                onPressed: _selectedRole != null
                    ? () => context.go(Routes.login, extra: _selectedRole)
                    : null,
                suffixIcon: Icons.arrow_forward_rounded,
                color: _roles
                    .firstWhere(
                      (r) => r.id == _selectedRole,
                      orElse: () => _roles.first,
                    )
                    .color,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha:0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? data.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha:0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha:isSelected ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(data.icon, color: data.color, size: 28),
                ),
                const SizedBox(width: 16),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            // Stats chips
            const SizedBox(height: 14),
            Row(
              children: data.stats.map((stat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stat,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: data.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> stats;

  const _RoleData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stats,
  });
}
