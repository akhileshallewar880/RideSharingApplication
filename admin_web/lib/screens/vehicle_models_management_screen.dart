import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model_model.dart';
import '../core/providers/vehicle_model_provider.dart';
import '../core/theme/admin_theme.dart';
import '../core/utils/toast_helper.dart';

class VehicleModelsManagementScreen extends ConsumerStatefulWidget {
  const VehicleModelsManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VehicleModelsManagementScreen> createState() => _VehicleModelsManagementScreenState();
}

class _VehicleModelsManagementScreenState extends ConsumerState<VehicleModelsManagementScreen> {
  bool? _filterIsActive;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicleModels();
    });
  }

  void _loadVehicleModels() {
    ref.read(vehicleModelNotifierProvider.notifier).loadVehicleModels(
          isActive: _filterIsActive,
          type: _filterType,
        );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => VehicleModelFormDialog(
        onSave: () {
          _loadVehicleModels();
          ToastHelper.success('Vehicle model created successfully');
        },
      ),
    );
  }

  void _showEditDialog(VehicleModel vehicleModel) {
    showDialog(
      context: context,
      builder: (context) => VehicleModelFormDialog(
        vehicleModel: vehicleModel,
        onSave: () {
          _loadVehicleModels();
          ToastHelper.success('Vehicle model updated successfully');
        },
      ),
    );
  }

  Future<void> _deleteVehicleModel(VehicleModel vehicleModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle Model'),
        content: Text('Are you sure you want to delete "${vehicleModel.brand} ${vehicleModel.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(vehicleModelNotifierProvider.notifier).deleteVehicleModel(vehicleModel.id);
      if (success) {
        ToastHelper.success('Vehicle model deleted successfully');
        _loadVehicleModels();
      } else {
        final error = ref.read(vehicleModelNotifierProvider).error;
        ToastHelper.error(error ?? 'Failed to delete vehicle model');
      }
    }
  }

  String _getLayoutLabelFromJson(String jsonLayout) {
    try {
      final Map<String, dynamic> layoutData = json.decode(jsonLayout);
      final String layout = layoutData['layout'] ?? '';
      return layout.replaceAll('-', '+');
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleModelNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Models',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage vehicle types and models',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                DropdownButton<bool?>(
                  value: _filterIsActive,
                  hint: const Text('All Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(value: true, child: Text('Active Only')),
                    DropdownMenuItem(value: false, child: Text('Inactive Only')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterIsActive = value);
                    _loadVehicleModels();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  value: _filterType,
                  hint: const Text('All Types'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'suv', child: Text('SUV')),
                    DropdownMenuItem(value: 'van', child: Text('Van')),
                    DropdownMenuItem(value: 'bus', child: Text('Bus')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterType = value);
                    _loadVehicleModels();
                  },
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterIsActive = null;
                      _filterType = null;
                    });
                    _loadVehicleModels();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(state.error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadVehicleModels,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.vehicleModels.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No vehicle models found', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Vehicle Model'),
                                ),
                              ],
                            ),
                          )
                        : _buildVehicleModelsList(state.vehicleModels),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleModelsList(List<VehicleModel> vehicleModels) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicleModels.length,
      itemBuilder: (context, index) {
        final vehicleModel = vehicleModels[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AdminTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: AdminTheme.primaryColor),
            ),
            title: Text(
              '${vehicleModel.brand} ${vehicleModel.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        vehicleModel.type.toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Text('Seats: ${vehicleModel.seatingCapacity}'),
                    if (vehicleModel.seatingLayout != null) ...[
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      Icon(Icons.event_seat, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getLayoutLabelFromJson(vehicleModel.seatingLayout!),
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicleModel.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicleModel.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (vehicleModel.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: vehicleModel.features.take(3).map((feature) =>
                      Chip(
                        label: Text(feature, style: const TextStyle(fontSize: 10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      )
                    ).toList(),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(vehicleModel);
                } else if (value == 'delete') {
                  _deleteVehicleModel(vehicleModel);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// Vehicle Model Form Dialog
class VehicleModelFormDialog extends ConsumerStatefulWidget {
  final VehicleModel? vehicleModel;
  final VoidCallback onSave;

  const VehicleModelFormDialog({
    Key? key,
    this.vehicleModel,
    required this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<VehicleModelFormDialog> createState() => _VehicleModelFormDialogState();
}

class _VehicleModelFormDialogState extends ConsumerState<VehicleModelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _seatingCapacityController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _featuresController;
  String _selectedType = 'car';
  bool _isActive = true;
  bool _isLoading = false;

  // Seating layout configuration
  int _numberOfRows = 0;
  List<TextEditingController> _rowSeatControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicleModel?.name ?? '');
    _brandController = TextEditingController(text: widget.vehicleModel?.brand ?? '');
    _seatingCapacityController = TextEditingController(
      text: widget.vehicleModel?.seatingCapacity.toString() ?? '4',
    );
    _imageUrlController = TextEditingController(text: widget.vehicleModel?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: widget.vehicleModel?.description ?? '');
    _featuresController = TextEditingController(
      text: widget.vehicleModel?.features.join(', ') ?? '',
    );
    _selectedType = widget.vehicleModel?.type ?? 'car';
    _isActive = widget.vehicleModel?.isActive ?? true;
    
    // Parse existing seating layout if editing
    if (widget.vehicleModel?.seatingLayout != null) {
      _parseExistingSeatingLayout(widget.vehicleModel!.seatingLayout!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _seatingCapacityController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose();
    for (var controller in _rowSeatControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _parseExistingSeatingLayout(String layoutJson) {
    try {
      final Map<String, dynamic> layoutData = json.decode(layoutJson);
      final String layout = layoutData['layout'] ?? '';
      final List<String> rowSeats = layout.split('-');
      
      setState(() {
        _numberOfRows = rowSeats.length;
        _rowSeatControllers = rowSeats.map((seats) {
          return TextEditingController(text: seats);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error parsing seating layout: $e');
    }
  }

  void _updateNumberOfRows(int rows) {
    setState(() {
      _numberOfRows = rows;
      
      // Add or remove controllers as needed
      while (_rowSeatControllers.length < rows) {
        _rowSeatControllers.add(TextEditingController(text: '2'));
      }
      while (_rowSeatControllers.length > rows) {
        _rowSeatControllers.removeLast().dispose();
      }
    });
  }

  String? _generateSeatingLayoutJson() {
    if (_numberOfRows == 0 || _rowSeatControllers.isEmpty) {
      return null;
    }

    try {
      final List<String> seatsPerRow = [];
      int seatNumber = 1;
      final List<Map<String, dynamic>> seats = [];

      for (int rowIndex = 0; rowIndex < _numberOfRows; rowIndex++) {
        final seatsInRow = int.tryParse(_rowSeatControllers[rowIndex].text) ?? 0;
        if (seatsInRow <= 0) continue;
        
        seatsPerRow.add(seatsInRow.toString());

        // Generate seat positions
        for (int seatIndex = 0; seatIndex < seatsInRow; seatIndex++) {
          String position;
          if (seatsInRow == 1) {
            position = 'left';
          } else if (seatsInRow == 2) {
            position = seatIndex == 0 ? 'left' : 'right';
          } else if (seatsInRow == 3) {
            if (seatIndex == 0) {
              position = 'left';
            } else {
              position = 'right';
            }
          } else {
            position = seatIndex < seatsInRow / 2 ? 'left' : 'right';
          }

          seats.add({
            'id': 'P$seatNumber',
            'row': rowIndex + 1,
            'position': position,
          });
          seatNumber++;
        }
      }

      if (seatsPerRow.isEmpty) return null;

      final layout = {
        'layout': seatsPerRow.join('-'),
        'rows': _numberOfRows,
        'seats': seats,
      };

      return json.encode(layout);
    } catch (e) {
      debugPrint('Error generating seating layout: $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final features = _featuresController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (widget.vehicleModel == null) {
        // Create
        final dto = CreateVehicleModelDto(
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          type: _selectedType,
          seatingCapacity: int.parse(_seatingCapacityController.text.trim()),
          seatingLayout: _generateSeatingLayoutJson(),
          imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          features: features,
        );

        final result = await ref.read(vehicleModelNotifierProvider.notifier).createVehicleModel(dto);
        if (result != null) {
          if (mounted) Navigator.pop(context);
          widget.onSave();
        } else {
          final error = ref.read(vehicleModelNotifierProvider).error;
          ToastHelper.error(error ?? 'Failed to create vehicle model');
        }
      } else {
        // Update
        final dto = UpdateVehicleModelDto(
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          type: _selectedType,
          seatingCapacity: int.parse(_seatingCapacityController.text.trim()),
          seatingLayout: _generateSeatingLayoutJson(),
          imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          features: features,
        );

        final result = await ref.read(vehicleModelNotifierProvider.notifier)
            .updateVehicleModel(widget.vehicleModel!.id, dto);
        if (result != null) {
          if (mounted) Navigator.pop(context);
          widget.onSave();
        } else {
          final error = ref.read(vehicleModelNotifierProvider).error;
          ToastHelper.error(error ?? 'Failed to update vehicle model');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vehicleModel == null ? 'Add Vehicle Model' : 'Edit Vehicle Model',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Model Name',
                          hintText: 'e.g., Ertiga, Innova',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Brand
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g., Maruti, Toyota',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'car', child: Text('Car')),
                          DropdownMenuItem(value: 'suv', child: Text('SUV')),
                          DropdownMenuItem(value: 'van', child: Text('Van')),
                          DropdownMenuItem(value: 'bus', child: Text('Bus')),
                        ],
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                      const SizedBox(height: 16),

                      // Seating Capacity
                      TextFormField(
                        controller: _seatingCapacityController,
                        decoration: const InputDecoration(
                          labelText: 'Seating Capacity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          final num = int.tryParse(value!);
                          if (num == null || num < 1) return 'Must be at least 1';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Seating Layout Configuration
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _numberOfRows.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Number of Rows (optional)',
                                    border: OutlineInputBorder(),
                                    helperText: 'Enter number of passenger rows',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (value) {
                                    final rows = int.tryParse(value) ?? 0;
                                    _updateNumberOfRows(rows);
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_numberOfRows > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Seats per Row',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Row 1 automatically includes the driver seat + passenger seats',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(_numberOfRows, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              'Row ${index + 1}:',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _rowSeatControllers[index],
                                              decoration: InputDecoration(
                                                hintText: 'Passenger seats',
                                                border: const OutlineInputBorder(),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                isDense: true,
                                                suffixText: index == 0 ? '+ driver' : 'passengers',
                                                suffixStyle: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSeatingLayoutPreview(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image URL
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Features
                      TextFormField(
                        controller: _featuresController,
                        decoration: const InputDecoration(
                          labelText: 'Features (comma separated)',
                          hintText: 'AC, Music System, GPS',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Is Active
                      Row(
                        children: [
                          Checkbox(
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value ?? true),
                          ),
                          const Text('Active'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.vehicleModel == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatingLayoutPreview() {
    if (_numberOfRows == 0 || _rowSeatControllers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse seats per row from controllers
    final List<int> rows = [];
    int totalSeats = 0;
    for (var controller in _rowSeatControllers) {
      final seats = int.tryParse(controller.text) ?? 0;
      if (seats > 0) {
        rows.add(seats);
        totalSeats += seats;
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final layoutString = rows.join('-');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_seat, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Seating Layout Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Layout: $layoutString (${totalSeats + 1} total seats including driver)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(Colors.orange.shade300, 'Driver'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue.shade300, 'Passenger'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Seat Map Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Front of vehicle indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FRONT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Driver's seat row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDriverSeat(),
                    const SizedBox(width: 40), // Aisle space
                  ],
                ),
                
                // Divider between driver and passengers
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 200,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.grey.shade300, Colors.transparent],
                    ),
                  ),
                ),
                
                // Passenger rows
                ...rows.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final seatsInRow = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildPassengerRow(seatsInRow, rowIndex + 1, rows),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            label == 'Driver' ? Icons.airline_seat_recline_normal : Icons.event_seat,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverSeat() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade600, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_recline_normal,
            size: 20,
            color: Colors.white,
          ),
          Text(
            'D',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(int seatsInRow, int rowNumber, List<int> allRows) {
    // Determine seat arrangement based on count
    List<Widget> seatWidgets = [];
    
    if (seatsInRow == 1) {
      // 1 seat: left side only
      seatWidgets = [
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 1, allRows)}'),
        const SizedBox(width: 40), // Aisle space
      ];
    } else if (seatsInRow == 2) {
      // 2 seats: one on each side
      seatWidgets = [
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 1, allRows)}'),
        const SizedBox(width: 40), // Aisle
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 2, allRows)}'),
      ];
    } else if (seatsInRow == 3) {
      // 3 seats: one left, two right
      seatWidgets = [
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 1, allRows)}'),
        const SizedBox(width: 40), // Aisle
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 2, allRows)}'),
        const SizedBox(width: 4),
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 3, allRows)}'),
      ];
    } else if (seatsInRow == 4) {
      // 4 seats: two on each side
      seatWidgets = [
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 1, allRows)}'),
        const SizedBox(width: 4),
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 2, allRows)}'),
        const SizedBox(width: 40), // Aisle
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 3, allRows)}'),
        const SizedBox(width: 4),
        _buildPassengerSeat('P${_getSeatNumber(rowNumber, 4, allRows)}'),
      ];
    } else {
      // Default: distribute evenly
      for (int i = 0; i < seatsInRow; i++) {
        if (i > 0 && i != (seatsInRow + 1) ~/ 2) {
          seatWidgets.add(const SizedBox(width: 4));
        }
        if (i == (seatsInRow + 1) ~/ 2) {
          seatWidgets.add(const SizedBox(width: 40)); // Aisle in middle
        }
        seatWidgets.add(_buildPassengerSeat('P${_getSeatNumber(rowNumber, i + 1, allRows)}'));
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: seatWidgets,
    );
  }

  int _getSeatNumber(int row, int position, List<int> rows) {
    // Calculate cumulative seat number
    int count = 0;
    for (int i = 0; i < row - 1; i++) {
      count += rows[i];
    }
    return count + position;
  }

  Widget _buildPassengerSeat(String seatId) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade600, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_seat,
            size: 18,
            color: Colors.white,
          ),
          Text(
            seatId,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
