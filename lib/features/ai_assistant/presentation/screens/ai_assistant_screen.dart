import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/triage_result_model.dart';
import '../../providers/ai_assistant_provider.dart';

// ── Couleurs IA ───────────────────────────────────────────────────────────────

const _kAiFrom = Color(0xFF4F46E5); // indigo
const _kAiTo   = Color(0xFF0EA5E9); // sky blue

class AiAssistantScreen extends ConsumerWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(aiModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, ref, mode),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: mode == AiMode.chat
            ? const _ChatView(key: ValueKey('chat'))
            : const _TriageView(key: ValueKey('triage')),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, AiMode mode) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kAiFrom, _kAiTo],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MediCare AI',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17)),
                        Text('Assistant médical intelligent',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    // Reset
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white70, size: 20),
                      tooltip: 'Nouvelle conversation',
                      onPressed: () {
                        ref.read(aiChatProvider.notifier).reset();
                        ref.read(triageProvider.notifier).reset();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Toggle mode
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4, bottom: 8),
                  child: _ModeToggle(current: mode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toggle chat / triage ──────────────────────────────────────────────────────

class _ModeToggle extends ConsumerWidget {
  final AiMode current;
  const _ModeToggle({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: '💬  Conseils santé',
            active: current == AiMode.chat,
            onTap: () =>
                ref.read(aiModeProvider.notifier).state = AiMode.chat,
          ),
          _Pill(
            label: '🔍  Triage',
            active: current == AiMode.triage,
            onTap: () =>
                ref.read(aiModeProvider.notifier).state = AiMode.triage,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? _kAiFrom : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VUE CHAT
// ─────────────────────────────────────────────────────────────────────────────

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({super.key});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Scroll automatique quand les messages changent
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: chatState.messages.length,
            itemBuilder: (ctx, i) {
              final msg = chatState.messages[i];
              return msg.isTyping
                  ? _TypingBubble()
                  : _ChatBubble(msg: msg);
            },
          ),
        ),
        if (chatState.error != null)
          _ErrorBanner(message: chatState.error!),
        _ChatInput(
          controller: _ctrl,
          loading: chatState.isLoading,
          onSend: () {
            ref.read(aiChatProvider.notifier).send(_ctrl.text);
            _ctrl.clear();
          },
        ),
      ],
    );
  }
}

// ── Bulle de chat ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kAiFrom, _kAiTo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [_kAiFrom, _kAiTo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border:
                    isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: _MarkdownText(
                text: msg.content,
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Rendu simple du markdown (gras avec **)
class _MarkdownText extends StatelessWidget {
  final String text;
  final Color color;
  const _MarkdownText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    text.splitMapJoin(
      RegExp(r'\*\*(.*?)\*\*'),
      onMatch: (m) {
        spans.add(TextSpan(
          text: m.group(1),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: color, fontSize: 13),
        ));
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) {
          spans.add(TextSpan(
            text: s,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.normal,
                color: color,
                fontSize: 13,
                height: 1.45),
          ));
        }
        return '';
      },
    );
    return RichText(text: TextSpan(children: spans));
  }
}

// ── Indicateur de frappe ──────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kAiFrom, _kAiTo]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (ctx, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final opacity = (((_anim.value + delay) % 1.0)).clamp(0.2, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _kAiFrom,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de saisie chat ──────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;
  const _ChatInput(
      {required this.controller, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Posez votre question santé…',
                  hintStyle: GoogleFonts.poppins(
                      color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kAiFrom, _kAiTo]),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onTap: loading ? null : onSend,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VUE TRIAGE
// ─────────────────────────────────────────────────────────────────────────────

class _TriageView extends ConsumerStatefulWidget {
  const _TriageView({super.key});

  @override
  ConsumerState<_TriageView> createState() => _TriageViewState();
}

class _TriageViewState extends ConsumerState<_TriageView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final triageState = ref.watch(triageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explication
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kAiFrom.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: _kAiFrom.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _kAiFrom, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Décrivez vos symptômes et l\'IA vous oriente vers le bon spécialiste.',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Zone de saisie
          Text('Vos symptômes',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Ex : J\'ai de la fièvre depuis 2 jours, des maux de tête et de la fatigue…',
              hintStyle: GoogleFonts.poppins(
                  color: AppColors.textHint, fontSize: 13, height: 1.4),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kAiFrom, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Analyser
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kAiFrom, _kAiTo]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: triageState.isLoading
                    ? null
                    : () => ref
                        .read(triageProvider.notifier)
                        .analyze(_ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: triageState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Analyser mes symptômes',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),

          // Erreur
          if (triageState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: triageState.error!),
          ],

          // Résultat
          if (triageState.result != null) ...[
            const SizedBox(height: 24),
            _TriageResultCard(result: triageState.result!),
          ],
        ],
      ),
    );
  }
}

// ── Carte résultat triage ─────────────────────────────────────────────────────

class _TriageResultCard extends ConsumerWidget {
  final TriageResultModel result;
  const _TriageResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = result.urgency;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: u.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: u.color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête urgence
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: u.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(u.icon, color: u.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Niveau d\'urgence',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                      Text(u.label,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: u.color)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spécialité recommandée
                Row(
                  children: [
                    const Icon(Icons.medical_services_rounded,
                        color: _kAiFrom, size: 18),
                    const SizedBox(width: 8),
                    Text('Spécialiste recommandé',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(result.specialty,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),

                // Recommandation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: _kAiFrom, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(result.recommendation,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bouton Prendre RDV
                if (result.urgency != TriageUrgency.emergency)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(Routes.doctorsList),
                      icon: const Icon(Icons.calendar_month_rounded,
                          size: 18),
                      label: Text('Prendre RDV — ${result.specialty}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAiFrom,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  // Urgence → appel SAMU
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.phone_rounded, size: 18),
                      label: Text('Appeler le SAMU — 190',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: u.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Disclaimer
                Text(result.disclaimer,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bannière erreur ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.error,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
