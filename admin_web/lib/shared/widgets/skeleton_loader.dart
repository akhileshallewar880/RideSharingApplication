import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Skeleton for card layouts
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  
  const SkeletonCard({
    super.key,
    this.width,
    this.height = 150,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 120, height: 16),
            const SizedBox(height: 12),
            SkeletonLoader(height: height - 60),
            const SizedBox(height: 12),
            const SkeletonLoader(width: 80, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for data table rows
class SkeletonTableRow extends StatelessWidget {
  final int columns;
  
  const SkeletonTableRow({
    super.key,
    this.columns = 5,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(
          columns,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SkeletonLoader(
                height: 16,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  
  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 200, height: 16),
                SizedBox(height: 8),
                SkeletonLoader(width: 150, height: 14),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const SkeletonLoader(width: 80, height: 32),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for dashboard stat cards
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(width: 100, height: 14),
                SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
              ],
            ),
            SizedBox(height: 16),
            SkeletonLoader(width: 80, height: 32),
            SizedBox(height: 8),
            SkeletonLoader(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for page loading
class SkeletonPageLoader extends StatelessWidget {
  final int cardCount;
  final int tableRows;
  
  const SkeletonPageLoader({
    super.key,
    this.cardCount = 4,
    this.tableRows = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const SkeletonLoader(width: 200, height: 28),
          const SizedBox(height: 24),
          
          // Stats cards skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
            ),
            itemCount: cardCount,
            itemBuilder: (context, index) => const SkeletonStatCard(),
          ),
          
          const SizedBox(height: 32),
          
          // Table skeleton
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonLoader(width: 150, height: 20),
                      SkeletonLoader(width: 200, height: 40),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...List.generate(
                  tableRows,
                  (index) => Column(
                    children: const [
                      SkeletonTableRow(),
                      Divider(height: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
