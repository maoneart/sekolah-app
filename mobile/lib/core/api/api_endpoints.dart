class ApiEndpoints {
  // Configured via compile-time dart-define
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.maoneart.my.id/api/v1',
  );

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String me = '/me';

  // Schools & Active context
  static const String schools = '/schools';
  static const String activeSchool = '/active-school';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Students & Classes
  static const String students = '/students';
  static const String classes = '/classes';
  static String classStudents(String classId) => '/classes/$classId/students';
  static String studentDetail(String studentId) => '/students/$studentId';
  static String issueStudentCard(String studentId) => '/students/$studentId/cards/issue';
  static String revokeStudentCard(String cardId) => '/student-cards/$cardId/revoke';

  // Attendance
  static const String attendance = '/attendance';
  static const String attendanceScans = '/attendance/scans';
  static String attendanceSession(String sessionId) => '/attendance/sessions/$sessionId';
  static String sessionRecords(String sessionId) => '/attendance/sessions/$sessionId/records';

  // Timetable
  static const String timetable = '/timetable';

  // Finance / Invoices
  static const String invoices = '/invoices';
  static String invoiceDetail(String invoiceId) => '/invoices/$invoiceId';
  static String invoicePayments(String invoiceId) => '/invoices/$invoiceId/payments';

  // Announcements
  static const String announcements = '/announcements';
  static String readAnnouncement(String id) => '/announcements/$id/read';

  // Reports
  static const String attendanceReport = '/reports/attendance';
  static const String financeReport = '/reports/finance';
}
