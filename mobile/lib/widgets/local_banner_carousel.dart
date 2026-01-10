import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../app/themes/app_colors.dart';
import '../app/themes/text_styles.dart';

/// Local banner carousel that displays banners from assets folder
/// No API calls - uses local images only
class LocalBannerCarousel extends StatefulWidget {
  final double height;
  final Duration autoPlayInterval;

  const LocalBannerCarousel({
    Key? key,
    this.height = 180,
    this.autoPlayInterval = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<LocalBannerCarousel> createState() => _LocalBannerCarouselState();
}

class _LocalBannerCarouselState extends State<LocalBannerCarousel> {
  int _currentIndex = 0;

  // Local banner data - add your banners here
  final List<Map<String, String>> _localBanners = [
    {
      'image': 'assets/images/otp_banners/otp_banner_1.png',
      'title': 'Welcome to VanYatra! 🚗',
      'subtitle': 'Your trusted rural ride booking platform',
    },
    {
      'image': 'assets/images/otp_banners/otp_banner_2.png',
      'title': 'Safe & Secure Rides',
      'subtitle': 'Verified drivers for your peace of mind',
    },
    {
      'image': 'assets/images/otp_banners/otp_banner_3.png',
      'title': 'Connect Rural Communities',
      'subtitle': 'Bridging distances, connecting lives',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_localBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_localBanners.length == 1) {
      return _buildBannerCard(_localBanners[0]);
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
            },
          ),
          items: _localBanners.map((banner) => _buildBannerCard(banner)).toList(),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _localBanners.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key
                    ? AppColors.primaryGreen
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBannerCard(Map<String, String> banner) {
    return Container(
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
            // Background image from assets
            Image.asset(
              banner['image']!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient if image fails to load
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryYellow.withOpacity(0.8),
                        AppColors.primaryYellow,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not found',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Banner text content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner['title'] != null)
                    Text(
                      banner['title']!,
                      style: TextStyles.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (banner['subtitle'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner['subtitle']!,
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
