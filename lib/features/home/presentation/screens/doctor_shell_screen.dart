import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../../../features/messaging/providers/messaging_provider.dart';
import '../../../../features/notification/providers/notification_provider.dart';
import 'doctor_dashboard_screen.dart';
import '../../../doctor/presentation/screens/doctor_planning_screen.dart';
import '../../../doctor/presentation/screens/doctor_patients_screen.dart';
import '../../../messaging/presentation/screens/conversations_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

final doctorTabProvider = StateProvider<int>((ref) => 0);

class DoctorShellScreen extends ConsumerWidget {
  const DoctorShellScreen({super.key});

  static const _screens = [
    DoctorDashboardScreen(),
    DoctorPlanningScreen(),
    DoctorPatientsScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(doctorTabProvider);
    final authState = ref.watch(authProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    // Badges
    final unreadNotifs = ref.watch(unreadCountProvider).whenOrNull(data: (c) => c) ?? 0;
    final convs = ref.watch(conversationsProvider).whenOrNull(data: (l) => l) ?? [];
    final unreadMessages = convs.fold<int>(0, (s, c) => s + c.unreadFor(userId));

    final tabs = [
      _DTab(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', badge: unreadNotifs),
      _DTab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Planning'),
      _DTab(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Patients'),
      _DTab(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages', badge: unreadMessages),
      _DTab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isSelected = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(doctorTabProvider.notifier).state = i,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.doctorColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                color: isSelected
                                    ? AppColors.doctorColor
                                    : AppColors.textHint,
                                size: 24,
                              ),
                              if (tab.badge > 0)
                                Positioned(
                                  top: -4,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      tab.badge > 9 ? '9+' : '${tab.badge}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.doctorColor
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  const _DTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}
