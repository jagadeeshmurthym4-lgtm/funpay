import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';
import 'package:cashspark/presentation/providers/coupon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

enum _CouponSort { newest, oldest, nameAZ, nameZA, sortOrder }

class AdminCouponsTab extends StatefulWidget {
  const AdminCouponsTab({super.key});

  @override
  State<AdminCouponsTab> createState() => _AdminCouponsTabState();
}

class _AdminCouponsTabState extends State<AdminCouponsTab> {
  // ─── Form Controllers ──────────────────────────────────────
  final _brandNameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _offerTitleCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _discountTextCtrl = TextEditingController();
  final _destinationUrlCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  bool _isFeatured = false;
  bool _isActive = true;
  DateTime? _expiryDate;
  bool _showForm = false;
  bool _isEditing = false;
  String? _editingCouponId;
  String _imagePreviewUrl = '';

  // ─── Search & Filters ─────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'All'; // All, Active, Inactive, Expired
  String _categoryFilter = 'All';
  _CouponSort _sortBy = _CouponSort.newest;

  // ─── Pagination ─────────────────────────────────────────
  int _currentPage = 1;
  int _pageSize = 20;
  int get _totalPages => _pageSize > 0 ? ((_filteredLength + _pageSize - 1) ~/ _pageSize) : 1;
  int _filteredLength = 0; // updated whenever filtered list changes

  // Common categories
  final List<String> _suggestedCategories = [
    'Amazon', 'Flipkart', 'Myntra', 'AJIO', 'Nykaa',
    'Electronics', 'Fashion', 'Beauty', 'Food', 'Travel',
  ];

  @override
  void initState() {
    super.initState();
    _imageUrlCtrl.addListener(_onImageUrlChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().loadAllCoupons();
    });
  }

  void _onImageUrlChanged() {
    final url = _imageUrlCtrl.text.trim();
    if (url != _imagePreviewUrl) {
      setState(() => _imagePreviewUrl = url);
    }
  }

  void _resetPage() => _currentPage = 1;

  @override
  void dispose() {
    _brandNameCtrl.dispose();
    _categoryCtrl.dispose();
    _offerTitleCtrl.dispose();
    _shortDescCtrl.dispose();
    _discountTextCtrl.dispose();
    _destinationUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    _sortOrderCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _brandNameCtrl.clear();
    _categoryCtrl.clear();
    _offerTitleCtrl.clear();
    _shortDescCtrl.clear();
    _discountTextCtrl.clear();
    _destinationUrlCtrl.clear();
    _imageUrlCtrl.clear();
    _sortOrderCtrl.text = '0';
    _isFeatured = false;
    _isActive = true;
    _expiryDate = null;
    _isEditing = false;
    _editingCouponId = null;
    _imagePreviewUrl = '';
  }

  void _populateForm(CouponEntity coupon) {
    _brandNameCtrl.text = coupon.brandName;
    _categoryCtrl.text = coupon.category;
    _offerTitleCtrl.text = coupon.offerTitle;
    _shortDescCtrl.text = coupon.shortDescription ?? '';
    _discountTextCtrl.text = coupon.discountText;
    _destinationUrlCtrl.text = coupon.destinationUrl;
    _imageUrlCtrl.text = coupon.imageUrl;
    _sortOrderCtrl.text = coupon.sortOrder.toString();
    _isFeatured = coupon.isFeatured;
    _isActive = coupon.isActive;
    _expiryDate = coupon.expiryDate;
    _isEditing = true;
    _editingCouponId = coupon.couponId;
    _imagePreviewUrl = coupon.imageUrl;
    setState(() => _showForm = true);
  }

  // ─── Filtered Coupons ─────────────────────────────────────
  List<CouponEntity> _getFilteredCoupons(List<CouponEntity> all) {
    var filtered = List<CouponEntity>.from(all);

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) =>
        c.brandName.toLowerCase().contains(query) ||
        c.offerTitle.toLowerCase().contains(query) ||
        c.discountText.toLowerCase().contains(query) ||
        c.category.toLowerCase().contains(query)
      ).toList();
    }

    // Status filter
    if (_statusFilter != 'All') {
      final now = DateTime.now();
      switch (_statusFilter) {
        case 'Active':
          filtered = filtered.where((c) =>
            c.isActive && (c.expiryDate == null || !c.expiryDate!.isBefore(now))
          ).toList();
          break;
        case 'Inactive':
          filtered = filtered.where((c) => !c.isActive).toList();
          break;
        case 'Expired':
          filtered = filtered.where((c) =>
            c.expiryDate != null && c.expiryDate!.isBefore(now)
          ).toList();
          break;
      }
    }

    // Category filter
    if (_categoryFilter != 'All') {
      filtered = filtered.where((c) => c.category == _categoryFilter).toList();
    }

    // Sort
    switch (_sortBy) {
      case _CouponSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _CouponSort.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _CouponSort.nameAZ:
        filtered.sort((a, b) => a.brandName.compareTo(b.brandName));
        break;
      case _CouponSort.nameZA:
        filtered.sort((a, b) => b.brandName.compareTo(a.brandName));
        break;
      case _CouponSort.sortOrder:
        filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
    }

    _filteredLength = filtered.length;
    return filtered;
  }

  // ─── Stats ─────────────────────────────────────────────────
  Map<String, int> _computeStats(List<CouponEntity> all) {
    final now = DateTime.now();
    final total = all.length;
    final active = all.where((c) =>
      c.isActive && (c.expiryDate == null || !c.expiryDate!.isBefore(now))
    ).length;
    final inactive = all.where((c) => !c.isActive).length;
    final expired = all.where((c) =>
      c.expiryDate != null && c.expiryDate!.isBefore(now)
    ).length;
    final featured = all.where((c) => c.isFeatured).length;
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'expired': expired,
      'featured': featured,
    };
  }

  // ─── Categories available ──────────────────────────────────
  List<String> _getAvailableCategories(List<CouponEntity> all) {
    final cats = all.map((c) => c.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<CouponProvider>(
      builder: (context, couponProv, _) {
        // Show success/error messages
        if (couponProv.successMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(couponProv.successMessage!),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              couponProv.clearSuccess();
            }
          });
        }
        if (couponProv.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(couponProv.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              couponProv.clearError();
            }
          });
        }

        final allCoupons = couponProv.allCoupons;
        final stats = _computeStats(allCoupons);
        final filtered = _getFilteredCoupons(allCoupons);
        final categories = _getAvailableCategories(allCoupons);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coupon Management',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '${stats['total']} coupons total',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _showForm = !_showForm;
                        if (!_showForm) _resetForm();
                      });
                    },
                    icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                    label: Text(_showForm ? 'Cancel' : 'New Coupon'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _showForm ? null : AppTheme.accentGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Stats Cards ──────────────────────────────
              _buildStatsRow(stats, theme),

              const SizedBox(height: 12),

              // ─── Search & Filters ─────────────────────────
              _buildSearchAndFilters(theme, isDark, categories),

              const SizedBox(height: 12),

              // ─── Add/Edit Form ────────────────────────────
              if (_showForm) ...[
                _buildForm(theme, isDark, couponProv),
                const SizedBox(height: 16),
              ],

              // ─── Results Count ────────────────────────────
              Row(
                children: [
                  Text(
                    '${filtered.length} coupon${filtered.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_searchCtrl.text.isNotEmpty || _statusFilter != 'All' || _categoryFilter != 'All')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchCtrl.clear();
                          _statusFilter = 'All';
                          _categoryFilter = 'All';
                          _resetPage();
                        });
                      },
                      child: Text(
                        'Clear filters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ─── Coupons List ─────────────────────────────
              if (couponProv.isLoading && allCoupons.isEmpty)
                const SizedBox(
                  height: 200,
                  child: PremiumLoader(message: 'Loading coupons...'),
                )
              else if (filtered.isEmpty)
                _buildEmptyState(theme, allCoupons.isEmpty)
              else
                ..._getPagedCoupons(filtered).map((coupon) => _CouponAdminCard(
                      coupon: coupon,
                      theme: theme,
                      isDark: isDark,
                      couponProv: couponProv,
                      onEdit: () => _populateForm(coupon),
                      onViewMarketplace: () => _showMarketplacePreview(coupon, isDark, theme),
                    )),

              // ─── Pagination ────────────────────────────────
              if (_totalPages > 1 || filtered.length > _pageSize)
                _buildPagination(theme, isDark),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ─── Stats Row ──────────────────────────────────────────────
  Widget _buildStatsRow(Map<String, int> stats, ThemeData theme) {
    final cards = [
      _StatItem(label: 'Total', value: stats['total']!, icon: Icons.local_offer_outlined, color: AppTheme.accentBlue),
      _StatItem(label: 'Active', value: stats['active']!, icon: Icons.check_circle_outline, color: AppTheme.accentGreen),
      _StatItem(label: 'Inactive', value: stats['inactive']!, icon: Icons.pause_circle_outline, color: AppTheme.accentOrange),
      _StatItem(label: 'Expired', value: stats['expired']!, icon: Icons.timer_off_outlined, color: theme.colorScheme.error),
      _StatItem(label: 'Featured', value: stats['featured']!, icon: Icons.star_rounded, color: AppTheme.accentPurple),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = cards[index];
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.color.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(c.icon, size: 13, color: c.color),
                    const SizedBox(width: 4),
                    Text(c.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: c.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.value}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: c.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Search & Filters ──────────────────────────────────────
  Widget _buildSearchAndFilters(ThemeData theme, bool isDark, List<String> categories) {
    return Column(
      children: [
        // Search bar
        PremiumGlass(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          borderRadius: 14,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() => _resetPage()),
            decoration: InputDecoration(
              hintText: 'Search by brand, offer, or category...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _resetPage());
                      },
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Status & Sort filters
        Row(
          children: [
            // Status filter chips
            Expanded(
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final statuses = ['All', 'Active', 'Inactive', 'Expired'];
                    final status = statuses[index];
                    final isSelected = _statusFilter == status;
                    Color? chipColor;
                    switch (status) {
                      case 'Active': chipColor = AppTheme.accentGreen; break;
                      case 'Inactive': chipColor = AppTheme.accentOrange; break;
                      case 'Expired': chipColor = theme.colorScheme.error; break;
                      default: chipColor = AppTheme.accentBlue;
                    }
                    return GestureDetector(
                      onTap: () => setState(() {
                        _statusFilter = status;
                        _resetPage();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? chipColor
                                : (isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? chipColor
                                : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sort dropdown
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1),
                  width: 0.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_CouponSort>(
                  value: _sortBy,
                  isDense: true,
                  items: [
                    DropdownMenuItem(value: _CouponSort.newest, child: Text('Newest', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                    DropdownMenuItem(value: _CouponSort.oldest, child: Text('Oldest', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                    DropdownMenuItem(value: _CouponSort.nameAZ, child: Text('A-Z', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                    DropdownMenuItem(value: _CouponSort.nameZA, child: Text('Z-A', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                    DropdownMenuItem(value: _CouponSort.sortOrder, child: Text('Sort Order', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _sortBy = v;
                        _resetPage();
                      });
                    }
                  },
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),

        // Category filter chips (if categories exist)
        if (categories.length > 1) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _categoryFilter == cat;
                return GestureDetector(
                  onTap: () => setState(() {
                    _categoryFilter = cat;
                    _resetPage();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentPurple.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentPurple
                            : (isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.accentPurple
                            : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ─── Form ──────────────────────────────────────────────────
  Widget _buildForm(ThemeData theme, bool isDark, CouponProvider couponProv) {
    return PremiumGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
                  size: 18, color: AppTheme.accentGreen),
              const SizedBox(width: 8),
              Text(
                _isEditing ? 'Edit Coupon' : 'Add New Coupon',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isEditing)
                GestureDetector(
                  onTap: () => setState(() {
                    _resetForm();
                    _showForm = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Cancel Edit',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 1: Brand Name & Category
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brandNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name *',
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Amazon',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Amazon',
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final cat = _suggestedCategories[index];
                          final isSelected = _categoryCtrl.text == cat;
                          return GestureDetector(
                            onTap: () => _categoryCtrl.text = cat,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentGreen
                                      : (isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.accentGreen
                                      : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Offer Title & Discount Text
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _offerTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Offer Title *',
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Up to 50% Off',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _discountTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Discount Text *',
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Min 50% Off',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Short Description
          TextField(
            controller: _shortDescCtrl,
            decoration: const InputDecoration(
              labelText: 'Short Description (optional)',
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'e.g. Exclusive deals on electronics',
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 10),

          // Row 3: Image URL & Destination URL
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL *',
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'https://...',
                      ),
                    ),
                    if (_imagePreviewUrl.isNotEmpty && _isValidUrl(_imagePreviewUrl))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildImagePreview(isDark, theme),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _destinationUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Destination URL *',
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 4: Sort Order & Expiry Date
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickExpiryDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: _expiryDate != null
                            ? 'Expiry: ${_formatDate(_expiryDate!)}'
                            : 'Expiry Date (optional)',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.date_range_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_expiryDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _expiryDate = null),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggles
          Row(
            children: [
              _buildToggle('Featured', _isFeatured, (v) {
                setState(() => _isFeatured = v);
              }, AppTheme.accentOrange, theme),
              const SizedBox(width: 16),
              _buildToggle('Active', _isActive, (v) {
                setState(() => _isActive = v);
              }, AppTheme.accentGreen, theme),
            ],
          ),
          const SizedBox(height: 16),

          // Submit button
          GradientButton(
            onPressed: couponProv.isLoading
                ? null
                : () => _submitCoupon(couponProv),
            label: _isEditing ? 'Update Coupon' : 'Create Coupon',
            icon: _isEditing
                ? Icons.save_outlined
                : Icons.add_circle_outline,
            gradient: const LinearGradient(
              colors: [AppTheme.accentGreen, Color(0xFF43A047)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
      String label, bool value, ValueChanged<bool> onChanged, Color color, ThemeData theme) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? color : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: value ? color : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool noCouponsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              noCouponsAtAll ? Icons.local_offer_outlined : Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              noCouponsAtAll ? 'No coupons yet' : 'No coupons match your filters',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              noCouponsAtAll
                  ? 'Create your first coupon to get started'
                  : 'Try adjusting your search or filter criteria',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ─── URL & Preview Helpers ─────────────────────────────────
  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Widget _buildImagePreview(bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showFullImagePreview(context, isDark),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? AppTheme.borderColor.withValues(alpha: 0.5)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
          ),
          color: isDark ? const Color(0xFF0A1E36) : const Color(0xFFF8FAFC),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _imagePreviewUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        size: 28, color: theme.colorScheme.error.withValues(alpha: 0.6)),
                    const SizedBox(height: 4),
                    Text('Invalid image',
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.error.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              placeholder: (_, __) => Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accentGreen.withValues(alpha: 0.5)),
                ),
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 10, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text('Preview',
                      style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImagePreview(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: _imagePreviewUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: 300,
                errorWidget: (_, __, ___) => Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                placeholder: (_, __) => Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Marketplace Preview ─────────────────────────────────
  void _showMarketplacePreview(CouponEntity coupon, bool isDark, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.accentGreen),
                    const SizedBox(width: 6),
                    Text('Marketplace Preview',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Preview card (matches marketplace style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? const Color(0xFF0A1E36) : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isDark ? AppTheme.borderColor.withValues(alpha: 0.4) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 64, height: 64,
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
                                Icons.local_offer_outlined, size: 28,
                                color: AppTheme.accentGreen.withValues(alpha: 0.5),
                              ),
                              placeholder: (_, __) => const SizedBox(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(coupon.brandName,
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.accentGreen)),
                                  ),
                                  if (coupon.isFeatured) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(coupon.offerTitle,
                                style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              if (coupon.shortDescription != null && coupon.shortDescription!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(coupon.shortDescription!,
                                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(coupon.discountText,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                blurRadius: 8, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Colors.black),
                              SizedBox(width: 3),
                              Text('Claim',
                                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Coupon details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _previewDetailRow('Category', coupon.category, isDark),
                    _previewDetailRow('Sort Order', '${coupon.sortOrder}', isDark),
                    _previewDetailRow('Created', _formatDate(coupon.createdAt), isDark),
                    _previewDetailRow('Expiry',
                      coupon.expiryDate != null ? _formatDate(coupon.expiryDate!) : 'No expiry', isDark),
                    _previewDetailRow('Status', coupon.isActive ? 'Active' : 'Inactive', isDark,
                      valueColor: coupon.isActive ? AppTheme.accentGreen : theme.colorScheme.error),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewDetailRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
          Text(value,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            )),
        ],
      ),
    );
  }

  // ─── Date Picker ──────────────────────────────────────────
  Future<void> _pickExpiryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ─── Paged Coupons ──────────────────────────────────────
  List<CouponEntity> _getPagedCoupons(List<CouponEntity> filtered) {
    // Clamp current page to valid range
    if (_currentPage < 1) _currentPage = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;

    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  // ─── Pagination Bar ───────────────────────────────────────
  Widget _buildPagination(ThemeData theme, bool isDark) {
    // Calculate visible page numbers (show max 5 pages)
    final totalPages = _totalPages;
    int startPage = (_currentPage - 2).clamp(1, totalPages);
    int endPage = (startPage + 4).clamp(1, totalPages);
    if (endPage - startPage < 4 && startPage > 1) {
      startPage = (endPage - 4).clamp(1, totalPages);
    }
    final pageNumbers = List.generate(endPage - startPage + 1, (i) => startPage + i);

    return Column(
      children: [
        const SizedBox(height: 12),
        // Page info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page $_currentPage of $totalPages',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            // Page size selector
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Per page: ',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1),
                      width: 0.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _pageSize,
                      isDense: true,
                      items: [10, 20, 50].map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text('$size', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _pageSize = v;
                            _resetPage();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Page number buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            _PageButton(
              icon: Icons.chevron_left_rounded,
              enabled: _currentPage > 1,
              onPressed: () => setState(() => _currentPage--),
            ),
            const SizedBox(width: 4),
            // Page numbers
            ...pageNumbers.map((page) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PageNumber(
                page: page,
                isActive: page == _currentPage,
                onPressed: () => setState(() => _currentPage = page),
                isDark: isDark,
              ),
            )),
            const SizedBox(width: 4),
            // Next button
            _PageButton(
              icon: Icons.chevron_right_rounded,
              enabled: _currentPage < totalPages,
              onPressed: () => setState(() => _currentPage++),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Submit Form ──────────────────────────────────────────
  Future<void> _submitCoupon(CouponProvider couponProv) async {
    if (_brandNameCtrl.text.trim().isEmpty ||
        _categoryCtrl.text.trim().isEmpty ||
        _offerTitleCtrl.text.trim().isEmpty ||
        _discountTextCtrl.text.trim().isEmpty ||
        _destinationUrlCtrl.text.trim().isEmpty ||
        _imageUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (*)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    bool success;
    if (_isEditing && _editingCouponId != null) {
      final updated = CouponEntity(
        couponId: _editingCouponId!,
        brandName: _brandNameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        offerTitle: _offerTitleCtrl.text.trim(),
        shortDescription: _shortDescCtrl.text.trim().isNotEmpty
            ? _shortDescCtrl.text.trim() : null,
        discountText: _discountTextCtrl.text.trim(),
        destinationUrl: _destinationUrlCtrl.text.trim(),
        imageUrl: _imageUrlCtrl.text.trim(),
        expiryDate: _expiryDate,
        isFeatured: _isFeatured,
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderCtrl.text) ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await couponProv.updateCoupon(updated);
    } else {
      success = await couponProv.createCoupon(
        brandName: _brandNameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        offerTitle: _offerTitleCtrl.text.trim(),
        shortDescription: _shortDescCtrl.text.trim().isNotEmpty
            ? _shortDescCtrl.text.trim() : null,
        discountText: _discountTextCtrl.text.trim(),
        destinationUrl: _destinationUrlCtrl.text.trim(),
        imageUrl: _imageUrlCtrl.text.trim(),
        expiryDate: _expiryDate,
        isFeatured: _isFeatured,
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderCtrl.text) ?? 0,
      );
    }

    if (success && mounted) {
      _resetForm();
      setState(() => _showForm = false);
      HapticFeedback.lightImpact();
    }
  }
}

// ════════════════════════════════════════════════════════════
// STAT ITEM DATA CLASS
// ════════════════════════════════════════════════════════════
class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
}

// ════════════════════════════════════════════════════════════
// COUPON ADMIN CARD
// ════════════════════════════════════════════════════════════
class _CouponAdminCard extends StatelessWidget {
  final CouponEntity coupon;
  final ThemeData theme;
  final bool isDark;
  final CouponProvider couponProv;
  final VoidCallback onEdit;
  final VoidCallback onViewMarketplace;

  const _CouponAdminCard({
    required this.coupon,
    required this.theme,
    required this.isDark,
    required this.couponProv,
    required this.onEdit,
    required this.onViewMarketplace,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = coupon.expiryDate != null && coupon.expiryDate!.isBefore(DateTime.now());

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Main Row ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coupon image
              Container(
                width: 52, height: 52,
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
                      Icons.local_offer_outlined, size: 24,
                      color: AppTheme.accentGreen.withValues(alpha: 0.4),
                    ),
                    placeholder: (_, __) => const SizedBox(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand + badges
                    Row(
                      children: [
                        Text(
                          coupon.brandName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(label: coupon.category, color: AppTheme.accentPurple, fontSize: 8, horizontalPadding: 5),
                        if (coupon.isFeatured) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        ],
                        if (isExpired) ...[
                          const SizedBox(width: 4),
                          StatusBadge(label: 'Expired', color: theme.colorScheme.error, fontSize: 8, horizontalPadding: 5),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.offerTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    // Discount + status indicator
                    Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 12, color: AppTheme.accentGreen),
                        const SizedBox(width: 4),
                        Text(
                          coupon.discountText,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentGreen,
                          ),
                        ),
                        const Spacer(),
                        // Active status dot
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: coupon.isActive ? AppTheme.accentGreen : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coupon.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500,
                            color: coupon.isActive ? AppTheme.accentGreen : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    // Sort order & ID row
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Order: ${coupon.sortOrder}',
                          style: TextStyle(fontSize: 9, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${coupon.couponId.length > 12 ? '${coupon.couponId.substring(0, 12)}...' : coupon.couponId}',
                          style: TextStyle(fontSize: 9, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ─── Action Row ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Copy ID
              _ActionButton(
                icon: Icons.copy_rounded,
                color: AppTheme.accentPurple,
                tooltip: 'Copy ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: coupon.couponId));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: ${coupon.couponId}'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // View marketplace preview
              _ActionButton(
                icon: Icons.visibility_outlined,
                color: AppTheme.accentOrange,
                tooltip: 'Marketplace Preview',
                onPressed: onViewMarketplace,
              ),
              const SizedBox(width: 6),
              // Active toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: coupon.isActive,
                      onChanged: (v) => couponProv.toggleActive(coupon.couponId, v),
                      activeColor: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              // Edit
              _ActionButton(
                icon: Icons.edit_outlined,
                color: AppTheme.accentBlue,
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              const SizedBox(width: 6),
              // Delete
              _ActionButton(
                icon: Icons.delete_outline,
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: Text('Delete "${coupon.brandName} - ${coupon.offerTitle}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              couponProv.deleteCoupon(coupon.couponId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ACTION BUTTON (reusable)
// ════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PAGE NAVIGATION BUTTON (prev/next)
// ════════════════════════════════════════════════════════════
class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark
                ? (enabled ? AppTheme.bgCardLight : Colors.transparent)
                : (enabled ? const Color(0xFFF1F5F9) : Colors.transparent),
            border: Border.all(
              color: isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? AppTheme.textMuted : const Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PAGE NUMBER BUTTON
// ════════════════════════════════════════════════════════════
class _PageNumber extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isDark;

  const _PageNumber({
    required this.page,
    required this.isActive,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? AppTheme.accentGreen : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? AppTheme.accentGreen
                  : (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0)),
              width: isActive ? 0 : 0.5,
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Colors.black
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
