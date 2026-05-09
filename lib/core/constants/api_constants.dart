class ApiConstants {
  ApiConstants._();

  // Change this to your Strapi server URL
  static const String baseUrl = 'http://10.0.2.2:1337/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:1337/api'; // iOS simulator
  // static const String baseUrl = 'https://your-domain.com/api'; // Production

  // Auth endpoints
  static const String login = '/auth/local';
  static const String register = '/auth/medicare-register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/users/me';

  // User endpoints
  static const String users = '/users';
  static const String doctors = '/doctors';
  static const String patients = '/patients';

  // Appointment endpoints
  static const String appointments = '/appointments';

  // Medical record endpoints
  static const String medicalRecords = '/medical-records';
  static const String prescriptions = '/prescriptions';

  // Notification endpoints
  static const String notifications = '/notifications';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String onboardingKey = 'onboarding_completed';
}
