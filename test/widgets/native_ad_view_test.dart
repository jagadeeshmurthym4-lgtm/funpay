import 'package:cashspark/core/widgets/native_ad_view.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_ad_service.dart';

/// Records native ad slot loads for verification.
class _RecordingAdService extends MockAdService {
  final Map<int, int> loadCalls = {};

  @override
  Future<bool> loadNativeAd({int slot = 0}) async {
    loadCalls[slot] = (loadCalls[slot] ?? 0) + 1;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AdMobServiceImpl.resetInstance);

  testWidgets('NativeAdView requests its slot on mount', (tester) async {
    final ad = _RecordingAdService();
    AdMobServiceImpl.setInstance(ad);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NativeAdView(slot: 7)),
      ),
    );
    await tester.pump();

    expect(ad.loadCalls[7], 1);
    expect(find.byType(NativeAdView), findsOneWidget);
  });

  testWidgets('NativeAdView collapses when the ad never loads', (tester) async {
    AdMobServiceImpl.setInstance(MockAdService());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NativeAdView(slot: 1)),
      ),
    );
    await tester.pump();

    // Mock returns false → view collapses to an empty box, no platform calls.
    expect(find.byType(NativeAdView), findsOneWidget);
    final size = tester.getSize(find.byType(NativeAdView));
    expect(size.height, 0);
  });
}
