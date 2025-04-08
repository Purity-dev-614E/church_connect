import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/features/super_admin/user_role_management.dart';
import 'package:provider/provider.dart';

class UserManagementTab extends StatefulWidget {
  @override
  _UserManagementTabState createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  
  // State for search and filtering
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getAllUsers();
      
      if (mounted) {
        setState(() {
          _users = List<UserModel>.from(users);
          _filterUsers(); // Apply any existing filters
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredUsers = _users.where((user) {
        // Filter by search query
        final matchesQuery = query.isEmpty || 
            user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
            
        // Filter by role
        final matchesRole = _selectedRole == 'All' || 
            (_selectedRole == 'Members' && user.role.toLowerCase() == 'user') ||
            (_selectedRole == 'Group Leaders' && user.role.toLowerCase() == 'admin') ||
            (_selectedRole == 'Admins' && user.role.toLowerCase() == 'super_admin');
            
        return matchesQuery && matchesRole;
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _filterUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to user creation screen or show dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add user functionality will be implemented here')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserRoleManagementScreen()),
                  ).then((_) {
                    // Refresh the user list when returning from role management
                    _loadUsers();
                  });
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Manage Roles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('Filter by:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Members', child: Text('Members')),
                  DropdownMenuItem(value: 'Group Leaders', child: Text('Group Leaders')),
                  DropdownMenuItem(value: 'Admins', child: Text('Admins')),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                    _filterUsers();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(
                  child: Text('No users found matching the criteria'),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserListItem(user);
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildUserListItem(UserModel user) {
    // Get role display name
    String roleDisplay = 'Unknown';
    Color roleColor = Colors.grey;
    
    switch (user.role.toLowerCase()) {
      case 'super_admin':
        roleDisplay = 'Super Admin';
        roleColor = AppColors.primaryColor;
        break;
      case 'admin':
        roleDisplay = 'Group Leader';
        roleColor = AppColors.secondaryColor;
        break;
      case 'user':
        roleDisplay = 'Member';
        roleColor = AppColors.accentColor;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyles.heading2.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withOpacity(0.3)),
              ),
              child: Text(
                roleDisplay,
                style: TextStyles.bodyText.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.secondaryColor),
              onPressed: () {
                // Edit user functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit user: ${user.fullName}')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete user functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete user: ${user.fullName}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}