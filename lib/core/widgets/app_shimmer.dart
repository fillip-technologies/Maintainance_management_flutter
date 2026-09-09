import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';

/// Centralized theme-aware shimmer effect wrapper.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Duration period;

  const AppShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF0F1D38) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF1E3A66) : const Color(0xFFF8FAFC),
      period: period,
      child: child,
    );
  }
}

/// A basic placeholder element with customizable width, height, and border radius.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
      ),
    );
  }
}

/// Shimmer skeleton matching the 2-column EquipmentCategoryCard grid.
class EquipmentCategoryGridSkeleton extends StatelessWidget {
  final int itemCount;

  const EquipmentCategoryGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 126,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 44, height: 44, borderRadius: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 2),
                        ShimmerBox(width: 65, height: 13, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 32, height: 15, borderRadius: 10),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  ShimmerBox(width: 42, height: 16, borderRadius: 6),
                  SizedBox(width: 4),
                  ShimmerBox(width: 42, height: 16, borderRadius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton matching the flat list of DeviceItemCard.
class EquipmentListSkeleton extends StatelessWidget {
  final int itemCount;

  const EquipmentListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const ShimmerBox(width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 130, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 11, borderRadius: 4),
                  ],
                ),
              ),
              const ShimmerBox(width: 52, height: 22, borderRadius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton matching StaffDeviceCheckCard in the checklist tab.
class StaffChecklistSkeleton extends StatelessWidget {
  final int itemCount;

  const StaffChecklistSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerBox(width: 42, height: 42, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 140, height: 15, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 90, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  const ShimmerBox(width: 54, height: 20, borderRadius: 10),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: ShimmerBox(height: 38, borderRadius: 12)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 38, borderRadius: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton matching IssueCard in issue lists.
class IssuesListSkeleton extends StatelessWidget {
  final int itemCount;

  const IssuesListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(width: 70, height: 18, borderRadius: 8),
                  ShimmerBox(width: 55, height: 12, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 10),
              const ShimmerBox(width: 170, height: 15, borderRadius: 4),
              const SizedBox(height: 6),
              const ShimmerBox(width: 240, height: 12, borderRadius: 4),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(width: 100, height: 16, borderRadius: 6),
                  ShimmerBox(width: 60, height: 20, borderRadius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for Technician Zone Tree Explorer view.
class ZoneTreeSkeleton extends StatelessWidget {
  const ZoneTreeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Bar placeholder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tree node skeletons
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    ShimmerBox(width: 36, height: 36, borderRadius: 10),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 130, height: 14, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 80, height: 11, borderRadius: 4),
                        ],
                      ),
                    ),
                    ShimmerBox(width: 48, height: 20, borderRadius: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for Technician Zone Status Table view.
class ZoneStatusTableSkeleton extends StatelessWidget {
  const ZoneStatusTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
                ShimmerBox(width: 75, height: 36, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const ShimmerBox(width: double.infinity, height: 32, borderRadius: 8),
                const SizedBox(height: 12),
                ...List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: const [
                        ShimmerBox(width: 32, height: 32, borderRadius: 8),
                        SizedBox(width: 10),
                        Expanded(child: ShimmerBox(height: 14, borderRadius: 4)),
                        SizedBox(width: 10),
                        ShimmerBox(width: 40, height: 14, borderRadius: 4),
                        SizedBox(width: 10),
                        ShimmerBox(width: 40, height: 14, borderRadius: 4),
                      ],
                    ),
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

/// Shimmer skeleton for Profile page initial loading.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: ShimmerBox(width: 80, height: 80, shape: BoxShape.circle),
          ),
          const SizedBox(height: 16),
          const Center(child: ShimmerBox(width: 140, height: 16, borderRadius: 6)),
          const SizedBox(height: 8),
          const Center(child: ShimmerBox(width: 180, height: 12, borderRadius: 4)),
          const SizedBox(height: 28),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    ShimmerBox(width: 24, height: 24, borderRadius: 6),
                    SizedBox(width: 14),
                    Expanded(child: ShimmerBox(height: 14, borderRadius: 4)),
                    ShimmerBox(width: 36, height: 20, borderRadius: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
