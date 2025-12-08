/// App Constants
/// 
/// Defines application-wide constants.

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Enterprise Mobile';
  static const String appVersion = '1.0.0';

  // API & Firebase
  static const String baseUrl = 'https://api.example.com';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheDuration = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);

  // GPS Settings
  static const double defaultLatitude = 21.0285;  // Hanoi
  static const double defaultLongitude = 105.8542;
  static const double attendanceRadius = 500; // meters

  // File Upload
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedDocTypes = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
}
