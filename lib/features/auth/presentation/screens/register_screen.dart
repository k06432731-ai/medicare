import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/auth/providers/auth_state.dart';
import '../../../../shared/widgets/medicare_button.dart';
import '../../../../shared/widgets/medicare_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _dobController = TextEditingController();
  bool _acceptTerms = false;

  Color get _roleColor => switch (widget.role) {
        'doctor' => AppColors.doctorColor,
        'admin' => AppColors.adminColor,
        _ => AppColors.patientColor,
      };

  String get _roleLabel => switch (widget.role) {
        'doctor' => 'Médecin',
        'admin' => 'Administrateur',
        _ => 'Patient',
      };

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Build registration payload for Strapi
    final data = <String, dynamic>{
      // Username unique basé sur prénom+nom+timestamp pour éviter les conflits Strapi
      'username': '${_firstNameController.text.trim().toLowerCase()}_${_lastNameController.text.trim().toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'appRole': widget.role,
    };

    if (widget.role == 'patient' && _dobController.text.isNotEmpty) {
      data['dateOfBirth'] = _dobController.text;
    }
    if (widget.role == 'doctor') {
      data['specialty'] = _specialtyController.text.trim();
      data['licenseNumber'] = _licenseController.text.trim();
    }

    ref.read(authProvider.notifier).register(data);
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: ColorScheme.light(primary: _roleColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      // Format ISO 8601 requis par Strapi (yyyy-MM-dd)
      _dobController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController, _lastNameController, _emailController,
      _phoneController, _passwordController, _confirmPasswordController,
      _specialtyController, _licenseController, _dobController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authProvider.notifier).clearError();
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
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.go(Routes.login, extra: widget.role),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 28),
              Text('Créer un compte',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Inscrivez-vous en tant que $_roleLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(label: 'Informations personnelles'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: MedicareTextField(
                            controller: _firstNameController,
                            label: 'Prénom',
                            hint: 'Jean',
                            prefixIcon: Icons.badge_outlined,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MedicareTextField(
                            controller: _lastNameController,
                            label: 'Nom',
                            hint: 'Dupont',
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    MedicareTextField(
                      controller: _emailController,
                      label: 'Adresse email',
                      hint: 'exemple@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    MedicareTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: '+33 6 00 00 00 00',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d+\-\s]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Téléphone requis';
                        if (v.replaceAll(RegExp(r'\D'), '').length < 8) {
                          return 'Numéro invalide';
                        }
                        return null;
                      },
                    ),

                    if (widget.role == 'patient') ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: AbsorbPointer(
                          child: MedicareTextField(
                            controller: _dobController,
                            label: 'Date de naissance',
                            hint: 'jj/mm/aaaa',
                            prefixIcon: Icons.cake_outlined,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Date requise' : null,
                          ),
                        ),
                      ),
                    ],

                    if (widget.role == 'doctor') ...[
                      const SizedBox(height: 24),
                      _SectionTitle(label: 'Informations professionnelles'),
                      const SizedBox(height: 16),
                      MedicareTextField(
                        controller: _specialtyController,
                        label: 'Spécialité',
                        hint: 'Cardiologie, Pédiatrie...',
                        prefixIcon: Icons.local_hospital_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Spécialité requise'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      MedicareTextField(
                        controller: _licenseController,
                        label: 'Numéro de licence médicale',
                        hint: 'Ex: RPP-12345',
                        prefixIcon: Icons.workspace_premium_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Numéro requis' : null,
                      ),
                    ],

                    const SizedBox(height: 24),
                    _SectionTitle(label: 'Sécurité'),
                    const SizedBox(height: 16),

                    MedicarePasswordField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        if (v.length < 8) return 'Minimum 8 caractères';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return 'Doit contenir une majuscule';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Doit contenir un chiffre';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    MedicarePasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer le mot de passe',
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirmation requise';
                        if (v != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) =>
                                setState(() => _acceptTerms = v ?? false),
                            activeColor: _roleColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                              children: [
                                const TextSpan(text: "J'accepte les "),
                                TextSpan(
                                  text: "Conditions d'utilisation",
                                  style: TextStyle(
                                    color: _roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: " et la "),
                                TextSpan(
                                  text: "Politique de confidentialité",
                                  style: TextStyle(
                                    color: _roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    MedicareButton(
                      label: "S'inscrire",
                      onPressed: _register,
                      isLoading: isLoading,
                      color: _roleColor,
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Déjà un compte ? ",
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.go(Routes.login, extra: widget.role),
                            child: Text(
                              "Se connecter",
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
