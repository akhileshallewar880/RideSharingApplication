import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/services/admin_users_service.dart';
import '../../core/services/admin_auth_service.dart';
import '../../shared/widgets/breadcrumb_nav.dart';
import '../../shared/widgets/action_confirmation_modal.dart';
import '../../shared/widgets/enhanced_stat_card.dart';
import 'widgets/driver_registration_dialog.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final AdminAuthService _authService = AdminAuthService();
  late final AdminUsersService _usersService;
  
  String _searchQuery = '';
  String _selectedUserType = 'all'; // all, passenger, driver, admin
  String _selectedStatus = 'all'; // all, active, blocked
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  
  List<Map<String, dynamic>> _users = [];
  int _totalUsers = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usersService = AdminUsersService(_authService);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _usersService.getUsers(
        page: _currentPage,
        limit: _rowsPerPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        userType: _selectedUserType != 'all' ? _selectedUserType : null,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
      );

      if (response['success'] == true) {
        final pagination = response['pagination'] is Map ? (response['pagination'] as Map) : null;
        final int totalCount = (pagination?['totalCount'] as int?) ?? (response['data'] as List?)?.length ?? 0;
        final int totalPages = (pagination?['totalPages'] as int?) ?? ((totalCount + _rowsPerPage - 1) ~/ _rowsPerPage);

        setState(() {
          _users = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _totalUsers = totalCount;
          _totalPages = totalPages;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _totalActiveUsers =>
      _users.where((u) => u['isActive'] == true).length;

  int get _totalDrivers =>
      _users.where((u) => u['userType'] == 'driver' || u['isDriver'] == true).length;

  int get _totalPassengers =>
      _users.where((u) => u['userType'] == 'passenger').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _error != null
                ? _buildErrorWidget()
                : _isLoading && _users.isEmpty
                    ? _buildLoadingWidget()
                    : Padding(
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: AdminTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AdminTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: 16,
              color: AdminTheme.textSecondary,
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
    return Row(
      children: [
        Expanded(
          child: EnhancedStatCard(
            title: 'Total Users',
            value: _totalUsers.toString(),
            icon: Icons.people,
            iconColor: AdminTheme.primaryColor,
            backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Active Users',
            value: _totalActiveUsers.toString(),
            icon: Icons.check_circle,
            iconColor: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.1),
            subtitle: '${_totalActiveUsers}/$_totalUsers active',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Drivers',
            value: _totalDrivers.toString(),
            icon: Icons.local_taxi,
            iconColor: AdminTheme.accentColor,
            backgroundColor: AdminTheme.accentColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedStatCard(
            title: 'Passengers',
            value: _totalPassengers.toString(),
            icon: Icons.person,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
              _loadUsers();
            },
            decoration: InputDecoration(
              hintText: 'Search by email or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: _selectedUserType,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Types')),
              DropdownMenuItem(value: 'passenger', child: Text('Passengers')),
              DropdownMenuItem(value: 'driver', child: Text('Drivers')),
              DropdownMenuItem(value: 'admin', child: Text('Admins')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedUserType = value!;
                _currentPage = 1;
              });
              _loadUsers();
            },
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: _selectedStatus,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
                _currentPage = 1;
              });
              _loadUsers();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    if (_users.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 18,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
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
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Rides')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _users.map((user) {
                          final name = (user['name'] ?? '').toString().trim();
                          final email = (user['email'] ?? '').toString().trim();
                          final rideCount = user['rideCount'];

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  name.isNotEmpty ? name : (email.isNotEmpty ? email : (user['phone'] ?? 'N/A').toString()),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              DataCell(Text(user['phone'] ?? 'N/A')),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      email.isNotEmpty ? email : 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    if (user['isEmailVerified'] == true)
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
                              DataCell(_buildUserTypeBadge(user['userType'] ?? 'passenger')),
                              DataCell(Text(rideCount == null ? '0' : rideCount.toString())),
                              DataCell(_buildStatusBadge(user['isActive'] ?? false)),
                              DataCell(Text(_formatDate(user['createdAt']))),
                              DataCell(_buildActionButtons(user)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage - 1) * _rowsPerPage + 1} to ${_currentPage * _rowsPerPage > _totalUsers ? _totalUsers : _currentPage * _rowsPerPage} of $_totalUsers users',
            style: TextStyle(
              fontSize: 14,
              color: AdminTheme.textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadUsers();
                      }
                    : null,
              ),
              ...List.generate(
                _totalPages > 5 ? 5 : _totalPages,
                (index) {
                  int pageNum;
                  if (_totalPages <= 5) {
                    pageNum = index + 1;
                  } else if (_currentPage <= 3) {
                    pageNum = index + 1;
                  } else if (_currentPage >= _totalPages - 2) {
                    pageNum = _totalPages - 4 + index;
                  } else {
                    pageNum = _currentPage - 2 + index;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextButton(
                      onPressed: () {
                        setState(() => _currentPage = pageNum);
                        _loadUsers();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _currentPage == pageNum
                            ? AdminTheme.primaryColor
                            : Colors.transparent,
                        foregroundColor: _currentPage == pageNum
                            ? Colors.white
                            : AdminTheme.textPrimary,
                        minimumSize: const Size(40, 40),
                      ),
                      child: Text('$pageNum'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadUsers();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildUserTypeBadge(String type) {
    Color color;
    IconData icon;
    
    switch (type.toLowerCase()) {
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
          Icon(
            isActive ? Icons.check_circle : Icons.block,
            size: 12,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Phone', user['phone']),
              _buildDetailRow('Type', user['userType']),
              _buildDetailRow('Status', user['isActive'] ? 'Active' : 'Blocked'),
              _buildDetailRow('Email Verified', user['isEmailVerified'] ? 'Yes' : 'No'),
              _buildDetailRow('Created', _formatDate(user['createdAt'])),
              if (user['lastLoginAt'] != null)
                _buildDetailRow('Last Login', _formatDate(user['lastLoginAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AdminTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
          ),
        ],
      ),
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AdminTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(isBlocking ? 'Blocking user...' : 'Unblocking user...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await _usersService.blockUser(
          userId: user['id'],
          block: isBlocking,
          reason: blockReason,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBlocking ? 'User blocked successfully' : 'User unblocked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Reload users
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AdminTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text('Deleting user...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await _usersService.deleteUser(user['id']);

        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Reload users
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showRegisterDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => DriverRegistrationDialog(
        onRegistered: _loadUsers,
      ),
    );
  }

  void _showCreateAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'admin';

    bool sendingOtp = false;
    bool verifyingOtp = false;
    bool otpSent = false;
    bool otpVerified = false;
    String? otpId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Admin User'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        otpVerified
                            ? 'Mobile verified'
                            : (otpSent ? 'OTP sent. Enter OTP to verify.' : 'Verify phone with OTP'),
                        style: TextStyle(
                          color: otpVerified ? Colors.green : AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: sendingOtp || otpVerified
                          ? null
                          : () async {
                              final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
                              if (phone.length != 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid 10-digit phone number'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                sendingOtp = true;
                                otpSent = false;
                                otpVerified = false;
                                otpId = null;
                                otpController.text = '';
                              });

                              try {
                                final result = await _usersService.sendOtp(phoneNumber: phone);
                                if (result['isExistingUser'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This phone number is already registered. Use a new number.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final id = result['otpId']?.toString();
                                if (id == null || id.isEmpty) {
                                  throw Exception('OTP ID missing');
                                }

                                setState(() {
                                  otpId = id;
                                  otpSent = true;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP sent successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send OTP: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() => sendingOtp = false);
                              }
                            },
                      child: sendingOtp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send OTP'),
                    ),
                  ],
                ),
                if (otpSent && !otpVerified) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'OTP *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: verifyingOtp
                            ? null
                            : () async {
                                final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
                                final otp = otpController.text.trim();
                                if (otpId == null || otpId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please send OTP first'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (!RegExp(r'^\d{4}$').hasMatch(otp)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid 4-digit OTP'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => verifyingOtp = true);
                                try {
                                  final verify = await _usersService.verifyOtp(
                                    phoneNumber: phone,
                                    otp: otp,
                                    otpId: otpId!,
                                  );
                                  if (verify['isNewUser'] != true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('This phone number is already registered. Use a new number.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => otpVerified = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mobile number verified'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('OTP verification failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  setState(() => verifyingOtp = false);
                                }
                              },
                        child: verifyingOtp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify'),
                      ),
                    ],
                  ),
                ],
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
                    setState(() => selectedRole = value!);
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
              onPressed: () async {
                final phoneDigits = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email and password are required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (phoneDigits.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number is required (10 digits)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!otpVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please verify mobile number with OTP'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context); // Close dialog

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AdminTheme.primaryColor),
                            const SizedBox(height: 16),
                            const Text('Creating admin user...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  await _usersService.createAdminUser(
                    name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    phone: phoneDigits,
                    role: selectedRole,
                    phoneVerified: true,
                  );

                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin user created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUsers(); // Reload users
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
