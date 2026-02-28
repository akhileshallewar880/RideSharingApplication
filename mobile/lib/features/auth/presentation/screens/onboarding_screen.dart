import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/shared/widgets/buttons.dart';

/// Onboarding carousel screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Book Rides Easily',
      description: 'Find rides in your village or nearby towns with just a few taps',
      icon: Icons.location_on_outlined,
      color: AppColors.success,
    ),
    OnboardingPage(
      title: 'Safe & Reliable',
      description: 'All drivers are verified and rated by the community',
      icon: Icons.verified_user_outlined,
      color: AppColors.info,
    ),
    OnboardingPage(
      title: 'Affordable Fares',
      description: 'Pay fair prices for your journey with multiple payment options',
      icon: Icons.payments_outlined,
      color: AppColors.primaryYellow,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  void _skip() {
    // Navigate to login
    Navigator.of(context).pushReplacementNamed('/login');
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text('Skip'),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  activeDotColor: AppColors.primaryGreen,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 12,
                ),
              ),
            ),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: PrimaryButton(
                text: _currentPage == _pages.length - 1 
                    ? 'Get Started' 
                    : 'Next',
                onPressed: _nextPage,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ).animate()
              .scale(delay: 200.ms, duration: 400.ms)
              .fadeIn(),
          
          const SizedBox(height: AppSpacing.massive),
          
          // Title
          Text(
            page.title,
            style: TextStyles.displaySmall,
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.2, end: 0, delay: 300.ms),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Description
          Text(
            page.description,
            style: TextStyles.bodyLarge.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
