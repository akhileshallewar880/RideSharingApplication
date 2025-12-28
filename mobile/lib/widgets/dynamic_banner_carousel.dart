import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner.dart' as model;
import '../services/banner_service.dart';
import '../core/config/environment_config.dart';

class DynamicBannerCarousel extends StatefulWidget {
  final List<model.Banner> banners;
  final double height;
  final Duration autoPlayInterval;

  const DynamicBannerCarousel({
    Key? key,
    required this.banners,
    this.height = 180,
    this.autoPlayInterval = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<DynamicBannerCarousel> createState() => _DynamicBannerCarouselState();
}

class _DynamicBannerCarouselState extends State<DynamicBannerCarousel> {
  final BannerService _bannerService = BannerService();
  int _currentIndex = 0;
  final Set<String> _impressionRecorded = {};

  @override
  void initState() {
    super.initState();
    // Record impression for first banner
    if (widget.banners.isNotEmpty) {
      _recordImpression(widget.banners[0].id);
    }
  }

  void _recordImpression(String bannerId) {
    if (!_impressionRecorded.contains(bannerId)) {
      _impressionRecorded.add(bannerId);
      _bannerService.recordImpression(bannerId);
    }
  }

  Future<void> _handleBannerTap(model.Banner banner) async {
    // Record click
    await _bannerService.recordClick(banner.id);

    // Handle action
    if (banner.hasAction && banner.actionUrl != null) {
      if (banner.actionType == 'external') {
        // Open external URL
        final uri = Uri.parse(banner.actionUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (banner.actionType == 'deeplink') {
        // TODO: Handle deep link navigation within app
        // This would navigate to specific screens based on URL pattern
        print('Deep link: ${banner.actionUrl}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.banners.length == 1) {
      return _buildBannerCard(widget.banners[0]);
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            autoPlay: true,
            autoPlayInterval: widget.autoPlayInterval,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
              _recordImpression(widget.banners[index].id);
            },
          ),
          items: widget.banners.map((banner) => _buildBannerCard(banner)).toList(),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.banners.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBannerCard(model.Banner banner) {
    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (banner.imageUrl != null)
                Image.network(
                  '${EnvironmentConfig.baseUrl}${banner.imageUrl}',
                  fit: BoxFit.cover,
                  cacheWidth: 400, // Limit memory usage
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackBanner(banner);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
              else
                _buildFallbackBanner(banner),

              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (banner.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (banner.hasAction && banner.actionText != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            banner.actionText!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(model.Banner banner) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (banner.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  banner.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
