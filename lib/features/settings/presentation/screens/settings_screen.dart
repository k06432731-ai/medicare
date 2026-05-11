import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Paramètres',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          const SizedBox(height: 10),
          _ToggleCard(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            title: 'Rendez-vous',
            subtitle: 'Rappels de vos consultations',
            value: settings.notifAppointment,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotifAppointment(v),
          ),
          const SizedBox(height: 10),
          _ToggleCard(
            icon: Icons.medication_rounded,
            iconColor: AppColors.secondary,
            title: 'Ordonnances',
            subtitle: 'Nouvelles prescriptions reçues',
            value: settings.notifPrescription,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotifPrescription(v),
          ),
          const SizedBox(height: 10),
          _ToggleCard(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.warning,
            title: 'Factures',
            subtitle: 'Factures en attente de paiement',
            value: settings.notifInvoice,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotifInvoice(v),
          ),

          const SizedBox(height: 28),

          // ── Apparence ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Apparence'),
          const SizedBox(height: 10),
          _ToggleCard(
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Mode sombre',
            subtitle: 'Interface en thème nuit',
            value: isDarkMode,
            onChanged: (v) {
              // Synchronise le ThemeMode applicatif et le flag persistant.
              ref
                  .read(themeModeProvider.notifier)
                  .setTheme(v ? ThemeMode.dark : ThemeMode.light);
              ref.read(settingsProvider.notifier).setDarkMode(v);
            },
          ),

          const SizedBox(height: 28),

          // ── Langue ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Langue'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: LocaleNotifier.supported.asMap().entries.map((entry) {
                final i = entry.key;
                final l = entry.value;
                final selected = l.languageCode == locale.languageCode;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primarySurface
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            l.languageCode == 'ar' ? 'ع' : 'FR',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        LocaleNotifier.labelOf(l),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () =>
                          ref.read(localeProvider.notifier).setLocale(l),
                    ),
                    if (i < LocaleNotifier.supported.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ── Aide & Support ────────────────────────────────────────────────
          _SectionHeader(title: 'Aide & Support'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'FAQ',
                  subtitle: 'Questions fréquemment posées',
                  onTap: () => _showFaq(context),
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.tertiary,
                  title: 'Politique de confidentialité',
                  subtitle: 'Comment nous protégeons vos données',
                  onTap: () => _showPrivacy(context),
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textHint,
                  title: 'Version de l\'application',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Questions fréquentes',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ..._faqItems.map((item) => _FaqTile(
                  question: item['q']!,
                  answer: item['a']!,
                )),
          ],
        ),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confidentialité',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'MediCare collecte uniquement les données nécessaires à la prestation de soins médicaux. '
          'Vos données sont chiffrées, stockées sur des serveurs sécurisés et ne sont jamais partagées sans votre consentement.',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris',
                style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

const _faqItems = [
  {
    'q': 'Comment prendre un rendez-vous ?',
    'a':
        'Allez dans l\'onglet Accueil, puis appuyez sur "Chercher un médecin". Sélectionnez un médecin et choisissez un créneau disponible.',
  },
  {
    'q': 'Comment accéder à mes ordonnances ?',
    'a':
        'Vos ordonnances sont disponibles dans l\'onglet "Dossier médical". Elles sont automatiquement ajoutées après chaque consultation.',
  },
  {
    'q': 'Mes données sont-elles sécurisées ?',
    'a':
        'Oui. Toutes vos données médicales sont chiffrées et stockées sur des serveurs sécurisés. Vous pouvez activer la biométrie pour un accès encore plus sûr.',
  },
  {
    'q': 'Comment contacter mon médecin ?',
    'a':
        'Depuis la fiche d\'un médecin, vous pouvez voir ses informations de contact. Pour le moment, le contact direct passe par le secrétariat.',
  },
  {
    'q': 'Comment annuler un rendez-vous ?',
    'a':
        'Allez dans votre liste de rendez-vous et appuyez sur le rendez-vous concerné pour le modifier ou l\'annuler.',
  },
];

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primarySurface,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.answer,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
