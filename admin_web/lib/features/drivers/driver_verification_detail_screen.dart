import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_models.dart';
import '../../core/providers/driver_provider.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/constants/app_constants.dart';

class DriverVerificationDetailScreen extends ConsumerStatefulWidget {
  final PendingDriver driver;

  const DriverVerificationDetailScreen({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  ConsumerState<DriverVerificationDetailScreen> createState() =>
      _DriverVerificationDetailScreenState();
}

class _DriverVerificationDetailScreenState
    extends ConsumerState<DriverVerificationDetailScreen> {
  final _rejectionReasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _approveDriver() async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Driver',
      message: 'Are you sure you want to approve ${widget.driver.fullName}?',
      confirmText: 'Approve',
      isDestructive: false,
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      try {
        await ref.read(pendingDriversProvider.notifier).approveDriver(
              widget.driver.id,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver approved successfully'),
              backgroundColor: AdminTheme.successColor,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _rejectDriver() async {
    final reason = await _showRejectDialog();

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isProcessing = true);

      try {
        await ref.read(pendingDriversProvider.notifier).rejectDriver(
              widget.driver.id,
              reason,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver rejected'),
              backgroundColor: AdminTheme.warningColor,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AdminTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AdminTheme.errorColor
                  : AdminTheme.successColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() {
    _rejectionReasonController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for rejection:'),
            SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid documents, unclear photos...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_rejectionReasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Verification'),
        actions: [
          if (widget.driver.verificationStatus == 'pending') ...[
            if (!_isProcessing)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: _rejectDriver,
                tooltip: 'Reject',
              ),
            SizedBox(width: 8),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Banner
              if (widget.driver.verificationStatus != 'pending')
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminTheme.getStatusBackgroundColor(
                        widget.driver.verificationStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.driver.verificationStatus == 'approved'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: AdminTheme.getStatusColor(
                            widget.driver.verificationStatus),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.driver.verificationStatus.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.getStatusColor(
                                    widget.driver.verificationStatus),
                              ),
                            ),
                            if (widget.driver.rejectionReason != null)
                              Text(
                                widget.driver.rejectionReason!,
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),

              // Driver Information
              _buildSection(
                title: 'Driver Information',
                child: Column(
                  children: [
                    _buildInfoTile('Full Name', widget.driver.fullName),
                    _buildInfoTile('Email', widget.driver.email),
                    _buildInfoTile('Phone', widget.driver.phone),
                    _buildInfoTile(
                      'Date of Birth',
                      '${DateFormat('dd MMM yyyy').format(widget.driver.dateOfBirth)} (${widget.driver.age} years)',
                    ),
                    if (widget.driver.emergencyContact != null)
                      _buildInfoTile(
                        'Emergency Contact',
                        widget.driver.emergencyContact!,
                      ),
                    _buildInfoTile(
                      'Registration Date',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(widget.driver.registeredAt),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Vehicle Information
              _buildSection(
                title: 'Vehicle Information',
                child: Column(
                  children: [
                    _buildInfoTile('Vehicle Number', widget.driver.vehicleNumber),
                    _buildInfoTile(
                      'Vehicle Type',
                      widget.driver.vehicleType.toUpperCase(),
                    ),
                    _buildInfoTile('City', widget.driver.city),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Documents
              _buildSection(
                title: 'Documents',
                child: Column(
                  children: [
                    if (widget.driver.documents.drivingLicense != null)
                      _buildDocumentCard(
                        'Driving License',
                        widget.driver.documents.drivingLicense!,
                      ),
                    SizedBox(height: 12),
                    if (widget.driver.documents.rcBook != null)
                      _buildDocumentCard(
                        'RC Book',
                        widget.driver.documents.rcBook!,
                      ),
                    SizedBox(height: 12),
                    if (widget.driver.documents.profilePhoto != null)
                      _buildDocumentCard(
                        'Profile Photo',
                        widget.driver.documents.profilePhoto!,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Notes (for admin)
              if (widget.driver.verificationStatus == 'pending')
                _buildSection(
                  title: 'Admin Notes (Optional)',
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any notes about this verification...',
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Action Buttons
              if (widget.driver.verificationStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text('Reject'),
                        onPressed: _isProcessing ? null : _rejectDriver,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.errorColor,
                          side: BorderSide(color: AdminTheme.errorColor),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _isProcessing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.check),
                        label: Text(_isProcessing ? 'Processing...' : 'Approve Driver'),
                        onPressed: _isProcessing ? null : _approveDriver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.successColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AdminTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, DocumentInfo document) {
    // Construct full URL if document URL is relative
    final String fullDocumentUrl = document.documentUrl.startsWith('http')
        ? document.documentUrl
        : '${AppConstants.baseUrl.replaceAll('/api/v1', '')}${document.documentUrl}';
    
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Open document in new tab/window
          _viewDocument(document, fullDocumentUrl);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AdminTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fullDocumentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image,
                        size: 40,
                        color: AdminTheme.primaryColor,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Uploaded: ${DateFormat('dd MMM yyyy').format(document.uploadedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: document.status == 'verified' 
                            ? AdminTheme.successColor.withOpacity(0.1)
                            : AdminTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: document.status == 'verified'
                              ? AdminTheme.successColor
                              : AdminTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: AdminTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  void _viewDocument(DocumentInfo document, String fullDocumentUrl) {
    // For web, we can use url_launcher or open in dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: Text('Document Viewer'),
                leading: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.open_in_browser),
                    onPressed: () {
                      // Open in new browser tab
                      // For web: window.open(fullDocumentUrl, '_blank');
                    },
                    tooltip: 'Open in new tab',
                  ),
                ],
              ),
              Expanded(
                child: Image.network(
                  fullDocumentUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load document'),
                          SizedBox(height: 8),
                          Text(
                            'URL: $fullDocumentUrl',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Error: ${error.toString()}',
                            style: TextStyle(fontSize: 10, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading document...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
