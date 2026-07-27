import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';
import 'package:cashspark/presentation/providers/coupon_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AdminCouponsTab extends StatefulWidget {
  const AdminCouponsTab({super.key});

  @override
  State<AdminCouponsTab> createState() => _AdminCouponsTabState();
}

class _AdminCouponsTabState extends State<AdminCouponsTab> {
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
      setState(() {
        _imagePreviewUrl = url;
      });
    }
  }

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('Coupon Management',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
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

              // Add/Edit Form
              if (_showForm) _buildForm(theme, isDark, couponProv),

              if (_showForm) const SizedBox(height: 16),

              // Coupons list
              if (couponProv.isLoading && couponProv.allCoupons.isEmpty)
                const PremiumLoader(message: 'Loading coupons...')
              else if (couponProv.allCoupons.isEmpty)
                _buildEmptyState(theme)
              else
                ...couponProv.allCoupons.map((coupon) => _CouponAdminCard(
                      coupon: coupon,
                      theme: theme,
                      isDark: isDark,
                      couponProv: couponProv,
                      onEdit: () => _populateForm(coupon),
                    )),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

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
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final cat = _suggestedCategories[index];
                          final isSelected =
                              _categoryCtrl.text == cat;
                          return GestureDetector(
                            onTap: () =>
                                _categoryCtrl.text = cat,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentGreen
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentGreen
                                      : (isDark
                                          ? AppTheme.borderColor
                                          : const Color(0xFFCBD5E1)),
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
                                      : (isDark
                                          ? AppTheme.textSecondary
                                          : const Color(0xFF64748B)),
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
                    // Image preview thumbnail
                    if (_imagePreviewUrl.isNotEmpty &&
                        _isValidUrl(_imagePreviewUrl))
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No coupons yet',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Create your first coupon to get started',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https'));
  }

  Widget _buildImagePreview(bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showFullPreview(context, isDark),
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
                        size: 28,
                        color: theme.colorScheme.error.withValues(alpha: 0.6)),
                    const SizedBox(height: 4),
                    Text(
                      'Invalid image',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.error.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              placeholder: (_, __) => Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentGreen.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // Top-right badge
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 10, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPreview(BuildContext context, bool isDark) {
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
                    color: isDark
                        ? AppTheme.bgCard
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                placeholder: (_, __) => Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.bgCard
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _submitCoupon(CouponProvider couponProv) async {
    // Validation
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
      // Update existing coupon
      final updated = CouponEntity(
        couponId: _editingCouponId!,
        brandName: _brandNameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        offerTitle: _offerTitleCtrl.text.trim(),
        shortDescription: _shortDescCtrl.text.trim().isNotEmpty
            ? _shortDescCtrl.text.trim()
            : null,
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
            ? _shortDescCtrl.text.trim()
            : null,
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

// ============================================================
// COUPON ADMIN CARD
// ============================================================
class _CouponAdminCard extends StatelessWidget {
  final CouponEntity coupon;
  final ThemeData theme;
  final bool isDark;
  final CouponProvider couponProv;
  final VoidCallback onEdit;

  const _CouponAdminCard({
    required this.coupon,
    required this.theme,
    required this.isDark,
    required this.couponProv,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = coupon.expiryDate != null &&
        coupon.expiryDate!.isBefore(DateTime.now());

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Coupon image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      AppTheme.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: coupon.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.local_offer_outlined,
                      size: 22,
                      color: AppTheme.accentGreen.withValues(alpha: 0.4),
                    ),
                    placeholder: (_, __) => const SizedBox(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.brandName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            coupon.category,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentPurple,
                            ),
                          ),
                        ),
                        if (coupon.isFeatured) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFF59E0B)),
                        ],
                        if (isExpired) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'EXPIRED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.offerTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondary
                            : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      coupon.discountText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Active toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Active',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: coupon.isActive,
                      onChanged: (v) =>
                          couponProv.toggleActive(coupon.couponId, v),
                      activeColor: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                color: AppTheme.accentBlue,
                tooltip: 'Edit',
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppTheme.accentBlue.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _confirmDelete(context),
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.error.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
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
        content: Text('Delete "${coupon.brandName} - ${coupon.offerTitle}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              couponProv.deleteCoupon(coupon.couponId);
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
