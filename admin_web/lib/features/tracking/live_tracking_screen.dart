import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../shared/widgets/breadcrumb_nav.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  String _selectedFilter = 'all'; // all, active, available, offline
  String _searchQuery = '';

  // Mock data - replace with SignalR real-time updates
  final List<Map<String, dynamic>> _mockDrivers = [
    {
      'id': '1',
      'name': 'Rajesh Kumar',
      'phone': '+919876543210',
      'status': 'active', // active, available, offline
      'lat': 20.7514,
      'lng': 80.2462,
      'vehicle': 'MH 31 AB 1234',
      'currentRide': 'Allapalli to Gadchiroli',
      'passengers': 3,
      'totalSeats': 5,
    },
    {
      'id': '2',
      'name': 'Amit Sharma',
      'phone': '+919876543211',
      'status': 'available',
      'lat': 20.7614,
      'lng': 80.2562,
      'vehicle': 'MH 31 CD 5678',
      'currentRide': null,
      'passengers': 0,
      'totalSeats': 5,
    },
    {
      'id': '3',
      'name': 'Suresh Patil',
      'phone': '+919876543212',
      'status': 'offline',
      'lat': 20.7414,
      'lng': 80.2362,
      'vehicle': 'MH 31 EF 9012',
      'currentRide': null,
      'passengers': 0,
      'totalSeats': 7,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  List<Map<String, dynamic>> get _filteredDrivers {
    var filtered = _mockDrivers;

    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((d) => d['status'] == _selectedFilter).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) {
        return d['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d['phone'].contains(_searchQuery) ||
            d['vehicle'].toLowerCase().contains(_searchQuery.toLowerCase());
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
          // Header with breadcrumbs
          _buildHeader(),

          // Content
          Expanded(
            child: Row(
              children: [
                // Map View (70%)
                Expanded(
                  flex: 7,
                  child: _buildMapView(),
                ),

                // Driver List Sidebar (30%)
                Expanded(
                  flex: 3,
                  child: _buildDriverSidebar(),
                ),
              ],
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
              BreadcrumbItem(label: 'Live Tracking'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time driver and vehicle tracking',
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Quick Stats
              _buildQuickStat(
                'Active Rides',
                _mockDrivers.where((d) => d['status'] == 'active').length.toString(),
                Colors.green,
                Icons.directions_car,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                'Available',
                _mockDrivers.where((d) => d['status'] == 'available').length.toString(),
                AdminTheme.accentColor,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                'Offline',
                _mockDrivers.where((d) => d['status'] == 'offline').length.toString(),
                Colors.red,
                Icons.offline_bolt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Google Maps Integration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Map will display here when Google Maps API is configured',
                style: TextStyle(
                  fontSize: 14,
                  color: AdminTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_filteredDrivers.length} drivers in selected area',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSidebar() {
    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
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
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search drivers, vehicles...',
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
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Active', 'active'),
                    _buildFilterChip('Available', 'available'),
                    _buildFilterChip('Offline', 'offline'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Driver List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDrivers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final driver = _filteredDrivers[index];
                return _buildDriverCard(driver);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AdminTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AdminTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AdminTheme.primaryColor : AdminTheme.textSecondary,
        fontSize: 13,
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final statusColor = driver['status'] == 'active'
        ? Colors.green
        : driver['status'] == 'available'
            ? AdminTheme.accentColor
            : Colors.red;

    return InkWell(
      onTap: () {
        // TODO: Zoom to driver location on map when Google Maps is integrated
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${driver['name']} location')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Name and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driver['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vehicle Number
            Row(
              children: [
                Icon(Icons.local_taxi, size: 14, color: AdminTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  driver['vehicle'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Current Ride (if active)
            if (driver['currentRide'] != null) ...[
              Row(
                children: [
                  Icon(Icons.route, size: 14, color: AdminTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      driver['currentRide'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: AdminTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${driver['passengers']}/${driver['totalSeats']} passengers',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
