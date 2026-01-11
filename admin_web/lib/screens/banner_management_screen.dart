import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/banner_models.dart' as banner_models;
import '../services/admin_banner_service.dart';
import '../widgets/banner_form_dialog.dart';
import '../core/constants/app_constants.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({Key? key}) : super(key: key);

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final AdminBannerService _bannerService = AdminBannerService();

  List<banner_models.Banner> _banners = [];
  banner_models.BannerPagination? _pagination;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Filters
  bool? _filterIsActive;
  String? _filterTargetAudience;
  int _currentPage = 1;
  final int _pageSize = 10;

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

    try {
      final response = await _bannerService.getBanners(
        isActive: _filterIsActive,
        targetAudience: _filterTargetAudience,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _banners = response.data;
        _pagination = response.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        onSave: (banner) async {
          await _loadBanners();
          _showSuccessMessage('Banner created successfully');
        },
      ),
    );
  }

  void _showEditDialog(banner_models.Banner banner) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        banner: banner,
        onSave: (updatedBanner) async {
          await _loadBanners();
          _showSuccessMessage('Banner updated successfully');
        },
      ),
    );
  }

  Future<void> _deleteBanner(banner_models.Banner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
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
        _showSuccessMessage('Banner deleted successfully');
      } catch (e) {
        _showErrorMessage(e.toString());
      }
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.view_carousel, size: 32, color: Color(0xFF2E7D32)),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banner Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create and manage promotional banners for mobile app',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Messages
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

          // Filters
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Active filter
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<bool?>(
                    value: _filterIsActive,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterIsActive = value;
                        _currentPage = 1;
                      });
                      _loadBanners();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Audience filter
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    value: _filterTargetAudience,
                    decoration: const InputDecoration(
                      labelText: 'Audience',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'passenger', child: Text('Passengers')),
                      DropdownMenuItem(value: 'driver', child: Text('Drivers')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterTargetAudience = value;
                        _currentPage = 1;
                      });
                      _loadBanners();
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBanners,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Banner list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _banners.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No banners found', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _showCreateDialog,
                              child: const Text('Create First Banner'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return _BannerCard(
                            banner: banner,
                            onEdit: () => _showEditDialog(banner),
                            onDelete: () => _deleteBanner(banner),
                          );
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
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
}

class _BannerCard extends StatelessWidget {
  final banner_models.Banner banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCurrentlyActive = banner.isCurrentlyActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner preview
            if (banner.imageUrl != null)
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(AppConstants.getImageUrl(banner.imageUrl!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            const SizedBox(width: 16),

            // Banner info
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentlyActive ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCurrentlyActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentlyActive ? Colors.green[800] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (banner.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      banner.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: '${dateFormat.format(banner.startDate)} - ${dateFormat.format(banner.endDate)}',
                      ),
                      _InfoChip(
                        icon: Icons.people,
                        label: banner.targetAudience,
                      ),
                      _InfoChip(
                        icon: Icons.sort,
                        label: 'Order: ${banner.displayOrder}',
                      ),
                      _InfoChip(
                        icon: Icons.visibility,
                        label: '${banner.impressionCount} views',
                      ),
                      _InfoChip(
                        icon: Icons.touch_app,
                        label: '${banner.clickCount} clicks (${banner.clickThroughRate.toStringAsFixed(1)}%)',
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
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  color: const Color(0xFF2E7D32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
