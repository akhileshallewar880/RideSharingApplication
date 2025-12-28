import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_models.dart';
import '../../core/providers/driver_provider.dart';
import '../../core/theme/admin_theme.dart';
import 'driver_verification_detail_screen.dart';

class DriverVerificationListScreen extends ConsumerStatefulWidget {
  const DriverVerificationListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DriverVerificationListScreen> createState() =>
      _DriverVerificationListScreenState();
}

class _DriverVerificationListScreenState
    extends ConsumerState<DriverVerificationListScreen> {
  String _selectedStatus = 'pending';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDrivers() {
    ref.read(pendingDriversProvider.notifier).loadDrivers(
          status: _selectedStatus == 'all' ? null : _selectedStatus,
          searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(pendingDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Verification'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDrivers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Search
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: Text('All'),
                            selected: _selectedStatus == 'all',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = 'all');
                                _loadDrivers();
                              }
                            },
                          ),
                          FilterChip(
                            label: Text('Pending'),
                            selected: _selectedStatus == 'pending',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = 'pending');
                                _loadDrivers();
                              }
                            },
                          ),
                          FilterChip(
                            label: Text('Approved'),
                            selected: _selectedStatus == 'approved',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = 'approved');
                                _loadDrivers();
                              }
                            },
                          ),
                          FilterChip(
                            label: Text('Rejected'),
                            selected: _selectedStatus == 'rejected',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStatus = 'rejected');
                                _loadDrivers();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or vehicle number...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadDrivers();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadDrivers(),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Drivers List
          Expanded(
            child: driversState.isLoading && driversState.drivers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : driversState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: AdminTheme.errorColor),
                            SizedBox(height: 16),
                            Text(
                              driversState.error!,
                              style: TextStyle(color: AdminTheme.errorColor),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDrivers,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : driversState.drivers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 64, color: AdminTheme.textSecondary),
                                SizedBox(height: 16),
                                Text(
                                  'No drivers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AdminTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 800) {
                                return _buildDataTable(driversState.drivers);
                              } else {
                                return _buildListView(driversState.drivers);
                              }
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<PendingDriver> drivers) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Vehicle')),
              DataColumn(label: Text('City')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Registered')),
              DataColumn(label: Text('Actions')),
            ],
            rows: drivers.map((driver) {
              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          driver.fullName,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          driver.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(driver.phone)),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          driver.vehicleNumber,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          driver.vehicleType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(driver.city)),
                  DataCell(_buildStatusChip(driver.verificationStatus)),
                  DataCell(Text(
                    DateFormat('dd MMM yyyy').format(driver.registeredAt),
                  )),
                  DataCell(
                    ElevatedButton.icon(
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('Review'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DriverVerificationDetailScreen(driver: driver),
                          ),
                        ).then((_) => _loadDrivers());
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<PendingDriver> drivers) {
    return ListView.builder(
      itemCount: drivers.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DriverVerificationDetailScreen(driver: driver),
                ),
              ).then((_) => _loadDrivers());
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              driver.phone,
                              style: TextStyle(
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(driver.verificationStatus),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          Icons.directions_car,
                          driver.vehicleNumber,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          Icons.location_city,
                          driver.city,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Registered: ${DateFormat('dd MMM yyyy').format(driver.registeredAt)}',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: AdminTheme.getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.textSecondary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
