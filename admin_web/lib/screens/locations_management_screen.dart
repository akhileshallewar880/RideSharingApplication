import 'package:flutter/material.dart';
import '../models/admin_location_models.dart';
import '../services/location_service.dart';

class LocationsManagementScreen extends StatefulWidget {
  const LocationsManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationsManagementScreen> createState() => _LocationsManagementScreenState();
}

class _LocationsManagementScreenState extends State<LocationsManagementScreen> {
  final LocationService _locationService = LocationService();
  String _searchQuery = '';

  List<AdminLocation> _locations = [];
  LocationStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadStatistics();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _locationService.getAllLocations(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _filterActive,
        page: _currentPage,
        pageSize: 10,
      );

      setState(() {
        _locations = response.locations;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _locationService.getStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditLocationDialog(
        onSave: () {
          _loadLocations();
          _loadStatistics();
        },
      ),
    );
  }

  void _showEditLocationDialog(AdminLocation location) {
    showDialog(
      context: context,
      builder: (context) => AddEditLocationDialog(
        location: location,
        onSave: () {
          _loadLocations();
          _loadStatistics();
        },
      ),
    );
  }

  Future<void> _deleteLocation(AdminLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _locationService.deleteLocation(location.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully')),
        );
        _loadLocations();
        _loadStatistics();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations Management'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Statistics Cards
          if (_statistics != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  _buildStatCard(
                    'Total Locations',
                    _statistics!.totalLocations.toString(),
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Active',
                    _statistics!.activeLocations.toString(),
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'With Coordinates',
                    _statistics!.locationsWithCoordinates.toString(),
                    Colors.orange,
                  ),
                ],
              ),
            ),

          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1;
                      });
                      _loadLocations();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, district, state, or pincode',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
                                });
                                _loadLocations();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool?>(
                      value: _filterActive,
                      hint: Row(
                        children: [
                          Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'All Status',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.list, size: 18, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text('All Status'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text('Active Only'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 18, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              const Text('Inactive Only'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterActive = value;
                          _currentPage = 1;
                        });
                        _loadLocations();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadLocations,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddLocationDialog,
                  icon: const Icon(Icons.add_location, size: 20),
                  label: const Text('Add Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),

          // Locations Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLocations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _locations.isEmpty
                        ? const Center(
                            child: Text('No locations found'),
                          )
                        : SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                columnSpacing: 20,
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('District')),
                                  DataColumn(label: Text('State')),
                                  DataColumn(label: Text('Sub-Location')),
                                  DataColumn(label: Text('Pincode')),
                                  DataColumn(label: Text('Latitude')),
                                  DataColumn(label: Text('Longitude')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _locations.map((location) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(location.name)),
                                      DataCell(Text(location.district)),
                                      DataCell(Text(location.state)),
                                      DataCell(Text(location.subLocation ?? '-')),
                                      DataCell(Text(location.pincode ?? '-')),
                                      DataCell(Text(
                                        location.latitude?.toStringAsFixed(6) ?? '-',
                                      )),
                                      DataCell(Text(
                                        location.longitude?.toStringAsFixed(6) ?? '-',
                                      )),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: location.isActive
                                                ? Colors.green[100]
                                                : Colors.red[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            location.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: location.isActive
                                                  ? Colors.green[900]
                                                  : Colors.red[900],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => _showEditLocationDialog(location),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteLocation(location),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),

          // Pagination
          if (_totalPages > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First page button
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage = 1;
                            });
                            _loadLocations();
                          }
                        : null,
                    tooltip: 'First page',
                    color: Colors.green[700],
                  ),
                  // Previous page button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage > 1 ? Colors.green[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadLocations();
                            }
                          : null,
                      tooltip: 'Previous page',
                    ),
                  ),
                  // Page indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[700]!, width: 2),
                    ),
                    child: Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                  // Next page button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage < _totalPages ? Colors.green[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadLocations();
                            }
                          : null,
                      tooltip: 'Next page',
                    ),
                  ),
                  // Last page button
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() {
                              _currentPage = _totalPages;
                            });
                            _loadLocations();
                          }
                        : null,
                    tooltip: 'Last page',
                    color: Colors.green[700],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddEditLocationDialog extends StatefulWidget {
  final AdminLocation? location;
  final VoidCallback onSave;

  const AddEditLocationDialog({
    Key? key,
    this.location,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditLocationDialog> createState() => _AddEditLocationDialogState();
}

class _AddEditLocationDialogState extends State<AddEditLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  late TextEditingController _nameController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _subLocationController;
  late TextEditingController _pincodeController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _stateController = TextEditingController(text: widget.location?.state ?? '');
    _districtController = TextEditingController(text: widget.location?.district ?? '');
    _subLocationController = TextEditingController(text: widget.location?.subLocation ?? '');
    _pincodeController = TextEditingController(text: widget.location?.pincode ?? '');
    _latitudeController = TextEditingController(
      text: widget.location?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.location?.longitude?.toString() ?? '',
    );
    _isActive = widget.location?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stateController.dispose();
    _subLocationController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.location == null) {
        // Create new location
        final request = CreateLocationRequest(
          name: _nameController.text.trim(),
          subLocation: _subLocationController.text.trim().isEmpty
              ? null
              : _subLocationController.text.trim(),
          state: _stateController.text.trim(),
          district: _districtController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty
              ? null
              : _pincodeController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
        );
        await _locationService.createLocation(request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location created successfully')),
        );
      } else {
        // Update existing location
        final request = UpdateLocationRequest(
          name: _nameController.text.trim(),
          state: _stateController.text.trim(),
          district: _districtController.text.trim(),
          subLocation: _subLocationController.text.trim().isEmpty
              ? null
              : _subLocationController.text.trim(),
          pincode: _pincodeController.text.trim().isEmpty
              ? null
              : _pincodeController.text.trim(),
          latitude: double.tryParse(_latitudeController.text.trim()),
          longitude: double.tryParse(_longitudeController.text.trim()),
          isActive: _isActive,
        );
        await _locationService.updateLocation(widget.location!.id, request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }

      Navigator.pop(context);
      widget.onSave();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Add Location' : 'Edit Location'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter district';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Sub-Location (e.g., Hospital, School, etc.)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter landmark or specific area',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final lat = double.tryParse(value.trim());
                          if (lat == null || lat < -90 || lat > 90) {
                            return 'Invalid latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final lng = double.tryParse(value.trim());
                          if (lng == null || lng < -180 || lng > 180) {
                            return 'Invalid longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.location != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
