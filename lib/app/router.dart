import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/auth_state.dart';
import '../features/home/presentation/screens/patient_shell_screen.dart';
import '../features/home/presentation/screens/doctor_shell_screen.dart';
import '../features/home/presentation/screens/admin_home_screen.dart';
import '../features/doctor/presentation/screens/doctors_list_screen.dart';
import '../features/doctor/data/models/doctor_model.dart';
import '../features/appointment/presentation/screens/book_appointment_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/doctor/presentation/screens/doctor_patient_detail_screen.dart';
import '../features/prescription/presentation/screens/create_prescription_screen.dart';
import '../features/medical_record/presentation/screens/create_medical_record_screen.dart';
import '../features/invoice/presentation/screens/patient_invoices_screen.dart';
import '../features/laboratory/presentation/screens/create_lab_order_screen.dart';
import '../features/laboratory/presentation/screens/lab_orders_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/security_screen.dart';
import '../features/settings/presentation/screens/change_password_screen.dart';
import '../features/recovery/presentation/screens/recovery_center_screen.dart';
import '../features/notification/presentation/screens/notifications_screen.dart';
import '../features/messaging/presentation/screens/chat_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/messaging/data/models/conversation_model.dart';
import '../features/teleconsultation/presentation/screens/teleconsultation_screen.dart';
import '../features/schedule/presentation/screens/doctor_schedule_screen.dart';
import '../features/payment/presentation/screens/payment_screen.dart';
import '../core/security/app_lock_provider.dart';
import '../core/security/app_lock_screen.dart';
import '../core/constants/app_colors.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

class Routes {
  Routes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const patientHome = '/patient/home';
  static const doctorHome = '/doctor/home';
  static const adminHome = '/admin/home';
  static const doctorsList = '/patient/doctors';
  static const editProfile = '/edit-profile';
  static const doctorPatientDetail = '/doctor/patient-detail';
  static const createPrescription = '/doctor/create-prescription';
  static const createMedicalRecord = '/doctor/create-medical-record';
  static const createLabOrder = '/doctor/create-lab-order';
  static const patientInvoices = '/patient/invoices';
  static const patientLabOrders = '/patient/lab-orders';
  static const settings = '/settings';
  static const security = '/security';
  static const changePassword = '/change-password';
  static const lockScreen = '/lock';
  static const recoveryCenter = '/recovery-center';
  static const notifications = '/notifications';
  static const chat = '/chat';
  static const aiAssistant = '/ai-assistant';
  static const teleconsultation = '/teleconsultation';
  static const doctorSchedule = '/doctor/schedule';
  static const payment = '/patient/payment';
  static String bookAppointment(int doctorId) => '/patient/book/$doctorId';
}

// ── Router notifier ───────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
    _ref.listen<AppLockStatus>(appLockProvider,
        (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final lockStatus = _ref.read(appLockProvider);
    final location = state.matchedLocation;

    final isChecking = authState is AuthChecking;
    final isAuthenticated = authState is AuthAuthenticated;

    final isAuthFlow = location == Routes.splash ||
        location == Routes.onboarding ||
        location.startsWith('/role') ||
        location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/forgot');

    // Stay on splash while checking stored token
    if (isChecking) return location == Routes.splash ? null : Routes.splash;

    // Not authenticated → force to auth flow
    if (!isAuthenticated && !isAuthFlow) return Routes.roleSelection;

    // Already authenticated → redirect away from auth screens
    if (authState is AuthAuthenticated && isAuthFlow) {
      return switch (authState.user.role) {
        'doctor' => Routes.doctorHome,
        'admin' => Routes.adminHome,
        _ => Routes.patientHome,
      };
    }

    // App lock: if locked and not already on lock screen → redirect there
    if (isAuthenticated &&
        lockStatus == AppLockStatus.locked &&
        location != Routes.lockScreen) {
      return Routes.lockScreen;
    }

    // If unlocked and on lock screen → go home
    if (authState is AuthAuthenticated &&
        lockStatus == AppLockStatus.unlocked &&
        location == Routes.lockScreen) {
      return switch (authState.user.role) {
        'doctor' => Routes.doctorHome,
        'admin' => Routes.adminHome,
        _ => Routes.patientHome,
      };
    }

    return null;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Auth routes ────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, state) =>
            LoginScreen(role: state.extra as String? ?? 'patient'),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, state) =>
            RegisterScreen(role: state.extra as String? ?? 'patient'),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, state) =>
            ForgotPasswordScreen(role: state.extra as String? ?? 'patient'),
      ),

      // ── Lock screen ────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.lockScreen,
        builder: (context, state) => const AppLockScreen(),
      ),

      // ── App routes (protected) ─────────────────────────────────────────────
      GoRoute(
        path: Routes.patientHome,
        builder: (context, state) => const PatientShellScreen(),
      ),
      GoRoute(
        path: Routes.doctorHome,
        builder: (context, state) => const DoctorShellScreen(),
      ),
      GoRoute(
        path: Routes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: Routes.doctorsList,
        builder: (context, state) => const DoctorsListScreen(),
      ),
      GoRoute(
        path: '/patient/book/:doctorId',
        builder: (_, state) => BookAppointmentScreen(
          doctorId: int.parse(state.pathParameters['doctorId']!),
          doctor: state.extra as DoctorModel?,
        ),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.doctorPatientDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return DoctorPatientDetailScreen(
            patientId: extra['patientId'] as int,
            patientName: extra['patientName'] as String,
            patientPhone: extra['patientPhone'] as String?,
          );
        },
      ),
      GoRoute(
        path: Routes.createPrescription,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreatePrescriptionScreen(
            patientId: extra['patientId'] as int,
            patientName: extra['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: Routes.createMedicalRecord,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreateMedicalRecordScreen(
            patientId: extra['patientId'] as int,
            patientName: extra['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: Routes.createLabOrder,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreateLabOrderScreen(
            patientId: extra['patientId'] as int,
            patientName: extra['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: Routes.patientInvoices,
        builder: (context, _) => const PatientInvoicesScreen(),
      ),
      GoRoute(
        path: Routes.patientLabOrders,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Mes Analyses'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          body: const LabOrdersScreen(),
        ),
      ),

      // ── Settings routes ────────────────────────────────────────────────────
      GoRoute(
        path: Routes.settings,
        builder: (context, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.security,
        builder: (context, _) => const SecurityScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.recoveryCenter,
        builder: (context, _) => const RecoveryCenterScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.chat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatScreen(
            conversation: extra['conversation'] as ConversationModel,
            currentUserId: extra['userId'] as int,
          );
        },
      ),
      GoRoute(
        path: Routes.aiAssistant,
        builder: (context, _) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: Routes.doctorSchedule,
        builder: (context, _) => const DoctorScheduleScreen(),
      ),
      GoRoute(
        path: Routes.payment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentScreen(
            invoiceId: extra['invoiceId'] as int,
            amount: (extra['amount'] as num).toDouble(),
          );
        },
      ),
      GoRoute(
        path: Routes.teleconsultation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TeleconsultationScreen(
            appointmentId: extra['appointmentId'] as int,
            doctorName: extra['doctorName'] as String,
            patientName: extra['patientName'] as String,
            scheduledAt: extra['scheduledAt'] as DateTime,
          );
        },
      ),
    ],
  );
});
