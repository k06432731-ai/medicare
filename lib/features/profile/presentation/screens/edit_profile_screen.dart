import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/medicare_button.dart';
import '../../../../shared/widgets/medicare_text_field.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../auth/data/models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _specialtyCtrl;
  late TextEditingController _feeCtrl;

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isAvailable = true;
  String? _error;
  UserModel? _user;
  File? _localAvatarFile; // picked but not yet uploaded

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    _user = authState is AuthAuthenticated ? authState.user : null;

    _firstNameCtrl = TextEditingController(text: _user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: _user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: _user?.phone ?? '');
    _bioCtrl = TextEditingController(text: _user?.bio ?? '');
    _specialtyCtrl = TextEditingController(text: _user?.specialty ?? '');
    _feeCtrl = TextEditingController(
      text: _user?.consultationFee != null
          ? _user!.consultationFee!.toStringAsFixed(0)
          : '',
    );
    _isAvailable = _user?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _specialtyCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  // ── Avatar picker ───────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() {
      _localAvatarFile = File(image.path);
      _isUploadingAvatar = true;
    });

    try {
      await ref.read(authRepositoryProvider).uploadAvatar(image.path);

      // Refresh user from server to get proper avatar URL
      final updatedUser = await ref.read(authRepositoryProvider).getMe();
      ref.read(authProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo de profil mise à jour',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _localAvatarFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final data = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
      };
      if (_user?.role == 'doctor') {
        if (_specialtyCtrl.text.trim().isNotEmpty) {
          data['specialty'] = _specialtyCtrl.text.trim();
        }
        if (_feeCtrl.text.trim().isNotEmpty) {
          data['consultationFee'] =
              double.tryParse(_feeCtrl.text.trim()) ?? 0;
        }
        data['isAvailable'] = _isAvailable;
      }

      final updatedUser =
          await ref.read(authRepositoryProvider).updateProfile(data);
      ref.read(authProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour !',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = _user?.role == 'doctor';
    // Re-read user in case avatar was just updated
    final authState = ref.watch(authProvider);
    final liveUser =
        authState is AuthAuthenticated ? authState.user : _user;
    final avatarUrl = liveUser?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Enregistrer',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: _localAvatarFile != null
                            ? Image.file(_localAvatarFile!,
                                fit: BoxFit.cover)
                            : avatarUrl != null
                                ? Image.network(avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, trace) =>
                                        _Initials(liveUser?.initials ?? '?'))
                                : _Initials(liveUser?.initials ?? '?'),
                      ),
                    ),
                    // Upload indicator overlay
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    // Camera button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAvatar,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Appuyez sur la caméra pour changer la photo',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 28),

              // ── Informations personnelles ─────────────────────────────
              _SectionTitle('Informations personnelles'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MedicareTextField(
                      controller: _firstNameCtrl,
                      label: 'Prénom',
                      hint: 'Mohamed',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MedicareTextField(
                      controller: _lastNameCtrl,
                      label: 'Nom',
                      hint: 'Ben Ali',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MedicareTextField(
                controller: _phoneCtrl,
                label: 'Téléphone',
                hint: '+216 XX XXX XXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              MedicareTextField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Quelques mots sur vous…',
                prefixIcon: Icons.info_outline_rounded,
                maxLines: 3,
              ),

              // ── Informations médecin ──────────────────────────────────
              if (isDoctor) ...[
                const SizedBox(height: 28),
                _SectionTitle('Informations médicales'),
                const SizedBox(height: 16),
                MedicareTextField(
                  controller: _specialtyCtrl,
                  label: 'Spécialité',
                  hint: 'Ex: Cardiologie',
                  prefixIcon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 16),
                MedicareTextField(
                  controller: _feeCtrl,
                  label: 'Tarif consultation (DT)',
                  hint: 'Ex: 40',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Availability toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isAvailable
                                  ? AppColors.success
                                  : AppColors.textSecondary)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isAvailable
                              ? Icons.check_circle_outline_rounded
                              : Icons.do_not_disturb_rounded,
                          size: 20,
                          color: _isAvailable
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Disponible pour les RDV',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text(
                              _isAvailable
                                  ? 'Les patients peuvent vous prendre RDV'
                                  : 'Indisponible — RDV désactivés',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.success
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Error banner ──────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              MedicareButton(
                label: 'Enregistrer les modifications',
                onPressed: _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Local widgets ─────────────────────────────────────────────────────────────

class _Initials extends StatelessWidget {
  final String initials;
  const _Initials(this.initials);
  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
