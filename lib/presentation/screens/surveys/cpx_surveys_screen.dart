import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/cpx_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// CPX Research survey wall.
///
/// On mobile the wall is rendered inside an in-app WebView. On web (where the
/// webview plugin is unsupported) the wall opens in a new browser tab instead.
/// Rewards are delivered server-side via the `cpxPostback` Cloud Function and
/// appear in the user's wallet automatically — the wallet stream is refreshed
/// when this screen is opened so pending credits show up immediately.
class CpxSurveysScreen extends StatefulWidget {
  const CpxSurveysScreen({super.key});

  @override
  State<CpxSurveysScreen> createState() => _CpxSurveysScreenState();
}

class _CpxSurveysScreenState extends State<CpxSurveysScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _loadError = false;
  String? _wallUrl;

  @override
  void initState() {
    super.initState();
    _buildWallUrl();
    _refreshWallet();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Only treat main-frame failures as fatal — subresources (ads,
            // tracking pixels) fail all the time and must not block the wall.
            if (error.isForMainFrame == true && mounted) {
              setState(() => _loadError = true);
            }
          },
        ),
      );

    // Mobile: load the wall as soon as the first frame is ready.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openWallUrl();
      });
    }
  }

  /// Builds the signed wall URL from the CPX config + current user.
  void _buildWallUrl() {
    final cpx = context.read<CpxProvider>();
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _wallUrl = cpx.buildOfferWallUrl(
      userId: user.uid,
      email: user.email,
      username: user.username ?? user.fullName,
    );
  }

  /// Re-arms the wallet listener so a survey credit that landed while the
  /// wall was open appears in the balance immediately.
  void _refreshWallet() {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      context.read<WalletProvider>().listenToWallet(userId);
    }
  }

  Future<void> _openWallUrl() async {
    final url = _wallUrl;
    if (url == null) return;

    if (kIsWeb) {
      // webview_flutter is not supported on web — open in a new tab.
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the survey wall.')),
        );
      }
    } else {
      _loadError = false;
      setState(() => _isLoading = true);
      await _webViewController.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = _wallUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CPX Surveys'),
        centerTitle: true,
      ),
      body: url == null
          ? const Center(child: Text('Please sign in to take surveys.'))
          : kIsWeb
              ? _buildWebFallback(isDark)
              : Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_isLoading)
                      Positioned.fill(
                        child: ColoredBox(
                          color: isDark
                              ? const Color(0xFF0F2740)
                              : Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    if (_loadError) _buildErrorState(isDark),
                  ],
                ),
    );
  }

  /// Web fallback: instructions + a button that opens the wall in a new tab.
  Widget _buildWebFallback(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 64, color: Color(0xFF06B6D4)),
            const SizedBox(height: 16),
            Text(
              'Surveys open in a new tab',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'After finishing surveys, come back here — rewards are credited '
              'to your wallet automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openWallUrl,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Survey Wall'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Positioned.fill(
      child: ColoredBox(
        color: isDark ? const Color(0xFF0F2740) : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 56, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'Could not load the survey wall',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check your connection and try again.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openWallUrl,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
