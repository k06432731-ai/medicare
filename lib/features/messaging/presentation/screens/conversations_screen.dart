import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../../doctor/providers/doctor_provider.dart';
import '../../../doctor/data/models/doctor_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/messaging_repository.dart';
import '../../providers/messaging_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  Future<void> _startNewConversation(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final isDoctor = authState.user.role == 'doctor';

    // Pour l'instant on liste seulement les médecins (côté patient).
    // Côté médecin : "nouvelle conversation" sera initié depuis la fiche patient.
    if (isDoctor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pour discuter avec un patient, ouvrez sa fiche depuis "Patients".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref2, _) {
          final doctorsAsync = ref2.watch(doctorsProvider(null));
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text('Choisir un médecin',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: doctorsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('Erreur : $e',
                            style: const TextStyle(color: AppColors.error))),
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return const Center(
                            child: Text('Aucun médecin disponible.'));
                      }
                      return ListView.builder(
                        controller: scrollCtrl,
                        itemCount: doctors.length,
                        itemBuilder: (_, i) => _DoctorPickerTile(
                          doctor: doctors[i],
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            try {
                              final conv = await ref
                                  .read(messagingRepositoryProvider)
                                  .findOrCreate(doctorId: doctors[i].id);
                              ref.invalidate(conversationsProvider);
                              if (context.mounted) {
                                context.push(Routes.chat, extra: {
                                  'conversation': conv,
                                  'userId': authState.user.id,
                                });
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur : $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);
    final authState = ref.watch(authProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;
    final isDoctor =
        authState is AuthAuthenticated && authState.user.role == 'doctor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Messages',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textPrimary)),
      ),
      floatingActionButton: isDoctor
          ? null // côté médecin : on initie depuis la fiche patient
          : FloatingActionButton.extended(
              onPressed: () => _startNewConversation(context, ref),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.chat_rounded, color: Colors.white),
              label: Text('Nouvelle discussion',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppColors.error))),
        data: (list) {
          if (list.isEmpty) return _EmptyConversations();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, indent: 80, endIndent: 16),
              itemBuilder: (ctx, i) => _ConversationTile(
                conv: list[i],
                userId: userId,
                onTap: () => context.push(
                  Routes.chat,
                  extra: {'conversation': list[i], 'userId': userId},
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tuile conversation ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final int userId;
  final VoidCallback onTap;
  const _ConversationTile(
      {required this.conv, required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = conv.otherName(userId);
    final unread = conv.unreadFor(userId);
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';
    final lastAt = conv.lastMessageAt;
    final timeStr = lastAt != null ? _timeLabel(lastAt) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primarySurface,
        child: Text(initials,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 15)),
      ),
      title: Text(
        name,
        style: GoogleFonts.poppins(
            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            color: AppColors.textPrimary),
      ),
      subtitle: conv.lastMessage != null
          ? Text(
              conv.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: unread > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      unread > 0 ? FontWeight.w600 : FontWeight.normal),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return DateFormat('EEEE', 'fr_FR').format(dt);
    return DateFormat('d MMM', 'fr_FR').format(dt);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucun message',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Vos échanges avec les médecins apparaîtront ici.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile médecin (sélecteur de nouvelle conversation) ───────────────────────

class _DoctorPickerTile extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  const _DoctorPickerTile({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primarySurface,
        child: Text(doctor.initials,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13)),
      ),
      title: Text('Dr. ${doctor.fullName}',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(doctor.displaySpecialty,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chat_outlined,
          color: AppColors.primary, size: 20),
    );
  }
}
