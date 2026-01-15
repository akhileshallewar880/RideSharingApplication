import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_type_model.dart';
import '../core/providers/vehicle_type_provider.dart';
import '../core/theme/admin_theme.dart';
import '../core/utils/toast_helper.dart';

class VehicleTypesManagementScreen extends ConsumerStatefulWidget {
  const VehicleTypesManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VehicleTypesManagementScreen> createState() => _VehicleTypesManagementScreenState();
}

class _VehicleTypesManagementScreenState extends ConsumerState<VehicleTypesManagementScreen> {
  bool? _filterIsActive;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicleTypes();
    });
  }

  void _loadVehicleTypes() {
    ref.read(vehicleTypeNotifierProvider.notifier).loadVehicleTypes(
          isActive: _filterIsActive,
          category: _filterCategory,
        );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => VehicleTypeFormDialog(
        onSave: () {
          _loadVehicleTypes();
          ToastHelper.showSuccess('Vehicle type created successfully');
        },
      ),
    );
  }

  void _showEditDialog(VehicleType vehicleType) {
    showDialog(
      context: context,
      builder: (context) => VehicleTypeFormDialog(
        vehicleType: vehicleType,
        onSave: () {
          _loadVehicleTypes();
          ToastHelper.showSuccess('Vehicle type updated successfully');
        },
      ),
    );
  }

  Future<void> _deleteVehicleType(VehicleType vehicleType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle Type'),
        content: Text('Are you sure you want to delete "${vehicleType.displayName}"?'),
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
      final success = await ref.read(vehicleTypeNotifierProvider.notifier).deleteVehicleType(vehicleType.id);
      if (success) {
        ToastHelper.showSuccess('Vehicle type deleted successfully');
      } else {
        final error = ref.read(vehicleTypeNotifierProvider).error;
        ToastHelper.showError(error ?? 'Failed to delete vehicle type');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleTypeNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Types Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage vehicle types and pricing',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Vehicle Type', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
                    _loadVehicleTypes();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  value: _filterCategory,
                  hint: const Text('All Categories'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'shared', child: Text('Shared')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                  ],
                  onChanged: (value) {
                    setState(() => _filterCategory = value);
                    _loadVehicleTypes();
                  },
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterIsActive = null;
                      _filterCategory = null;
                    });
                    _loadVehicleTypes();
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
                              onPressed: _loadVehicleTypes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.vehicleTypes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No vehicle types found', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Vehicle Type'),
                                ),
                              ],
                            ),
                          )
                        : _buildVehicleTypesList(state.vehicleTypes),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypesList(List<VehicleType> vehicleTypes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicleTypes.length,
      itemBuilder: (context, index) {
        final vehicleType = vehicleTypes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: vehicleType.isActive ? Colors.green[100] : Colors.grey[300],
              child: Icon(
                Icons.directions_car,
                color: vehicleType.isActive ? Colors.green[700] : Colors.grey[600],
              ),
            ),
            title: Row(
              children: [
                Text(
                  vehicleType.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: vehicleType.isActive ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicleType.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      color: vehicleType.isActive ? Colors.green[700] : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (vehicleType.category != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicleType.category!,
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Code: ${vehicleType.name}'),
                const SizedBox(height: 4),
                if (vehicleType.description != null)
                  Text(vehicleType.description!, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Text('Base: ₹${vehicleType.basePrice.toStringAsFixed(2)}'),
                    Text('Per Km: ₹${vehicleType.pricePerKm.toStringAsFixed(2)}'),
                    Text('Per Min: ₹${vehicleType.pricePerMinute.toStringAsFixed(2)}'),
                    Text('Seats: ${vehicleType.minSeats}-${vehicleType.maxSeats}'),
                  ],
                ),
                if (vehicleType.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: vehicleType.features
                        .map((feature) => Chip(
                              label: Text(feature, style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(vehicleType),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteVehicleType(vehicleType),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Form Dialog
class VehicleTypeFormDialog extends ConsumerStatefulWidget {
  final VehicleType? vehicleType;
  final VoidCallback onSave;

  const VehicleTypeFormDialog({
    Key? key,
    this.vehicleType,
    required this.onSave,
  }) : super(key: key);

  @override
  ConsumerState<VehicleTypeFormDialog> createState() => _VehicleTypeFormDialogState();
}

class _VehicleTypeFormDialogState extends ConsumerState<VehicleTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _iconController;
  late TextEditingController _descriptionController;
  late TextEditingController _basePriceController;
  late TextEditingController _pricePerKmController;
  late TextEditingController _pricePerMinuteController;
  late TextEditingController _minSeatsController;
  late TextEditingController _maxSeatsController;
  late TextEditingController _displayOrderController;
  late TextEditingController _featuresController;
  bool _isActive = true;
  String? _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final vt = widget.vehicleType;
    _nameController = TextEditingController(text: vt?.name ?? '');
    _displayNameController = TextEditingController(text: vt?.displayName ?? '');
    _iconController = TextEditingController(text: vt?.icon ?? '');
    _descriptionController = TextEditingController(text: vt?.description ?? '');
    _basePriceController = TextEditingController(text: vt?.basePrice.toString() ?? '0');
    _pricePerKmController = TextEditingController(text: vt?.pricePerKm.toString() ?? '0');
    _pricePerMinuteController = TextEditingController(text: vt?.pricePerMinute.toString() ?? '0');
    _minSeatsController = TextEditingController(text: vt?.minSeats.toString() ?? '1');
    _maxSeatsController = TextEditingController(text: vt?.maxSeats.toString() ?? '4');
    _displayOrderController = TextEditingController(text: vt?.displayOrder.toString() ?? '0');
    _featuresController = TextEditingController(text: vt?.features.join(', ') ?? '');
    _isActive = vt?.isActive ?? true;
    _category = vt?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _pricePerKmController.dispose();
    _pricePerMinuteController.dispose();
    _minSeatsController.dispose();
    _maxSeatsController.dispose();
    _displayOrderController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final features = _featuresController.text
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    bool success = false;

    if (widget.vehicleType == null) {
      // Create
      final dto = CreateVehicleTypeDto(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        icon: _iconController.text.trim().isEmpty ? null : _iconController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        basePrice: double.parse(_basePriceController.text),
        pricePerKm: double.parse(_pricePerKmController.text),
        pricePerMinute: double.parse(_pricePerMinuteController.text),
        minSeats: int.parse(_minSeatsController.text),
        maxSeats: int.parse(_maxSeatsController.text),
        isActive: _isActive,
        displayOrder: int.parse(_displayOrderController.text),
        category: _category,
        features: features,
      );
      success = await ref.read(vehicleTypeNotifierProvider.notifier).createVehicleType(dto);
    } else {
      // Update
      final dto = UpdateVehicleTypeDto(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        icon: _iconController.text.trim().isEmpty ? null : _iconController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        basePrice: double.parse(_basePriceController.text),
        pricePerKm: double.parse(_pricePerKmController.text),
        pricePerMinute: double.parse(_pricePerMinuteController.text),
        minSeats: int.parse(_minSeatsController.text),
        maxSeats: int.parse(_maxSeatsController.text),
        isActive: _isActive,
        displayOrder: int.parse(_displayOrderController.text),
        category: _category,
        features: features,
      );
      success = await ref.read(vehicleTypeNotifierProvider.notifier).updateVehicleType(widget.vehicleType!.id, dto);
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      widget.onSave();
    } else {
      final error = ref.read(vehicleTypeNotifierProvider).error;
      ToastHelper.showError(error ?? 'Failed to save vehicle type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.vehicleType == null ? 'Add Vehicle Type' : 'Edit Vehicle Type',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name (Code)', hintText: 'e.g., auto, car, suv'),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'Display Name', hintText: 'e.g., Auto Rickshaw'),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _iconController,
                        decoration: const InputDecoration(labelText: 'Icon (Optional)', hintText: 'Icon name or URL'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _basePriceController,
                              decoration: const InputDecoration(labelText: 'Base Price'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pricePerKmController,
                              decoration: const InputDecoration(labelText: 'Price Per Km'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pricePerMinuteController,
                              decoration: const InputDecoration(labelText: 'Price Per Minute'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minSeatsController,
                              decoration: const InputDecoration(labelText: 'Min Seats'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxSeatsController,
                              decoration: const InputDecoration(labelText: 'Max Seats'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _displayOrderController,
                              decoration: const InputDecoration(labelText: 'Display Order'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Category (Optional)'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None')),
                          DropdownMenuItem(value: 'personal', child: Text('Personal')),
                          DropdownMenuItem(value: 'shared', child: Text('Shared')),
                          DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                        ],
                        onChanged: (value) => setState(() => _category = value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _featuresController,
                        decoration: const InputDecoration(
                          labelText: 'Features (Optional)',
                          hintText: 'e.g., AC, GPS, Music System (comma-separated)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryColor),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
