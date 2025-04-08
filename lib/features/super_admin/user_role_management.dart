import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserRoleManagementScreen> createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];
  
  // Available roles
  final List<String> _availableRoles = ['user', 'admin', 'super_admin'];

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getAllUsers();
      
      setState(() {
        _users = List<UserModel>.from(users);
        _filteredUsers = List<UserModel>.from(users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load users: ${e.toString()}';
      });
    }
  }
  
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List<UserModel>.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 user.email.toLowerCase().contains(query.toLowerCase()) ||
                 user.role.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  Future<void> _updateUserRole(UserModel user, String newRole) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Create updated user model
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        contact: user.contact,
        nextOfKin: user.nextOfKin,
        nextOfKinContact: user.nextOfKinContact,
        role: newRole,
        gender: user.gender,
      );
      
      // Update user role
      await userProvider.updateUser(updatedUser);
      
      // Refresh user list
      await _loadUsers();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName}\'s role updated to $newRole'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Role Management',
        showBackButton: true,
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildUserList(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorColor,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyles.heading2.copyWith(
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyles.bodyText,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Retry',
            onPressed: _loadUsers,
            color: AppColors.primaryColor,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _filterUsers,
          ),
        ),
        
        // User count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Users: ${_users.length}',
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // User list
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildUserCard(UserModel user) {
    // Determine role color
    Color roleColor;
    switch (user.role.toLowerCase()) {
      case 'super_admin':
        roleColor = Colors.red;
        break;
      case 'admin':
        roleColor = Colors.orange;
        break;
      case 'user':
      default:
        roleColor = Colors.green;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar or initials
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 24,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyles.heading2.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Current role chip
                Chip(
                  label: Text(
                    user.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: roleColor,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Role selection
            Row(
              children: [
                const Text(
                  'Change Role:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableRoles.map((role) {
                        final isCurrentRole = role.toLowerCase() == user.role.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(role),
                            backgroundColor: isCurrentRole
                                ? AppColors.primaryColor
                                : Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isCurrentRole ? Colors.white : Colors.black,
                              fontWeight: isCurrentRole ? FontWeight.bold : FontWeight.normal,
                            ),
                            onPressed: isCurrentRole
                                ? null
                                : () => _showRoleChangeConfirmation(user, role),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRoleChangeConfirmation(UserModel user, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text(
          'Are you sure you want to change ${user.fullName}\'s role from ${user.role} to $newRole?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserRole(user, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}