import 'package:flutter/material.dart';

/// A widget that paints a shimmering gradient overlay on its child.
/// Used to create skeleton loading placeholders.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                (0.5 + _animation.value * 0.25).clamp(0.0, 1.0),
                (0.6 + _animation.value * 0.25).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// A convenience widget that renders a rounded rectangle skeleton
/// with shimmer animation.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A circular skeleton with shimmer animation.
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A convenience widget that renders a rounded row skeleton for
/// offer cards.
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 12),
      child: const SkeletonBox(
        height: 180,
        borderRadius: 24,
      ),
    );
  }
}

/// A skeleton for the featured offers section header + page view.
class FeaturedOffersSkeleton extends StatelessWidget {
  const FeaturedOffersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: SkeletonBox(
              width: 160,
              height: 20,
              borderRadius: 6,
            ),
          ),
          // Offer card skeleton
          SizedBox(
            height: 180,
            child: ShimmerLoading(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A3350)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Dots indicator skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == 0 ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for a single project grid card.
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon skeleton
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Spacer(),
                  // Category badge skeleton
                  Container(
                    width: 50,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name skeleton
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Reward skeleton
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              // Button skeleton
              Container(
                width: double.infinity,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton for notification tile rows.
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A3350)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonCircle(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 200, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12, width: double.infinity, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 100, borderRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// A skeleton row for the leaderboard list (used in loading state).
class LeaderboardRowSkeleton extends StatelessWidget {
  const LeaderboardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              // Rank number
              SkeletonBox(width: 28, height: 14, borderRadius: 4),
              SizedBox(width: 8),
              // Avatar circle
              SkeletonCircle(size: 36),
              SizedBox(width: 10),
              // Name
              Expanded(
                child: SkeletonBox(height: 14, width: 120, borderRadius: 4),
              ),
              SizedBox(width: 8),
              // Earnings
              SkeletonBox(height: 14, width: 60, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton that mimics the Wallet dashboard layout.
class WalletDashboardSkeleton extends StatelessWidget {
  const WalletDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance card skeleton
        ShimmerLoading(
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3350)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Stats row skeleton
        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
        const SizedBox(height: 16),
        // Earnings breakdown skeleton
        ShimmerLoading(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3350)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Search bar skeleton
        ShimmerLoading(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3350)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Section header skeleton
        const SkeletonBox(height: 18, width: 180, borderRadius: 6),
        const SizedBox(height: 16),
        // Transaction row skeletons
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _TransactionRowSkeleton(),
        )),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A3350)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _TransactionRowSkeleton extends StatelessWidget {
  const _TransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A3350)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 140, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(height: 12, width: double.infinity, borderRadius: 4),
                  SizedBox(height: 4),
                  SkeletonBox(height: 10, width: 80, borderRadius: 3),
                ],
              ),
            ),
            SizedBox(width: 8),
            SkeletonBox(height: 16, width: 70, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// A skeleton card matching the featured projects carousel layout.
class FeaturedProjectCardSkeleton extends StatelessWidget {
  const FeaturedProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);
    final shimmerBorder = isDark
        ? const Color(0xFF4ADE80).withValues(alpha: 0.1)
        : const Color(0xFF4ADE80).withValues(alpha: 0.15);

    return ShimmerLoading(
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: shimmerBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Star icon + FEATURED badge row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title skeleton
              Container(
                width: 160,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              // Category skeleton
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              // Reward row skeleton
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Timer row skeleton
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
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
}

/// A skeleton that mimics the Rewards screen layout (streak card, ad card,
/// daily tasks header + rows, reward history header + rows).
class RewardsScreenSkeleton extends StatelessWidget {
  const RewardsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak card skeleton
        ShimmerLoading(
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3350)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Ad reward card skeleton
        ShimmerLoading(
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A3350)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Daily Tasks section header
        const SkeletonBox(height: 18, width: 140, borderRadius: 6),
        const SizedBox(height: 12),
        // Daily task rows
        ...List.generate(2, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _RewardsTaskRowSkeleton(),
        )),
        const SizedBox(height: 24),
        // Reward History section header
        const SkeletonBox(height: 18, width: 160, borderRadius: 6),
        const SizedBox(height: 12),
        // Reward history rows
        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: _RewardHistoryRowSkeleton(),
        )),
      ],
    );
  }
}

class _RewardsTaskRowSkeleton extends StatelessWidget {
  const _RewardsTaskRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A3350)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14, width: 160, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(height: 10, width: double.infinity, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonBox(height: 6, width: double.infinity, borderRadius: 3),
                ],
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(height: 16, width: 50, borderRadius: 4),
                  SizedBox(height: 4),
                  SkeletonBox(height: 22, width: 50, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardHistoryRowSkeleton extends StatelessWidget {
  const _RewardHistoryRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A3350)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SkeletonCircle(size: 36),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 14, width: 120, borderRadius: 4)),
            SizedBox(width: 8),
            SkeletonBox(height: 16, width: 70, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// A skeleton search bar that mimics the search input field layout.
class SearchBarSkeleton extends StatelessWidget {
  const SearchBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ShimmerLoading(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Search icon placeholder
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Text line placeholder
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton sort bar that mimics the sort dropdown and project count layout.
class SortBarSkeleton extends StatelessWidget {
  const SortBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Sort dropdown placeholder
          ShimmerLoading(
            child: Container(
              width: 100,
              height: 32,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Project count placeholder
          ShimmerLoading(
            child: Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton row of filter chips matching the category chip layout.
class FilterChipsSkeleton extends StatelessWidget {
  const FilterChipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A3350) : const Color(0xFFE2E8F0);

    // Widths that roughly match common category label lengths
    const chipWidths = [68.0, 80.0, 72.0, 56.0, 64.0, 76.0];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(chipWidths.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShimmerLoading(
              child: Container(
                width: chipWidths[index],
                height: 34,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: chipWidths[index] * 0.55,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Empty state displayed when the featured projects list is empty
/// and the app is not loading.
class FeaturedProjectsEmptyState extends StatelessWidget {
  const FeaturedProjectsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 80,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F2740).withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_outline_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                'No featured projects at the moment',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state displayed in the project grid when no projects match
/// the current filters and the app is not loading.
class ProjectsEmptyState extends StatelessWidget {
  const ProjectsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined,
              size: 48,
              color:
                  isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different category or search term',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton grid for top projects section.
class TopProjectsSkeleton extends StatelessWidget {
  const TopProjectsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + "See All" skeleton
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                  width: 120,
                  height: 20,
                  borderRadius: 6,
                ),
                SkeletonBox(
                  width: 50,
                  height: 16,
                  borderRadius: 6,
                ),
              ],
            ),
          ),
          // Grid skeleton — 2 columns, 2 rows
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const ProjectCardSkeleton();
            },
          ),
        ],
      ),
    );
  }
}
