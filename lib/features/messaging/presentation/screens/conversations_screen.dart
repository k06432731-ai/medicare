import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../data/models/conversation_model.dart';
import '../../providers/messaging_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);
    final authState = ref.watch(authProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

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
