import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/driver_registration_service.dart';
import '../../../core/theme/admin_theme.dart';

class DriverRegistrationDialog extends StatefulWidget {
  final VoidCallback? onRegistered;

  const DriverRegistrationDialog({
    super.key,
    this.onRegistered,
  });

  @override
  State<DriverRegistrationDialog> createState() => _DriverRegistrationDialogState();
}

class _DriverRegistrationDialogState extends State<DriverRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  DateTime? _dateOfBirth;

  List<RegistrationCity> _cities = const [];
  RegistrationCity? _selectedCity;

  List<RegistrationVehicleModel> _vehicleModels = const [];
  RegistrationVehicleModel? _selectedVehicleModel;

  PlatformFile? _licenseFile;
  PlatformFile? _rcFile;

  bool _loadingLookups = true;
  bool _submitting = false;

  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _otpId;
  String? _tempToken;

  final _service = DriverRegistrationService();

  @override
  void initState() {
    super.initState();
    _loadLookups();

    _phoneController.addListener(() {
      // If phone is edited after OTP sent/verified, force re-verification.
      if (_otpSent || _otpVerified) {
        setState(() {
          _otpSent = false;
          _otpVerified = false;
          _otpId = null;
          _tempToken = null;
          _otpController.text = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _vehicleNumberController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phoneDigits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phoneError = _validatePhone(phoneDigits);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _sendingOtp = true;
      _otpSent = false;
      _otpVerified = false;
      _otpId = null;
      _tempToken = null;
      _otpController.text = '';
    });

    try {
      final result = await _service.sendOtp(phoneNumber: phoneDigits);
      if (!mounted) return;

      if (result.isExistingUser == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This phone number is already registered. Use a new number to register a driver.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (result.otpId == null || result.otpId!.isEmpty) {
        throw Exception('OTP ID missing from server response');
      }

      setState(() {
        _otpId = result.otpId;
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phoneDigits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final otp = _otpController.text.trim();

    if (_otpId == null || _otpId!.isEmpty) {
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

    setState(() => _verifyingOtp = true);
    try {
      final result = await _service.verifyOtp(
        phoneNumber: phoneDigits,
        otp: otp,
        otpId: _otpId!,
      );

      if (!mounted) return;

      if (!result.isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This phone number is already registered. Use a new number to register a driver.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (result.tempToken == null || result.tempToken!.isEmpty) {
        throw Exception('Temporary token missing from server response');
      }

      setState(() {
        _tempToken = result.tempToken;
        _otpVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number verified'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _loadingLookups = true);
    try {
      final cities = await _service.getCities();
      final models = await _service.getVehicleModels();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _vehicleModels = models;
        _loadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load registration data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter full name';
    if (v.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final ok = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v);
    return ok ? null : 'Please enter a valid email';
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter phone number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit number';
    return null;
  }

  String? _validateEmergencyContact(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit number';
    return null;
  }

  String? _validateVehicleNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter vehicle number';

    final clean = v.replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    if (!regex.hasMatch(clean)) {
      return 'Enter valid vehicle number (e.g., MH 31 AB 1234)';
    }

    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? initial,
      firstDate: DateTime(1950),
      lastDate: initial,
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickDocument({required bool isLicense}) async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (!mounted) return;

    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    if ((file.size) > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File size cannot exceed 10MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (isLicense) {
        _licenseFile = file;
      } else {
        _rcFile = file;
      }
    });
  }

  Future<void> _submit() async {
    if (!_otpVerified || _tempToken == null || _tempToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify mobile number with OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select current city'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedVehicleModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select vehicle type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_licenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload driving license'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rcFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload vehicle RC'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final phoneDigits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      final dobStr = _dateOfBirth!.toIso8601String().split('T').first;

      String? emergency;
      final emergencyDigits = _emergencyContactController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (emergencyDigits.isNotEmpty) {
        emergency = '+91$emergencyDigits';
      }

      final vehicleNumber = _vehicleNumberController.text.trim().replaceAll(' ', '').toUpperCase();

      final payload = DriverRegistrationPayload(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        dateOfBirth: dobStr,
        phoneNumber: phoneDigits,
        currentCityId: _selectedCity!.id,
        currentCityName: _selectedCity!.name,
        vehicleModelId: _selectedVehicleModel!.id,
        vehicleNumber: vehicleNumber,
        emergencyContact: emergency,
      );

      final result = await _service.completeDriverRegistration(
        payload: payload,
        tempToken: _tempToken,
      );

      // Upload documents with the newly created driver's access token (same as driver app)
      await _service.uploadDriverDocument(
        accessToken: result.accessToken,
        file: _licenseFile!,
        documentType: 'license',
      );
      await _service.uploadDriverDocument(
        accessToken: result.accessToken,
        file: _rcFile!,
        documentType: 'rc',
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onRegistered?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver ${_nameController.text.trim()} registered successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.local_taxi, color: AdminTheme.accentColor),
          const SizedBox(width: 8),
          const Text('Register New Driver'),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: _loadingLookups
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sectionTitle('Basic Information'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'Email (Optional)',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        validator: _validatePhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _otpVerified
                                  ? 'Mobile verified'
                                  : (_otpSent ? 'OTP sent. Enter OTP to verify.' : 'Verify mobile number using OTP'),
                              style: TextStyle(
                                color: _otpVerified ? Colors.green : AdminTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: (_submitting || _sendingOtp || _otpVerified) ? null : _sendOtp,
                            icon: _sendingOtp
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sms),
                            label: Text(_sendingOtp ? 'Sending...' : 'Send OTP'),
                          ),
                        ],
                      ),
                      if (_otpSent && !_otpVerified) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'OTP *',
                                  hintText: '1234',
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: (_submitting || _verifyingOtp) ? null : _verifyOtp,
                              child: _verifyingOtp
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
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _submitting ? null : _pickDob,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _dateOfBirth == null
                                ? 'Select date'
                                : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                    '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                    '${_dateOfBirth!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Location'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RegistrationCity>(
                        value: _selectedCity,
                        items: _cities
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting ? null : (v) => setState(() => _selectedCity = v),
                        validator: (v) => v == null ? 'Please select a city' : null,
                        decoration: const InputDecoration(
                          labelText: 'Current City *',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Vehicle Details'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RegistrationVehicleModel>(
                        value: _selectedVehicleModel,
                        items: _vehicleModels
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting ? null : (v) => setState(() => _selectedVehicleModel = v),
                        validator: (v) => v == null ? 'Please select vehicle type' : null,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type *',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleNumberController,
                        validator: _validateVehicleNumber,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
                          _UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number *',
                          hintText: 'MH 31 AB 1234',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Documents'),
                      const SizedBox(height: 12),
                      _fileRow(
                        title: 'Driving License *',
                        file: _licenseFile,
                        onPick: () => _pickDocument(isLicense: true),
                      ),
                      const SizedBox(height: 10),
                      _fileRow(
                        title: 'Vehicle RC *',
                        file: _rcFile,
                        onPick: () => _pickDocument(isLicense: false),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Emergency Contact'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emergencyContactController,
                        validator: _validateEmergencyContact,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact (Optional)',
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.emergency),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Required fields',
                        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: (_loadingLookups || _submitting || !_otpVerified) ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_submitting ? 'Registering...' : (_otpVerified ? 'Complete Registration' : 'Verify Mobile First')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AdminTheme.textPrimary,
      ),
    );
  }

  Widget _fileRow({
    required String title,
    required PlatformFile? file,
    required VoidCallback onPick,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            file == null ? title : '$title: ${file.name}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _submitting ? null : onPick,
          icon: const Icon(Icons.upload_file),
          label: Text(file == null ? 'Upload' : 'Change'),
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
