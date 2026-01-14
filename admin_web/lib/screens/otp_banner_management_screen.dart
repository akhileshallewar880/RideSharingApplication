import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/banner_models.dart' as banner_models;
import '../services/admin_banner_service.dart';
import '../widgets/banner_form_dialog.dart';

/// OTP Screen Banner Management Screen
/// Specifically for managing banners that appear on the OTP verification screen
class OTPBannerManagementScreen extends StatefulWidget {
  const OTPBannerManagementScreen({Key? key}) : super(key: key);

  @override
  State<OTPBannerManagementScreen> createState() => _OTPBannerManagementScreenState();
}

class _OTPBannerManagementScreenState extends State<OTPBannerManagementScreen> {
  final AdminBannerService _bannerService = AdminBannerService();

  List<banner_models.Banner> _banners = [];
  banner_models.BannerPagination? _pagination;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Filters - hardcoded for OTP screen
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Using pre-defined mock banners for now
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

    final now = DateTime.now();
    final mockBanners = [
      banner_models.Banner(
        id: 'mock-1',
        title: 'Welcome to VanYatra! 🚗',
        description: 'Your trusted rural ride booking platform',
        imageUrl: 'https://via.placeholder.com/400x200/2196F3/FFFFFF?text=Welcome+to+VanYatra',
        actionType: 'none',
        actionUrl: null,
        actionText: null,
        targetAudience: 'otp_screen',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        isActive: true,
        displayOrder: 1,
        impressionCount: 1245,
        clickCount: 87,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      banner_models.Banner(
        id: 'mock-2',
        title: 'Safe & Secure Rides',
        description: 'Verified drivers for your peace of mind',
        imageUrl: 'https://via.placeholder.com/400x200/4CAF50/FFFFFF?text=Safe+%26+Secure',
        actionType: 'none',
        actionUrl: null,
        actionText: null,
        targetAudience: 'otp_screen',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 27)),
        isActive: true,
        displayOrder: 2,
        impressionCount: 892,
        clickCount: 45,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now,
      ),
      banner_models.Banner(
        id: 'mock-3',
        title: 'Connect Rural Communities',
        description: 'Bridging distances, connecting lives',
        imageUrl: 'https://via.placeholder.com/400x200/FF9800/FFFFFF?text=Connect+Communities',
        actionType: 'none',
        actionUrl: null,
        actionText: null,
        targetAudience: 'otp_screen',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 23)),
        isActive: true,
        displayOrder: 3,
        impressionCount: 654,
        clickCount: 32,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now,
      ),
    ];

    if (mounted) {
      setState(() {
        _banners = mockBanners;
        _pagination = banner_models.BannerPagination(
          currentPage: 1,
          totalPages: 1,
          totalCount: mockBanners.length,
          pageSize: 10,
        );
        _isLoading = false;
      });
    }

    /* 
    // Original API call - commented out for now
    try {
      final response = await _bannerService.getBanners(
        isActive: _filterIsActive,
        targetAudience: _filterTargetAudience,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _banners = response.data;
          _pagination = response.pagination;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load banners: ${e.toString()}';
          _isLoading = false;
          _banners = []; // Clear banners on error
        });
      }
      debugPrint('Error loading banners: $e');
    }
    */
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        defaultTargetAudience: 'otp_screen',
        onSave: (banner) async {
          await _loadBanners();
          _showSuccessMessage('OTP Banner created !!');
        },
      ),
    );
  }

  void _showEditDialog(banner_models.Banner banner) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        banner: banner,
        defaultTargetAudience: 'otp_screen',
        onSave: (updatedBanner) async {
          await _loadBanners();
          _showSuccessMessage('OTP Banner updated successfully');
        },
      ),
    );
  }

  Future<void> _deleteBanner(banner_models.Banner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete OTP Banner'),
        content: Text('Are you sure you want to delete "${banner.title}"?'),
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
      try {
        await _bannerService.deleteBanner(banner.id);
        await _loadBanners();
        _showSuccessMessage('OTP Banner deleted successfully');
      } catch (e) {
        _showErrorMessage(e.toString());
      }
    }
  }

  Future<void> _toggleBannerStatus(banner_models.Banner banner) async {
    try {
      final request = banner_models.UpdateBannerRequest(
        isActive: !banner.isActive,
      );
      
      await _bannerService.updateBanner(banner.id, request);
      await _loadBanners();
      _showSuccessMessage(
        banner.isActive 
          ? 'Banner deactivated successfully' 
          : 'Banner activated successfully'
      );
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _successMessage = null);
      }
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OTP Screen Banners',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage banners displayed during OTP verification',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add OTP Banner'),
                  onPressed: _showCreateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Success/Error Messages
          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),

          // Info Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These banners will be displayed on the OTP verification screen. Keep messages concise and encouraging.',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),

          // Banners List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _banners.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No OTP banners found',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add OTP Banner" to create one',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return _buildBannerCard(banner);
                        },
                      ),
          ),

          // Pagination
          if (_pagination != null && _pagination!.totalPages > 1)
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
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadBanners();
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Page $_currentPage of ${_pagination!.totalPages}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _pagination!.totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadBanners();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(banner_models.Banner banner) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                  ? Image.network(
                      banner.imageUrl!,
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 32),
                    ),
            ),
            const SizedBox(width: 16),
            
            // Banner Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          banner.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: banner.isActive,
                        onChanged: (_) => _toggleBannerStatus(banner),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.description ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Start: ${dateFormat.format(banner.startDate)}',
                      ),
                      _buildInfoChip(
                        Icons.event_busy,
                        'End: ${dateFormat.format(banner.endDate)}',
                      ),
                      _buildInfoChip(
                        Icons.visibility,
                        '${banner.impressionCount} views',
                      ),
                      _buildInfoChip(
                        Icons.touch_app,
                        '${banner.clickCount} clicks',
                      ),
                      if (banner.impressionCount > 0)
                        _buildInfoChip(
                          Icons.trending_up,
                          'CTR: ${((banner.clickCount / banner.impressionCount) * 100).toStringAsFixed(1)}%',
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(banner),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBanner(banner),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color ?? Colors.grey[700]),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.grey[700],
        ),
      ),
      backgroundColor: color?.withOpacity(0.1) ?? Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
