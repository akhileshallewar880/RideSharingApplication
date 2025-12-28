import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../shared/widgets/breadcrumb_nav.dart';
import '../../shared/widgets/action_confirmation_modal.dart';
import '../../shared/widgets/enhanced_stat_card.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  String _selectedUserType = 'all'; // all, passenger, driver, admin
  String _selectedStatus = 'all'; // all, active, blocked

  // Mock data - replace with real API calls
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'email': 'akhileshallewar880@gmail.com',
      'phone': '+919876543210',
      'userType': 'admin',
      'isActive': true,
      'isEmailVerified': true,
      'createdAt': '2024-12-15',
      'lastLoginAt': '2024-12-25 09:30',
      'totalBookings': 0,
      'isDriver': false,
    },
    {
      'id': '2',
      'email': 'rajesh.kumar@example.com',
      'phone': '+919876543211',
      'userType': 'driver',
      'isActive': true,
      'isEmailVerified': true,
      'createdAt': '2024-11-20',
      'lastLoginAt': '2024-12-25 08:15',
      'totalBookings': 145,
      'isDriver': true,
      'driverStatus': 'approved',
    },
    {
      'id': '3',
      'email': 'amit.sharma@example.com',
      'phone': '+919876543212',
      'userType': 'passenger',
      'isActive': true,
      'isEmailVerified': true,
      'createdAt': '2024-12-01',
      'lastLoginAt': '2024-12-24 18:45',
      'totalBookings': 12,
      'isDriver': false,
    },
    {
      'id': '4',
      'email': 'blocked.user@example.com',
      'phone': '+919876543213',
      'userType': 'passenger',
      'isActive': false,
      'isEmailVerified': false,
      'createdAt': '2024-10-05',
      'lastLoginAt': '2024-11-10 14:20',
      'totalBookings': 3,
      'isDriver': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _mockUsers;

    // Filter by user type
    if (_selectedUserType != 'all') {
      filtered = filtered.where((u) => u['userType'] == _selectedUserType).toList();
    }

    // Filter by status
    if (_selectedStatus != 'all') {
      final isActive = _selectedStatus == 'active';
      filtered = filtered.where((u) => u['isActive'] == isActive).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        return u['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u['phone'].contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildFiltersAndSearch(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildUsersTable()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbNav(
            items: [
              BreadcrumbItem(label: 'Dashboard', onTap: () {}),
              BreadcrumbItem(label: 'User Management'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage users, drivers, and admin accounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showRegisterDriverDialog,
                icon: const Icon(Icons.local_taxi),
                label: const Text('Register Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateAdminDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Admin User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalUsers = _mockUsers.length;
    final activeUsers = _mockUsers.where((u) => u['isActive']).length;
    final drivers = _mockUsers.where((u) => u['userType'] == 'driver').length;
    final passengers = _mockUsers.where((u) => u['userType'] == 'passenger').length;

    return Row(
      children: [
        Expanded(
          child: EnhancedStatCard(
            title: 'Total Users',
            value: totalUsers.toString(),
            icon: Icons.people,
            iconColor: AdminTheme.primaryColor,
            backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Active Users',
            value: activeUsers.toString(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.1),
            subtitle: '${activeUsers}/$totalUsers active',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Drivers',
            value: drivers.toString(),
            icon: Icons.local_taxi,
            iconColor: AdminTheme.accentColor,
            backgroundColor: AdminTheme.accentColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Passengers',
            value: passengers.toString(),
            icon: Icons.person,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by email or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(width: 16),

          // User Type Filter
          _buildDropdownFilter(
            label: 'User Type',
            value: _selectedUserType,
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Types')),
              DropdownMenuItem(value: 'passenger', child: Text('Passengers')),
              DropdownMenuItem(value: 'driver', child: Text('Drivers')),
              DropdownMenuItem(value: 'admin', child: Text('Admins')),
            ],
            onChanged: (value) {
              setState(() => _selectedUserType = value!);
            },
          ),
          const SizedBox(width: 16),

          // Status Filter
          _buildDropdownFilter(
            label: 'Status',
            value: _selectedStatus,
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: 24,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AdminTheme.textPrimary,
          ),
          dataTextStyle: TextStyle(
            fontSize: 13,
            color: AdminTheme.textPrimary,
          ),
          columns: const [
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Bookings')),
            DataColumn(label: Text('Last Login')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _filteredUsers.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user['email'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (user['isEmailVerified'])
                        Row(
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                DataCell(Text(user['phone'])),
                DataCell(_buildUserTypeBadge(user['userType'])),
                DataCell(_buildStatusBadge(user['isActive'])),
                DataCell(Text(user['totalBookings'].toString())),
                DataCell(Text(user['lastLoginAt'] ?? 'Never')),
                DataCell(_buildActionButtons(user)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserTypeBadge(String type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case 'admin':
        color = Colors.purple;
        icon = Icons.admin_panel_settings;
        break;
      case 'driver':
        color = AdminTheme.accentColor;
        icon = Icons.local_taxi;
        break;
      case 'passenger':
        color = Colors.blue;
        icon = Icons.person;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVE' : 'BLOCKED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          onPressed: () => _viewUserDetails(user),
          tooltip: 'View Details',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            user['isActive'] ? Icons.block : Icons.check_circle,
            size: 18,
            color: user['isActive'] ? Colors.red : Colors.green,
          ),
          onPressed: () => _toggleUserStatus(user),
          tooltip: user['isActive'] ? 'Block User' : 'Unblock User',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (user['userType'] != 'admin') ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteUser(user),
            tooltip: 'Delete User',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    // TODO: Navigate to user detail screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for ${user['email']}')),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final isBlocking = user['isActive'];
    String? blockReason;

    // If blocking, ask for reason
    if (isBlocking) {
      final reasonController = TextEditingController();
      final shouldBlock = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to block ${user['email']}?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for blocking',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'Enter reason (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                blockReason = reasonController.text;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Block User'),
            ),
          ],
        ),
      );

      if (shouldBlock != true) return;
    } else {
      // Unblock confirmation
      final confirmed = await ActionConfirmationModal.show(
        context: context,
        title: 'Unblock User',
        message: 'Are you sure you want to unblock ${user['email']}? They will regain access.',
        confirmText: 'Unblock',
        isDestructive: false,
      );

      if (confirmed != true) return;
    }

    if (mounted) {
      // TODO: Call API to block/unblock user
      // For drivers: PUT api/v1/AdminDriver/{driverId}/block
      // For users: PUT api/v1/AdminUsers/{userId}/block
      setState(() {
        user['isActive'] = !user['isActive'];
        if (isBlocking) {
          user['blockedReason'] = blockReason;
        } else {
          user['blockedReason'] = null;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBlocking ? 'User blocked successfully' : 'User unblocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await ActionConfirmationModal.show(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to delete ${user['email']}? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      // TODO: Call API to delete user
      setState(() {
        _mockUsers.remove(user);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showRegisterDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final licenseController = TextEditingController();
    final addressController = TextEditingController();
    final emergencyContactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_taxi, color: AdminTheme.accentColor),
            const SizedBox(width: 8),
            const Text('Register New Driver'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: '9876543210',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'Min 8 characters',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'License Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: licenseController,
                  decoration: InputDecoration(
                    labelText: 'License Number *',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address (Optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emergencyContactController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact (Optional)',
                    prefixIcon: const Icon(Icons.emergency),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: '9876543210',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Validate required fields
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  passwordController.text.isEmpty ||
                  licenseController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // TODO: Call API to register driver
              // POST api/v1/AdminDriver/register
              
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Driver ${nameController.text} registered successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            label: const Text('Register Driver'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminDialog() {
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Admin User'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call API to create admin user
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Admin user created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
