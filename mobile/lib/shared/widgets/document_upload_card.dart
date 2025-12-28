import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Document upload card with camera/gallery options and preview
class DocumentUploadCard extends StatefulWidget {
  final String title;
  final bool isRequired;
  final void Function(File? file) onFileSelected;
  final File? initialFile;
  
  const DocumentUploadCard({
    super.key,
    required this.title,
    this.isRequired = true,
    required this.onFileSelected,
    this.initialFile,
  });
  
  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
  }
  
  Future<void> _showImageSourceBottomSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload ${widget.title}',
              style: TextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryYellow,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture document'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusMD,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryYellow,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        setState(() {
          _selectedFile = imageFile;
          _isLoading = false;
        });
        widget.onFileSelected(imageFile);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _removeImage() {
    setState(() {
      _selectedFile = null;
    });
    widget.onFileSelected(null);
  }
  
  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyles.labelMedium.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        
        if (_selectedFile == null)
          // Upload placeholder
          InkWell(
            onTap: _isLoading ? null : _showImageSourceBottomSheet,
            borderRadius: AppSpacing.borderRadiusMD,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkSurface 
                    : AppColors.lightSurface,
                border: Border.all(
                  color: AppColors.primaryYellow.withOpacity(0.4),
                  width: 2,
                ),
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: DottedBorderPainter(
                color: AppColors.primaryYellow.withOpacity(0.4),
                strokeWidth: 2,
                gap: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColors.darkSurface 
                          : AppColors.lightSurface,
                      borderRadius: AppSpacing.borderRadiusMD,
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryYellow,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 40,
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Upload ${widget.title}',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to take photo or choose from gallery',
                                style: TextStyles.caption.copyWith(
                                  color: isDark 
                                      ? AppColors.darkTextTertiary 
                                      : AppColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          )
        else
          // Preview card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSurface 
                  : AppColors.lightSurface,
              borderRadius: AppSpacing.borderRadiusMD,
              border: Border.all(
                color: AppColors.primaryYellow.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMD),
                  ),
                  child: Image.file(
                    _selectedFile!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // File info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: TextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getFileSize(_selectedFile!),
                              style: TextStyles.caption.copyWith(
                                color: isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                      ),
                      IconButton(
                        onPressed: _showImageSourceBottomSheet,
                        icon: const Icon(Icons.refresh),
                        color: AppColors.primaryYellow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Custom painter for dotted border effect
class DottedBorderPainter extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;

  const DottedBorderPainter({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 2,
    this.gap = 5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(AppSpacing.radiusMD),
        ),
      );

    _drawDottedPath(canvas, path, paint);
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final dashWidth = gap;
    final dashSpace = gap;
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        final end = metric.getTangentForOffset(distance + dashWidth);
        if (start != null && end != null) {
          canvas.drawLine(start.position, end.position, paint);
        }
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
