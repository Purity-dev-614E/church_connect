/// Central place for deploy-time feature flags.
///
/// Toggle these values and redeploy to change behavior.
class AppFlags {
  /// When true, the entire app is replaced with an "Under Maintenance" screen.
  static const bool maintenanceMode = false;

  static const String maintenanceMessage =
      'Safari Connect is temporarily unavailable while we perform maintenance.\n\nPlease try again shortly.';
}

