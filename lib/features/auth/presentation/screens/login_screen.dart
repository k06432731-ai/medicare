import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../../../shared/widgets/medicare_button.dart';
import '../../../../shared/widgets/medicare_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Color get _roleColor => switch (widget.role) {
        'doctor' => AppColors.doctorColor,
        'admin' => AppColors.adminColor,
        _ => AppColors.patientColor,
      };

  String get _roleLabel => _roleLabelOf(widget.role);

  String _roleLabelOf(String role) => switch (role) {
        'doctor' => 'Médecin',
        'admin' => 'Administrateur',
        _ => 'Patient',
      };

  IconData get _roleIcon => switch (widget.role) {
        'doctor' => Icons.medical_services_rounded,
        'admin' => Icons.admin_panel_settings_rounded,
        _ => Icons.person_rounded,
      };

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    // React to auth errors → show snackbar and reset
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
      // Role mismatch guard — refuse login if the user's actual role
      // doesn't match what they selected on the role-selection screen.
      if (next is AuthAuthenticated) {
        final actualRole = next.user.role; // 'patient' / 'doctor' / 'admin'
        if (actualRole != widget.role) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ce compte est un compte ${_roleLabelOf(actualRole)}, '
                'pas un compte $_roleLabel. Choisissez le bon rôle.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
          ref.read(authProvider.notifier).logout();
          context.go(Routes.roleSelection);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go(Routes.roleSelection),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 32),

              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_roleIcon, size: 16, color: _roleColor),
                    const SizedBox(width: 6),
                    Text(
                      _roleLabel,
                      style: GoogleFonts.poppins(
                        color: _roleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text('Connexion',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Content de vous revoir ! Entrez vos identifiants pour accéder à votre espace.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    MedicareTextField(
                      controller: _emailController,
                      label: 'Adresse email',
                      hint: 'exemple@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    MedicarePasswordField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(
                          Routes.forgotPassword,
                          extra: widget.role,
                        ),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: GoogleFonts.poppins(
                            color: _roleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    MedicareButton(
                      label: 'Se connecter',
                      onPressed: _login,
                      isLoading: isLoading,
                      color: _roleColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pas encore de compte ? ",
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.go(Routes.register, extra: widget.role),
                      child: Text(
                        "S'inscrire",
                        style: GoogleFonts.poppins(
                          color: _roleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
