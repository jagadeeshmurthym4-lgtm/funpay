import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/screens/auth/login_screen.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/mock_ad_service.dart';
import 'helpers/mock_repositories.dart';

Widget createTestApp(AuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {
        AppRouter.home: (_) => const Scaffold(
              body: Center(child: Text('Home Screen Stub')),
            ),
      },
    ),
  );
}

void main() {
  // Test: dispose + recreate provider, use pump(Duration)
  testWidgets('dispose+recreate provider with pump(Duration)', (tester) async {
    // Inject mock AdService to avoid real AdMob SDK calls
    AdMobServiceImpl.setInstance(MockAdService());
    
    final mockRepository = MockAuthRepository();
    mockRepository.setMockUser(null);

    // Create first provider
    var authProvider = AuthProvider(
      authRepository: mockRepository as AuthRepository,
    );

    // Dispose and recreate
    authProvider.dispose();
    authProvider = AuthProvider(
      authRepository: mockRepository as AuthRepository,
    );

    await tester.pumpWidget(createTestApp(authProvider));
    // Advance clock to let AuthProvider._init() complete
    await tester.pump(const Duration(milliseconds: 100));
    // Complete the 1s LoginScreen animation
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Welcome Back'), findsOneWidget);
    authProvider.dispose();
  });
}
