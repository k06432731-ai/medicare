import '../config/env_config.dart';

class ApiConstants {
  ApiConstants._();

  // URL configurée via --dart-define=API_URL=... (voir EnvConfig)
  static String get baseUrl => EnvConfig.apiUrl;

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String login = '/auth/local';
  static const String register = '/auth/medicare-register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String me = '/users/me';

  // ── Users ────────────────────────────────────────────────────────────────
  static const String users = '/users';
  static const String doctors = '/users';   // filtrés par appRole=doctor
  static const String patients = '/users';  // filtrés par appRole=patient

  // ── Appointments ─────────────────────────────────────────────────────────
  static const String appointments = '/appointments';

  // ── Medical records ──────────────────────────────────────────────────────
  static const String medicalRecords = '/medical-records';
  static const String prescriptions = '/prescriptions';

  // ── Invoices ─────────────────────────────────────────────────────────────
  static const String invoices = '/invoices';

  // ── Lab orders & laboratories ─────────────────────────────────────────────
  static const String labOrders = '/lab-orders';
  static const String laboratories = '/laboratories';

  // ── Payment ──────────────────────────────────────────────────────────────
  static const String payments = '/payments';
  static const String paymentEngineInit = '/payment-engine/init';
  static const String paymentEngineVerify = '/payment-engine/verify';
  static const String paymentEngineStatus = '/payment-engine/status';
  static const String paymentEngineCallback = '/payment-engine/callback';

  // ── Stripe ───────────────────────────────────────────────────────────────
  static const String stripeCreateIntent = '/stripe-engine/create-intent';
  static const String stripeConfirm = '/stripe-engine/confirm';
  static const String stripeWebhook = '/stripe-engine/webhook';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationMy = '/notification-engine/my-notifications';
  static const String notificationUnreadCount = '/notification-engine/unread-count';
  static const String notificationMarkRead = '/notification-engine/mark-read';
  static const String notificationMarkAllRead = '/notification-engine/mark-all-read';

  // ── Messaging ─────────────────────────────────────────────────────────────
  static const String messagingConversations = '/messaging-engine/conversations';
  static const String messagingFindOrCreate = '/messaging-engine/find-or-create';
  static const String messagingMessages = '/messaging-engine/messages';
  static const String messagingSend = '/messaging-engine/send';
  static const String messagingMarkRead = '/messaging-engine/mark-read';

  // ── Recovery ─────────────────────────────────────────────────────────────
  static const String recoveryStats = '/recovery-engine/stats';
  static const String recoveryCases = '/recovery-engine/active-cases';
  static const String recoveryRunDetection = '/recovery-engine/run-detection';
  static const String recoveryStaffTasks = '/recovery-engine/staff-tasks';
  static const String recoveryRiskScores = '/recovery-engine/risk-scores';
  static const String recoveryDoctorView = '/recovery-engine/doctor-view';
  static const String recoveryPatientRisk = '/recovery-engine/patient-risk';

  // ── Schedule ─────────────────────────────────────────────────────────────
  static const String scheduleAvailability = '/schedule-engine/availability';
  static const String scheduleBlocks = '/schedule-engine/blocks';
  static const String scheduleAvailabilityPublic = '/schedule-engine/public-availability';

  // ── AI ────────────────────────────────────────────────────────────────────
  static const String aiAssistantChat = '/ai-assistant/chat';
  static const String aiDoctorTriage = '/ai-doctor/triage';
  // Doctor-facing AI tools
  static const String aiDoctorPatientSummary = '/ai-doctor/summarize-patient';
  static const String aiDoctorPrescriptionDraft = '/ai-doctor/prescription-draft';
  static const String aiDoctorDiagnosticSuggestions = '/ai-doctor/diagnostic-suggestions';
  // Legacy alias kept for reference
  static const String aiDoctorPrescriptionHelper = '/ai-doctor/prescription-helper';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminStats = '/admin-stats';

  // ── Upload ────────────────────────────────────────────────────────────────
  static const String upload = '/upload';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ── Storage keys ─────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String onboardingKey = 'onboarding_completed';
}
