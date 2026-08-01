import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/domain/entities/offer_entity.dart';
import 'package:cashspark/presentation/providers/offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Static offer wall items shown alongside Firestore offers.
/// These represent common task categories users can complete.
class _OfferWallItem {
  final String title;
  final String subtitle;
  final String reward;
  final IconData icon;
  final Color color;
  final String category;

  const _OfferWallItem({
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.icon,
    required this.color,
    required this.category,
  });
}

const List<_OfferWallItem> _wallItems = [
  _OfferWallItem(
    title: 'Install App',
    subtitle: 'Download & install partner apps to earn instant rewards',
    reward: '50 pts',
    icon: Icons.download_outlined,
    color: Color(0xFF4ADE80),
    category: 'Install',
  ),
  _OfferWallItem(
    title: 'Open Account',
    subtitle: 'Sign up on partner platforms using your referral link',
    reward: '80 pts',
    icon: Icons.person_add_outlined,
    color: Color(0xFF3B82F6),
    category: 'Sign Up',
  ),
  _OfferWallItem(
    title: 'Complete Survey',
    subtitle: 'Share your feedback in short surveys to earn rewards',
    reward: '40 pts',
    icon: Icons.quiz_outlined,
    color: Color(0xFF8B5CF6),
    category: 'Survey',
  ),
  _OfferWallItem(
    title: 'Sign Up',
    subtitle: 'Create a free account on partner websites & apps',
    reward: '60 pts',
    icon: Icons.app_registration_outlined,
    color: Color(0xFFF59E0B),
    category: 'Sign Up',
  ),
  _OfferWallItem(
    title: 'Watch Video',
    subtitle: 'Watch short promotional videos and earn cash rewards',
    reward: '25 pts',
    icon: Icons.play_circle_outline,
    color: Color(0xFFEC4899),
    category: 'Watch',
  ),
];

class OfferWallScreen extends StatefulWidget {
  const OfferWallScreen({super.key});

  @override
  State<OfferWallScreen> createState() => _OfferWallScreenState();
}

class _OfferWallScreenState extends State<OfferWallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().subscribeToActiveOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Wall'),
        centerTitle: true,
      ),
      body: Consumer<OfferProvider>(
        builder: (context, offerProvider, _) {
          final offers = offerProvider.offers;

          return RefreshIndicator(
            onRefresh: () => offerProvider.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F2740), const Color(0xFF1A3350)]
                          : [Colors.white, const Color(0xFFF0F5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: Color(0xFF4ADE80),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Offers & Earn',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse tasks and earn rewards instantly',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick task categories
                Text(
                  'Quick Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                ..._wallItems.map((item) => _buildWallItem(item, isDark)),

                const SizedBox(height: 24),

                // Featured Offers from Firestore
                if (offerProvider.isLoading)
                  ...List.generate(2, (_) => 
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ProjectCardSkeleton(),
                    ),
                  )
                else if (offers.isNotEmpty) ...[
                  Text(
                    'Featured Offers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...offers.map((offer) => _buildFeaturedOffer(offer, isDark)),
                ],

                if (!offerProvider.isLoading && offers.isEmpty && _wallItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.card_giftcard_outlined,
                              size: 64, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                          const SizedBox(height: 16),
                          Text(
                            'No offers available yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back soon for new earning opportunities!',
                            style: TextStyle(
                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallItem(_OfferWallItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Starting "${item.title}" task...'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2740) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.reward,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedOffer(OfferEntity offer, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Hero(
          tag: 'offer_${offer.title}',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [offer.color, offer.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: offer.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Helpers.iconFromString(offer.iconName),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      offer.reward,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
