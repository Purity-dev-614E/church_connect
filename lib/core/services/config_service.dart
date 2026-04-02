import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ConfigService {
  static const String _configPath = 'config/app_config.json';

  static ConfigService? _instance;
  static ConfigService get instance {
    _instance ??= ConfigService._();
    return _instance!;
  }

  ConfigService._();

  Map<String, dynamic>? _config;
  String? _currentEnvironment;

  Future<void> initialize() async {
    try {
      // Load config file
      final String configString = await rootBundle.loadString(_configPath);
      _config = json.decode(configString);

      // Set environment directly - no SharedPreferences confusion
      _currentEnvironment = 'development'; // Change this manually when needed
    } catch (e) {
      _config = {
        'development': {
          'frontend_port': 3000,
          'api_url': 'https://safari-backend-fgl3.onrender.com/api',
        },
      };
      _currentEnvironment = 'development';
    }
  }

  Future<void> setEnvironment(String environment) async {
    if (_config == null || !_config!.containsKey(environment)) {
      throw Exception('Environment $environment not found in config');
    }

    // Set environment directly - no SharedPreferences needed
    _currentEnvironment = environment;
  }

  String get currentEnvironment => _currentEnvironment ?? 'development';

  Future<int> getFrontendPort() async {
    if (_config == null) await initialize();

    // Return default frontend port for current environment
    return _config![currentEnvironment]['frontend_port'] as int;
  }

  Future<void> setFrontendPort(int port) async {
    // This method is now simplified - no SharedPreferences storage
  }

  Future<String> getApiUrl() async {
    if (_config == null) await initialize();

    String apiUrl = _config![currentEnvironment]['api_url'] as String;

    // In production web environment, handle relative URLs
    if (currentEnvironment == 'production' &&
        kIsWeb &&
        apiUrl.startsWith('/')) {
      return apiUrl;
    }

    return apiUrl;
  }

  Future<String> getFrontendBaseUrl() async {
    final port = await getFrontendPort();

    // For web development, use localhost with specified port
    if (port != null && port > 0) {
      return 'http://localhost:$port';
    } else {
      // For production, return empty (relative URLs)
      return '';
    }
  }

  Future<String> getWebDomain() async {
    if (_config == null) await initialize();

    if (currentEnvironment == 'production') {
      return _config![currentEnvironment]['web_domain'] as String;
    }

    // For non-production, use frontend base URL
    return await getFrontendBaseUrl();
  }

  // Supabase Configuration
  Future<String> getSupabaseUrl() async {
    if (_config == null) await initialize();
    return _config![currentEnvironment]['supabase_url'] as String;
  }

  Future<String> getSupabaseAnonKey() async {
    if (_config == null) await initialize();
    return _config![currentEnvironment]['supabase_anon_key'] as String;
  }

  Future<String> getSupabaseServiceRoleKey() async {
    if (_config == null) await initialize();
    return _config![currentEnvironment]['supabase_service_role_key'] as String;
  }

  Future<String> getPasswordResetUrl(String token) async {
    final baseUrl = await getFrontendBaseUrl();

    // In production, use the web domain from config instead of relative path
    if (currentEnvironment == 'production' && baseUrl.isEmpty) {
      final webDomain = _config![currentEnvironment]['web_domain'] as String;
      return '$webDomain/reset-password?token=$token';
    }

    return '$baseUrl/reset-password?token=$token';
  }

  Future<String> getFullUrl(String endpoint) async {
    final apiUrl = await getApiUrl();
    return '$apiUrl$endpoint';
  }

  Map<String, dynamic> getEnvironmentConfig(String environment) {
    if (_config == null) {
      throw Exception('Config not initialized. Call initialize() first.');
    }

    if (!_config!.containsKey(environment)) {
      throw Exception('Environment $environment not found in config');
    }

    return _config![environment] as Map<String, dynamic>;
  }

  List<String> getAvailableEnvironments() {
    if (_config == null) {
      throw Exception('Config not initialized. Call initialize() first.');
    }

    return _config!.keys.cast<String>().toList();
  }
}
