import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/app_lock_provider.dart';
import '../../providers/settings_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _checkingBiometrics = false;
  bool? _biometricsAvailable;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    setState(() => _checkingBiometrics = true);
    final available =
        await ref.read(appLockProvider.notifier).canUseBiometrics();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _checkingBiometrics = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // Verify identity before enabling
      final ok =
          await ref.read(appLockProvider.notifier).authenticate();
      if (!ok) return;
    }
    await ref.read(settingsProvider.notifier).setBiometricEnabled(enable);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final biometricsAvailable = _biometricsAvailable ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Sécurité',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Biométrie ────────────────────────────────────────────────────
          _SectionHeader(title: 'Authentification biométrique'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _checkingBiometrics
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.fingerprint_rounded,
                            color: biometricsAvailable
                                ? AppColors.primary
                                : AppColors.textHint,
                            size: 22,
                          ),
                  ),
                  title: Text('Déverrouillage biométrique',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    biometricsAvailable
                        ? 'Utiliser empreinte ou Face ID pour déverrouiller'
                        : 'Non disponible sur cet appareil',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: _checkingBiometrics
                      ? null
                      : Switch.adaptive(
                          value: settings.biometricEnabled &&
                              biometricsAvailable,
                          onChanged: biometricsAvailable
                              ? _toggleBiometric
                              : null,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primarySurface,
                        ),
                ),
                if (settings.biometricEnabled && biometricsAvailable) ...[
                  const Divider(height: 1, indent: 72),
                  // Auto-lock delay
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.timer_outlined,
                              color: AppColors.warning, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verrouillage automatique',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('Délai avant verrouillage',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        DropdownButton<int>(
                          value: settings.autoLockMinutes,
                          underline: const SizedBox(),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(
                                value: -1, child: Text('Immédiat')),
                            DropdownMenuItem(value: 1, child: Text('1 min')),
                            DropdownMenuItem(value: 5, child: Text('5 min')),
                            DropdownMenuItem(
                                value: 15, child: Text('15 min')),
                            DropdownMenuItem(
                                value: 30, child: Text('30 min')),
                            DropdownMenuItem(value: 0, child: Text('Jamais')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setAutoLockMinutes(v);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Mot de passe ────────────────────────────────────────────────
          _SectionHeader(title: 'Mot de passe'),
          const SizedBox(height: 10),
          Container(
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.error, size: 20),
              ),
              title: Text('Changer le mot de passe',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Modifier votre mot de passe actuel',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
              onTap: () => context.push(Routes.changePassword),
            ),
          ),

          const SizedBox(height: 28),

          // ── Confidentialité ──────────────────────────────────────────────
          _SectionHeader(title: 'Confidentialité'),
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
                  icon: Icons.visibility_off_outlined,
                  iconColor: AppColors.tertiary,
                  title: 'Capture d\'écran',
                  subtitle: 'Désactivée pour protéger vos données médicales',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Actif',
                        style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.primary,
                  title: 'Chiffrement des données',
                  subtitle: 'Vos données sont chiffrées (AES-256)',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Actif',
                        style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.https_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Communication sécurisée',
                  subtitle: 'Toutes les communications passent par HTTPS',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Actif',
                        style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
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
      trailing: trailing,
    );
  }
}
