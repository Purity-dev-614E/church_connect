class SupabaseConfig {
  // You can also load these from environment variables or a config file
  static const String supabaseUrl = 'https://hubrwunvnuslutyykvli.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1YnJ3dW52bnVzbHV0eXlrdmxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3NjE4MzEsImV4cCI6MjA1NzMzNzgzMX0.GEUOfe5OKzBZY5zT-LlhagykiCMMznxCY5pqTwpLhas';

  // Redirect URLs for password reset
  static const String productionResetUrl =
      'https://safariconnect.org/reset-password-handler';
  static const String developmentResetUrl =
      'http://localhost:3000/reset-password-handler';

  // Get appropriate redirect URL based on environment
  static String get resetRedirectUrl {
    // You can use a flag or environment variable to determine environment
    // For now, checking if we're in debug mode
    bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? productionResetUrl : developmentResetUrl;
  }
}
