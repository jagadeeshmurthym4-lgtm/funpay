import 'package:cashspark/presentation/screens/rewards/watch_earn_screen.dart';
import 'package:cashspark/presentation/screens/offers/offer_wall_screen.dart';
import 'package:cashspark/presentation/screens/surveys/surveys_screen.dart';
import 'package:cashspark/presentation/screens/surveys/cpx_surveys_screen.dart';
import 'package:cashspark/presentation/screens/auth/complete_profile_screen.dart';
import 'package:cashspark/presentation/screens/auth/registration_screen.dart';
import 'package:cashspark/presentation/screens/auth/edit_profile_screen.dart';
import 'package:cashspark/presentation/screens/auth/login_screen.dart';
import 'package:cashspark/presentation/screens/main_shell.dart';
import 'package:cashspark/presentation/screens/profile/profile_screen.dart';
import 'package:cashspark/presentation/screens/projects/projects_screen.dart';
import 'package:cashspark/presentation/screens/scratch_card/scratch_card_screen.dart';
import 'package:cashspark/presentation/screens/spin_wheel/spin_wheel_screen.dart';
import 'package:cashspark/presentation/screens/referral/referral_dashboard_screen.dart';
import 'package:cashspark/presentation/screens/referral/referral_levels_screen.dart';
import 'package:cashspark/presentation/screens/rewards/rewards_screen.dart';
import 'package:cashspark/presentation/screens/splash/splash_screen.dart';
import 'package:cashspark/presentation/screens/landing/landing_screen.dart';
import 'package:cashspark/presentation/screens/wallet/transaction_detail_screen.dart';
import 'package:cashspark/presentation/screens/wallet/wallet_dashboard_screen.dart';
import 'package:cashspark/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:cashspark/presentation/screens/notifications/notification_center_screen.dart';
import 'package:cashspark/presentation/screens/account/account_management_screen.dart';
import 'package:cashspark/presentation/screens/fraud/fraud_dashboard_screen.dart';
import 'package:cashspark/presentation/screens/legal/about_us_screen.dart';
import 'package:cashspark/presentation/screens/legal/contact_us_screen.dart';
import 'package:cashspark/presentation/screens/legal/disclaimer_screen.dart';
import 'package:cashspark/presentation/screens/legal/privacy_policy_screen.dart';
import 'package:cashspark/presentation/screens/legal/referral_disclaimer_screen.dart';
import 'package:cashspark/presentation/screens/legal/terms_conditions_screen.dart';
import 'package:cashspark/presentation/screens/settings/app_settings_screen.dart';
import 'package:cashspark/presentation/screens/settings/notification_preferences_screen.dart';
import 'package:cashspark/presentation/screens/settings/privacy_settings_screen.dart';
import 'package:cashspark/presentation/screens/help/help_center_screen.dart';
import 'package:cashspark/presentation/screens/help/faq_screen.dart';
import 'package:cashspark/presentation/screens/help/contact_support_screen.dart';
import 'package:cashspark/presentation/screens/help/ticket_history_screen.dart';
import 'package:cashspark/presentation/screens/help/ticket_detail_screen.dart';
import 'package:cashspark/presentation/screens/help/live_chat_screen.dart';
import 'package:cashspark/presentation/screens/projects/affiliate_projects_list_screen.dart';
import 'package:cashspark/presentation/screens/projects/my_projects_screen.dart';
import 'package:cashspark/presentation/screens/coupons/coupons_marketplace_screen.dart';
import 'package:cashspark/presentation/screens/search/search_screen.dart';
import 'package:cashspark/presentation/screens/withdrawals/withdrawal_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String transactionDetail = '/transaction-detail';
  static const String referrals = '/referrals';
  static const String referralLevels = '/referral-levels';
  static const String rewards = '/rewards';
  static const String withdrawals = '/withdrawals';
  static const String admin = '/admin';
  static const String notifications = '/notifications';
  static const String fraudDashboard = '/fraud-dashboard';
  static const String appSettings = '/settings';
  static const String accountManagement = '/account-management';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String referralDisclaimer = '/referral-disclaimer';
  static const String disclaimer = '/disclaimer';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String registration = '/registration';
  static const String completeProfile = '/complete-profile';
  static const String editProfile = '/edit-profile';
  static const String faq = '/faq';
  static const String projects = '/projects';
  static const String spinWheel = '/spin-wheel';
  static const String offerWall = '/offer-wall';
  static const String affiliateProjects = '/affiliate-projects';
  static const String myProjects = '/my-projects';
  static const String scratchCard = '/scratch-card';
  static const String watchEarn = '/watch-earn';
  static const String surveys = '/surveys';
  static const String cpxSurveys = '/cpx-surveys';
  static const String couponsMarketplace = '/coupons-marketplace';
  static const String search = '/search';
  static const String notificationPreferences = '/notification-preferences';
  static const String privacySettings = '/privacy-settings';
  static const String helpCenter = '/help-center';
  static const String contactSupport = '/contact-support';
  static const String ticketHistory = '/ticket-history';
  static const String ticketDetail = '/ticket-detail';
  static const String liveChat = '/live-chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case landing:
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainShell(),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case wallet:
        return MaterialPageRoute(
          builder: (_) => const WalletDashboardScreen(),
          settings: settings,
        );
      case transactionDetail:
        return MaterialPageRoute(
          builder: (_) => const TransactionDetailScreen(),
          settings: settings,
        );
      case referrals:
        return MaterialPageRoute(
          builder: (_) => const ReferralDashboardScreen(),
          settings: settings,
        );
      case referralLevels:
        return MaterialPageRoute(
          builder: (_) => const ReferralLevelsScreen(),
          settings: settings,
        );
      case rewards:
        return MaterialPageRoute(
          builder: (_) => const RewardsScreen(),
          settings: settings,
        );
      case withdrawals:
        return MaterialPageRoute(
          builder: (_) => const WithdrawalScreen(),
          settings: settings,
        );
      case admin:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
          settings: settings,
        );
      case appSettings:
        return MaterialPageRoute(
          builder: (_) => const AppSettingsScreen(),
          settings: settings,
        );
      case accountManagement:
        return MaterialPageRoute(
          builder: (_) => const AccountManagementScreen(),
          settings: settings,
        );
      case privacy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );
      case terms:
        return MaterialPageRoute(
          builder: (_) => const TermsConditionsScreen(),
          settings: settings,
        );
      case referralDisclaimer:
        return MaterialPageRoute(
          builder: (_) => const ReferralDisclaimerScreen(),
          settings: settings,
        );
      case disclaimer:
        return MaterialPageRoute(
          builder: (_) => const DisclaimerScreen(),
          settings: settings,
        );
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutUsScreen(),
          settings: settings,
        );
      case contact:
        return MaterialPageRoute(
          builder: (_) => const ContactUsScreen(),
          settings: settings,
        );
      case registration:
        return MaterialPageRoute(
          builder: (_) => const RegistrationScreen(),
          settings: settings,
        );
      case completeProfile:
        return MaterialPageRoute(
          builder: (_) => const CompleteProfileScreen(),
          settings: settings,
        );
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case faq:
        return MaterialPageRoute(
          builder: (_) => const FaqScreen(),
          settings: settings,
        );
      case projects:
        return MaterialPageRoute(
          builder: (_) => const ProjectsScreen(),
          settings: settings,
        );
      case spinWheel:
        return MaterialPageRoute(
          builder: (_) => const SpinWheelScreen(),
          settings: settings,
        );
      case scratchCard:
        return MaterialPageRoute(
          builder: (_) => const ScratchCardScreen(),
          settings: settings,
        );
      case offerWall:
        return MaterialPageRoute(
          builder: (_) => const OfferWallScreen(),
          settings: settings,
        );
      case fraudDashboard:
        return MaterialPageRoute(
          builder: (_) => const FraudDashboardScreen(),
          settings: settings,
        );
      case notificationPreferences:
        return MaterialPageRoute(
          builder: (_) => const NotificationPreferencesScreen(),
          settings: settings,
        );
      case privacySettings:
        return MaterialPageRoute(
          builder: (_) => const PrivacySettingsScreen(),
          settings: settings,
        );
      case helpCenter:
        return MaterialPageRoute(
          builder: (_) => const HelpCenterScreen(),
          settings: settings,
        );
      case contactSupport:
        return MaterialPageRoute(
          builder: (_) => const ContactSupportScreen(),
          settings: settings,
        );
      case ticketHistory:
        return MaterialPageRoute(
          builder: (_) => const TicketHistoryScreen(),
          settings: settings,
        );
      case ticketDetail:
        final ticket = settings.arguments as dynamic;
        return MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticket: ticket),
          settings: settings,
        );
      case liveChat:
        return MaterialPageRoute(
          builder: (_) => const LiveChatScreen(),
          settings: settings,
        );
      case affiliateProjects:
        return MaterialPageRoute(
          builder: (_) => const AffiliateProjectsListScreen(),
          settings: settings,
        );
      case myProjects:
        return MaterialPageRoute(
          builder: (_) => const MyProjectsScreen(),
          settings: settings,
        );
      case couponsMarketplace:
        return MaterialPageRoute(
          builder: (_) => const CouponsMarketplaceScreen(),
          settings: settings,
        );
      case watchEarn:
        return MaterialPageRoute(
          builder: (_) => const WatchEarnScreen(),
          settings: settings,
        );
      case surveys:
        return MaterialPageRoute(
          builder: (_) => const SurveysScreen(),
          settings: settings,
        );
      case cpxSurveys:
        return MaterialPageRoute(
          builder: (_) => const CpxSurveysScreen(),
          settings: settings,
        );
      case search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationCenterScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
