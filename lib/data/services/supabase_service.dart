import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  /// Get the Supabase client instance
  /// Initializes if not already initialized
  static SupabaseClient get client {
    if (_client == null) {
      _client = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );
    }
    return _client!;
  }

  /// Initialize Supabase (call this in main.dart before runApp)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
}

