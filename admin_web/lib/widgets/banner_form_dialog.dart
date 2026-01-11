import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/banner_models.dart' as banner_models;
import '../services/admin_banner_service.dart';
import '../core/constants/app_constants.dart';

class BannerFormDialog extends StatefulWidget {
  final banner_models.Banner? banner;
  final Function(banner_models.Banner) onSave;
  final String? defaultTargetAudience;

  const BannerFormDialog({
    Key? key,
    this.banner,
    required this.onSave,
    this.defaultTargetAudience,
  }) : super(key: key);

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminBannerService _bannerService = AdminBannerService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _actionUrlController;
  late TextEditingController _actionTextController;
  late TextEditingController _displayOrderController;

  String _actionType = 'none';
  String _targetAudience = 'all';
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  bool _isSaving = false;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing banner data or defaults
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _descriptionController = TextEditingController(text: widget.banner?.description ?? '');
    _imageUrlController = TextEditingController(text: widget.banner?.imageUrl ?? '');
    _actionUrlController = TextEditingController(text: widget.banner?.actionUrl ?? '');
    _actionTextController = TextEditingController(text: widget.banner?.actionText ?? '');
    _displayOrderController = TextEditingController(
      text: widget.banner?.displayOrder.toString() ?? '0',
    );

    if (widget.banner != null) {
      _actionType = widget.banner!.actionType;
      _targetAudience = widget.banner!.targetAudience;
      _isActive = widget.banner!.isActive;
      _startDate = widget.banner!.startDate;
      _endDate = widget.banner!.endDate;
    } else if (widget.defaultTargetAudience != null) {
      // Use default target audience for new banners
      _targetAudience = widget.defaultTargetAudience!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    _actionTextController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'File size must be less than 5MB';
          });
          return;
        }

        setState(() {
          _isUploading = true;
          _errorMessage = null;
        });

        try {
          final imageUrl = await _bannerService.uploadImage(file);
          setState(() {
            _imageUrlController.text = imageUrl;
            _isUploading = false;
          });
        } catch (e) {
          setState(() {
            _errorMessage = e.toString();
            _isUploading = false;
          });
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_startDate.isAfter(_endDate)) {
      setState(() {
        _errorMessage = 'End date must be after start date';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      banner_models.Banner savedBanner;

      if (widget.banner == null) {
        // Create new banner
        final request = banner_models.CreateBannerRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          actionUrl: _actionUrlController.text.trim().isEmpty
              ? null
              : _actionUrlController.text.trim(),
          actionType: _actionType,
          actionText: _actionTextController.text.trim().isEmpty
              ? null
              : _actionTextController.text.trim(),
          displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          targetAudience: _targetAudience,
        );

        savedBanner = await _bannerService.createBanner(request);
      } else {
        // Update existing banner
        final request = banner_models.UpdateBannerRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          actionUrl: _actionUrlController.text.trim().isEmpty
              ? null
              : _actionUrlController.text.trim(),
          actionType: _actionType,
          actionText: _actionTextController.text.trim().isEmpty
              ? null
              : _actionTextController.text.trim(),
          displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          targetAudience: _targetAudience,
        );

        savedBanner = await _bannerService.updateBanner(widget.banner!.id, request);
      }

      widget.onSave(savedBanner);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_carousel, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.banner == null ? 'Create Banner' : 'Edit Banner',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: 16),

                      // Image URL and upload
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload),
                            label: const Text('Upload'),
                          ),
                        ],
                      ),

                      // Image preview
                      if (_imageUrlController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                AppConstants.getImageUrl(_imageUrlController.text),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Action Type
                      DropdownButtonFormField<String>(
                        value: _actionType,
                        decoration: const InputDecoration(
                          labelText: 'Action Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('None')),
                          DropdownMenuItem(value: 'deeplink', child: Text('Deep Link')),
                          DropdownMenuItem(value: 'external', child: Text('External URL')),
                        ],
                        onChanged: (value) {
                          setState(() => _actionType = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Action URL (if action type is not none)
                      if (_actionType != 'none') ...[
                        TextFormField(
                          controller: _actionUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Action URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _actionTextController,
                          decoration: const InputDecoration(
                            labelText: 'Action Button Text',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 100,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Row: Target Audience and Display Order
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _targetAudience,
                              decoration: const InputDecoration(
                                labelText: 'Target Audience',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Users')),
                                DropdownMenuItem(value: 'passenger', child: Text('Passengers')),
                                DropdownMenuItem(value: 'driver', child: Text('Drivers')),
                              ],
                              onChanged: (value) {
                                setState(() => _targetAudience = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _displayOrderController,
                              decoration: const InputDecoration(
                                labelText: 'Display Order',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateFormat.format(_startDate)),
                                    const Icon(Icons.calendar_today, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateFormat.format(_endDate)),
                                    const Icon(Icons.calendar_today, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active toggle
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Banner will be visible to users'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                        activeColor: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveBanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.banner == null ? 'Create' : 'Save'),
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
