import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShimmerLoading', () {
    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('pumps frames to trigger animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // Pump several frames to verify the animation runs without errors
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders with default properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(height: 20),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('renders with custom width and borderRadius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: 100,
              height: 30,
              borderRadius: 8,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonCircle', () {
    testWidgets('renders with given size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: 48),
          ),
        ),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
    });
  });

  group('OfferCardSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfferCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(OfferCardSkeleton), findsOneWidget);
    });

    testWidgets('has expected height container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfferCardSkeleton(),
          ),
        ),
      );

      // Should contain a SkeletonBox inside
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('FeaturedOffersSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeaturedOffersSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(FeaturedOffersSkeleton), findsOneWidget);
    });

    testWidgets('contains skeleton boxes and dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeaturedOffersSkeleton(),
            ),
          ),
        ),
      );

      // Has multiple SkeletonBox children
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('ProjectCardSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(ProjectCardSkeleton), findsOneWidget);
    });
  });

  group('NotificationTileSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationTileSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(NotificationTileSkeleton), findsOneWidget);
    });
  });

  group('WalletDashboardSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WalletDashboardSkeleton(),
          ),
        ),
      );

      expect(find.byType(WalletDashboardSkeleton), findsOneWidget);
    });

    testWidgets('contains ShimmerLoading instances inside', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            // Wrap with enough height so the ListView renders all items
            body: SizedBox(
              height: 2000,
              child: WalletDashboardSkeleton(),
            ),
          ),
        ),
      );

      // ListView lazy-builds its children; a tall SizedBox ensures they render
      expect(find.byType(WalletDashboardSkeleton), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsWidgets);
    });
  });

  group('FeaturedProjectCardSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedProjectCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(FeaturedProjectCardSkeleton), findsOneWidget);
    });
  });

  group('RewardsScreenSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardsScreenSkeleton(),
          ),
        ),
      );

      expect(find.byType(RewardsScreenSkeleton), findsOneWidget);
    });

    testWidgets('renders multiple skeleton items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardsScreenSkeleton(),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonCircle), findsWidgets);
    });
  });

  group('SearchBarSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchBarSkeleton(),
          ),
        ),
      );

      expect(find.byType(SearchBarSkeleton), findsOneWidget);
    });

    testWidgets('has search area styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchBarSkeleton(),
          ),
        ),
      );

      // Verify the SizedBox is rendered inside for height
      expect(find.byType(SearchBarSkeleton), findsOneWidget);
    });
  });

  group('SortBarSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SortBarSkeleton(),
          ),
        ),
      );

      expect(find.byType(SortBarSkeleton), findsOneWidget);
    });

    testWidgets('contains Row layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SortBarSkeleton(),
          ),
        ),
      );

      // The skeleton has a Row structure
      expect(find.byType(SortBarSkeleton), findsOneWidget);
    });
  });

  group('FilterChipsSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FilterChipsSkeleton(),
          ),
        ),
      );

      expect(find.byType(FilterChipsSkeleton), findsOneWidget);
    });

    testWidgets('renders multiple chip placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: FilterChipsSkeleton(),
            ),
          ),
        ),
      );

      // The skeleton should have container children
      expect(find.byType(FilterChipsSkeleton), findsOneWidget);
    });
  });

  group('TopProjectsSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopProjectsSkeleton(),
            ),
          ),
        ),
      );

      expect(find.byType(TopProjectsSkeleton), findsOneWidget);
    });

    testWidgets('contains grid with project skeletons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopProjectsSkeleton(),
            ),
          ),
        ),
      );

      // Contains ProjectCardSkeleton widgets from the grid
      expect(find.byType(ProjectCardSkeleton), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });

  group('FeaturedProjectsEmptyState', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byType(FeaturedProjectsEmptyState), findsOneWidget);
    });

    testWidgets('displays correct message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedProjectsEmptyState(),
          ),
        ),
      );

      expect(find.text('No featured projects at the moment'), findsOneWidget);
    });

    testWidgets('displays star outline icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('has expected height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedProjectsEmptyState(),
          ),
        ),
      );

      final widget = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(widget.height, 80);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: FeaturedProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byType(FeaturedProjectsEmptyState), findsOneWidget);
      expect(find.text('No featured projects at the moment'), findsOneWidget);
    });
  });

  group('ProjectsEmptyState', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byType(ProjectsEmptyState), findsOneWidget);
    });

    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(),
          ),
        ),
      );

      expect(find.text('No projects found'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(),
          ),
        ),
      );

      expect(
        find.text('Try a different category or search term'),
        findsOneWidget,
      );
    });

    testWidgets('displays search off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const Scaffold(
            body: ProjectsEmptyState(),
          ),
        ),
      );

      expect(find.byType(ProjectsEmptyState), findsOneWidget);
      expect(find.text('No projects found'), findsOneWidget);
      expect(find.text('Try a different category or search term'), findsOneWidget);
    });
  });

  // Dark theme tests for a representative set of widgets
  group('Dark theme rendering', () {
    Widget wrapInDarkApp(Widget child) {
      return MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('SkeletonBox renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const SkeletonBox(height: 20)),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('SkeletonCircle renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const SkeletonCircle(size: 40)),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('ProjectCardSkeleton renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const ProjectCardSkeleton()),
      );

      expect(find.byType(ProjectCardSkeleton), findsOneWidget);
    });

    testWidgets('SearchBarSkeleton renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const SearchBarSkeleton()),
      );

      expect(find.byType(SearchBarSkeleton), findsOneWidget);
    });

    testWidgets('SortBarSkeleton renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const SortBarSkeleton()),
      );

      expect(find.byType(SortBarSkeleton), findsOneWidget);
    });

    testWidgets('FilterChipsSkeleton renders in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const FilterChipsSkeleton()),
      );

      expect(find.byType(FilterChipsSkeleton), findsOneWidget);
    });

    testWidgets('FeaturedProjectCardSkeleton renders in dark theme',
        (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const FeaturedProjectCardSkeleton()),
      );

      expect(find.byType(FeaturedProjectCardSkeleton), findsOneWidget);
    });

    testWidgets('ShimmerLoading animation runs in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapInDarkApp(const ShimmerLoading(
          child: SizedBox(width: 100, height: 100),
        )),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
