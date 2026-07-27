import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';
import 'package:cashspark/presentation/providers/coupon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CouponsMarketplaceScreen extends StatefulWidget {
  const CouponsMarketplaceScreen({super.key});

  @override
  State<CouponsMarketplaceScreen> createState() =>
      _CouponsMarketplaceScreenState();
}

class _CouponsMarketplaceScreenState extends State<CouponsMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().listenToCoupons();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Coupons Marketplace',
        onBack: () => Navigator.pop(context),
      ),
      body: Consumer<CouponProvider>(
        builder: (context, couponProv, _) {
          if (couponProv.isLoading && couponProv.coupons.isEmpty) {
            return const PremiumLoader(message: 'Loading coupons...');
          }

          final coupons = couponProv.coupons;
          final categories = ['All', ...couponProv.categories];

          // If coupons list is empty after loading
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64,
                      color: isDark
                          ? AppTheme.textMuted.withValues(alpha: 0.3)
                          : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No coupons available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for exclusive deals!',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category chips
              _buildCategoryChips(categories, isDark, couponProv),

              // Featured section (if any)
              if (couponProv.featuredCoupons.isNotEmpty)
                _buildFeaturedSection(couponProv.featuredCoupons, isDark),

              // Coupons list by category
              Expanded(
                child: _selectedCategory == 'All'
                    ? _buildAllCategories(coupons, isDark, couponProv)
                    : _buildCategoryCoupons(
                        couponProv.getCouponsByCategory(_selectedCategory),
                        _selectedCategory,
                        isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(
      List<String> categories, bool isDark, CouponProvider couponProv) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected
                    ? AppTheme.accentGreen
                    : (isDark
                        ? AppTheme.bgCardLight
                        : const Color(0xFFF1F5F9)),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentGreen
                      : (isDark
                          ? AppTheme.borderColor.withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.black
                        : (isDark
                            ? AppTheme.textSecondary
                            : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(
      List<CouponEntity> featured, bool isDark) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  'Featured Deals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _buildFeaturedCard(featured[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(CouponEntity coupon, bool isDark) {
    return GestureDetector(
      onTap: () => _claimCoupon(coupon),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: coupon.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.local_offer_outlined,
                          size: 16, color: Colors.white,
                        ),
                        placeholder: (_, __) => const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coupon.brandName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                coupon.discountText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                coupon.offerTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Claim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build all categories in a vertical list
  Widget _buildAllCategories(
      List<CouponEntity> coupons, bool isDark, CouponProvider couponProv) {
    final categories = couponProv.categories;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryCoupons = couponProv.getCouponsByCategory(category);
        return _buildCategorySection(category, categoryCoupons, isDark);
      },
    );
  }

  Widget _buildCategoryCoupons(
      List<CouponEntity> coupons, String category, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: coupons.length,
      itemBuilder: (context, index) => _buildCouponCard(coupons[index], isDark),
    );
  }

  Widget _buildCategorySection(
      String category, List<CouponEntity> coupons, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(_categoryIcon(category), size: 18, color: AppTheme.accentGreen),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${coupons.length} offer${coupons.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        ...coupons.map((coupon) => _buildCouponCard(coupon, isDark)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCouponCard(CouponEntity coupon, bool isDark) {
    return GestureDetector(
      onTap: () => _claimCoupon(coupon),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppTheme.bgCard : Colors.white,
          border: Border.all(
            color: isDark
                ? AppTheme.borderColor.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Coupon image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: coupon.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.local_offer_outlined,
                      size: 28,
                      color: AppTheme.accentGreen.withValues(alpha: 0.5),
                    ),
                    placeholder: (_, __) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Coupon details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            coupon.brandName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),
                        if (coupon.isFeatured) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              size: 12, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.offerTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (coupon.shortDescription != null &&
                        coupon.shortDescription!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        coupon.shortDescription!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.textMuted
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      coupon.discountText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Claim button (green, only one)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Colors.black),
                    SizedBox(width: 3),
                    Text(
                      'Claim',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimCoupon(CouponEntity coupon) async {
    HapticFeedback.mediumImpact();

    final url = coupon.destinationUrl.trim();
    if (url.isEmpty) {
      _showUnavailableSnackBar();
      return;
    }

    // Validate URL
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _showUnavailableSnackBar();
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showUnavailableSnackBar();
      }
    } catch (e) {
      _showUnavailableSnackBar();
    }
  }

  void _showUnavailableSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This offer is currently unavailable.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'amazon':
        return Icons.shopping_bag_outlined;
      case 'flipkart':
        return Icons.shopping_cart_outlined;
      case 'myntra':
      case 'ajio':
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'nykaa':
      case 'beauty':
        return Icons.face_outlined;
      case 'electronics':
        return Icons.devices_other_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'travel':
        return Icons.flight_takeoff_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }
}
