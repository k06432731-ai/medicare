import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_model.dart';

// ── Computed providers ─────────────────────────────────────────────────────────

/// Returns the authenticated user or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

/// Returns true if the current user is a doctor.
final isDoctorProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == 'doctor';
});

/// Returns true if the current user is a patient.
final isPatientProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == 'patient';
});

/// Returns true if the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == 'admin';
});

/// Returns the display name of the current user, or 'Utilisateur'.
final currentUserNameProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.fullName ?? 'Utilisateur';
});

/// Returns the initials of the current user.
final currentUserInitialsProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.initials ?? '?';
});
