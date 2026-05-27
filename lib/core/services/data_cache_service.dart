import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';

class DataCacheService {
  static const String _usersKey = 'cached_users';
  static const String _groupsKey = 'cached_groups';
  static const String _eventsKey = 'cached_events';
  static const String _lastUpdateKey = 'last_data_update';
  static const String _currentUserKey = 'current_user_data';

  // Cache duration in milliseconds (30 minutes)
  static const int _cacheDuration = 30 * 60 * 1000;

  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  // Check if cache is still valid
  Future<bool> _isCacheValid() async {
    await _ensureInitialized();
    final lastUpdate = _prefs?.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) < _cacheDuration;
  }

  // Cache users data
  Future<void> cacheUsers(List<UserModel> users) async {
    await _ensureInitialized();
    try {
      final usersJson = users.map((user) => user.toJson()).toList();
      await _prefs?.setString(_usersKey, json.encode(usersJson));
      await _updateTimestamp();
      print('Cached ${users.length} users');
    } catch (e) {
      print('Error caching users: $e');
    }
  }

  // Get cached users
  Future<List<UserModel>> getCachedUsers() async {
    await _ensureInitialized();
    try {
      if (!await _isCacheValid()) {
        return [];
      }
      final usersJson = _prefs?.getString(_usersKey);
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.map((userJson) => UserModel.fromJson(userJson)).toList();
      }
    } catch (e) {
      print('Error getting cached users: $e');
    }
    return [];
  }

  // Cache groups data
  Future<void> cacheGroups(List<GroupModel> groups) async {
    await _ensureInitialized();
    try {
      final groupsJson = groups.map((group) => group.toJson()).toList();
      await _prefs?.setString(_groupsKey, json.encode(groupsJson));
      await _updateTimestamp();
      print('Cached ${groups.length} groups');
    } catch (e) {
      print('Error caching groups: $e');
    }
  }

  // Get cached groups
  Future<List<GroupModel>> getCachedGroups() async {
    await _ensureInitialized();
    try {
      if (!await _isCacheValid()) {
        return [];
      }
      final groupsJson = _prefs?.getString(_groupsKey);
      if (groupsJson != null) {
        final List<dynamic> groupsList = json.decode(groupsJson);
        return groupsList.map((groupJson) => GroupModel.fromJson(groupJson)).toList();
      }
    } catch (e) {
      print('Error getting cached groups: $e');
    }
    return [];
  }

  // Cache events data
  Future<void> cacheEvents(List<EventModel> events) async {
    await _ensureInitialized();
    try {
      final eventsJson = events.map((event) => event.toJson()).toList();
      await _prefs?.setString(_eventsKey, json.encode(eventsJson));
      await _updateTimestamp();
      print('Cached ${events.length} events');
    } catch (e) {
      print('Error caching events: $e');
    }
  }

  // Get cached events
  Future<List<EventModel>> getCachedEvents() async {
    await _ensureInitialized();
    try {
      if (!await _isCacheValid()) {
        return [];
      }
      final eventsJson = _prefs?.getString(_eventsKey);
      if (eventsJson != null) {
        final List<dynamic> eventsList = json.decode(eventsJson);
        return eventsList.map((eventJson) => EventModel.fromJson(eventJson)).toList();
      }
    } catch (e) {
      print('Error getting cached events: $e');
    }
    return [];
  }

  // Cache current user data
  Future<void> cacheCurrentUser(UserModel user) async {
    await _ensureInitialized();
    try {
      await _prefs?.setString(_currentUserKey, json.encode(user.toJson()));
      print('Cached current user: ${user.fullName}');
    } catch (e) {
      print('Error caching current user: $e');
    }
  }

  // Get cached current user
  Future<UserModel?> getCachedCurrentUser() async {
    await _ensureInitialized();
    try {
      final userJson = _prefs?.getString(_currentUserKey);
      if (userJson != null) {
        return UserModel.fromJson(json.decode(userJson));
      }
    } catch (e) {
      print('Error getting cached current user: $e');
    }
    return null;
  }

  // Update cache timestamp
  Future<void> _updateTimestamp() async {
    await _ensureInitialized();
    await _prefs?.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Clear all cache
  Future<void> clearCache() async {
    await _ensureInitialized();
    try {
      await _prefs?.remove(_usersKey);
      await _prefs?.remove(_groupsKey);
      await _prefs?.remove(_eventsKey);
      await _prefs?.remove(_lastUpdateKey);
      // Don't remove current user data on logout
      print('Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Clear current user cache (for logout)
  Future<void> clearCurrentUserCache() async {
    await _ensureInitialized();
    try {
      await _prefs?.remove(_currentUserKey);
      print('Current user cache cleared');
    } catch (e) {
      print('Error clearing current user cache: $e');
    }
  }

  // Check if any cached data exists
  Future<bool> hasCachedData() async {
    await _ensureInitialized();
    return await _isCacheValid();
  }
}
