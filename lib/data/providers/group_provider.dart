import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import '../../data/services/group_services.dart';

class GroupProvider extends ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final GroupServices _groupService = GroupServices();

  // Helper method to handle loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper method to handle errors
  void _handleError(String operation, dynamic error) {
    _errorMessage = 'Error $operation: $error';
    debugPrint(_errorMessage);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    _setLoading(true);
    try {
      _groups = await _groupService.fetchAllGroups();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching groups', error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createGroup(GroupModel group) async {
    _setLoading(true);
    try {
      await _groupService.createGroup(group.name);
      await fetchGroups();
      _errorMessage = null;
    } catch (error) {
      _handleError('creating group', error);
      _setLoading(false); // Need to set loading to false here since fetchGroups won't be called
    }
  }

  Future<void> updateGroup(String groupId, GroupModel updatedGroup) async {
    _setLoading(true);
    try {
      await _groupService.updateGroup(groupId, updatedGroup.name);
      await fetchGroups();
      _errorMessage = null;
    } catch (error) {
      _handleError('updating group', error);
      _setLoading(false);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _setLoading(true);
    try {
      await _groupService.deleteGroup(groupId);
      await fetchGroups();
      _errorMessage = null;
    } catch (error) {
      _handleError('deleting group', error);
      _setLoading(false);
    }
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      return await _groupService.fetchGroupById(groupId);
    } catch (error) {
      _handleError('getting group by ID', error);
      return null;
    }
  }

  Future<List<dynamic>> getGroupMembers(String groupId) async {
    try {
      return await _groupService.fetchGroupMembers(groupId);
    } catch (error) {
      _handleError('fetching group members', error);
      return [];
    }
  }

  Future<bool> assignAdminToGroup(String groupId, String userId) async {
    try {
      return await _groupService.assignAdminToGroup(groupId, userId);
    } catch (error) {
      _handleError('assigning admin to group', error);
      return false;
    }
  }

  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      return await _groupService.addMemberToGroup(groupId, userId);
    } catch (error) {
      _handleError('adding member to group', error);
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      return await _groupService.removeMemberFromGroup(groupId, userId);
    } catch (error) {
      _handleError('removing member from group', error);
      return false;
    }
  }

  Future<List<GroupModel>> getGroupsByAdmin(String adminId) async {
    try {
      return await _groupService.getGroupsByAdmin(adminId);
    } catch (error) {
      _handleError('getting groups by admin', error);
      return [];
    }
  }

  Future<Map<String, dynamic>> getGroupDemographics(String groupId) async {
    try {
      return await _groupService.getGroupDemographics(groupId);
    } catch (error) {
      _handleError('getting group demographics', error);
      return {};
    }
  }
  
  Future<List<GroupModel>> getUserGroups(String userId) async {
    _setLoading(true);
    try {
      final userGroups = await _groupService.getUserGroups(userId);
      _errorMessage = null;
      _setLoading(false);
      return userGroups;
    } catch (error) {
      _handleError('getting user groups', error);
      _setLoading(false);
      return [];
    }
  }
  
  // Fetch groups where user is a member (alternative implementation if needed)
  Future<List<GroupModel>> fetchUserMemberships(String userId) async {
    _setLoading(true);
    try {
      final userGroups = await _groupService.getUserGroups(userId);
      _errorMessage = null;
      _setLoading(false);
      return userGroups;
    } catch (error) {
      _handleError('fetching user memberships', error);
      _setLoading(false);
      return [];
    }
  }
}