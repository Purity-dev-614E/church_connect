import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Manages local storage of regional leadership aliases (e.g., Regional Coordinator).
class RegionalAliasService {
  static const String _storageKey = 'regional_role_aliases';

  Future<Map<String, String>> _readAliases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAliases(Map<String, String> aliases) async {
    final prefs = await SharedPreferences.getInstance();
    if (aliases.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, jsonEncode(aliases));
    }
  }

  /// Saves or updates an alias. Passing `null` or empty removes the alias.
  Future<void> setAlias(String userId, String? alias) async {
    final trimmed = alias?.trim();
    final aliases = await _readAliases();

    if (trimmed == null || trimmed.isEmpty) {
      aliases.remove(userId);
    } else {
      aliases[userId] = trimmed;
    }

    await _writeAliases(aliases);
  }

  Future<String?> getAlias(String userId) async {
    final aliases = await _readAliases();
    return aliases[userId];
  }

  Future<Map<String, String>> getAllAliases() => _readAliases();

  Future<void> clearAlias(String userId) => setAlias(userId, null);
}

