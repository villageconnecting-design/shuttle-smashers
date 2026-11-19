/// App-wide constants for Shuttle Smashers
class AppConstants {
  // App info
  static const String appName = 'Shuttle Smashers';
  static const String appVersion = '1.0.0';

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 50.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Match types
  static const String matchTypeSingles = 'Singles';
  static const String matchTypeDoubles = 'Doubles';
  static const String matchTypeMixedDoubles = 'Mixed Doubles';

  // Match points
  static const int matchPointsToWin = 21;
  static const int matchMinimumLead = 2;
  static const int matchMaxPoints = 30;
}
