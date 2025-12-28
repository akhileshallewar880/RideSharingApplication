import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double? childAspectRatio;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.responsiveValue(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
      largeDesktop: largeDesktopColumns ?? 4,
    );
    
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio ?? _getDefaultAspectRatio(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
  
  double _getDefaultAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return 1.5;
    } else if (ResponsiveHelper.isTablet(context)) {
      return 1.3;
    } else {
      return 1.2;
    }
  }
}

class ResponsiveGridBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double? childAspectRatio;
  
  const ResponsiveGridBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.responsiveValue(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
      largeDesktop: largeDesktopColumns ?? 4,
    );
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio ?? _getDefaultAspectRatio(context),
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
  
  double _getDefaultAspectRatio(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return 1.5;
    } else if (ResponsiveHelper.isTablet(context)) {
      return 1.3;
    } else {
      return 1.2;
    }
  }
}
