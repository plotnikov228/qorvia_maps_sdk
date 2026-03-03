import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_response.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_step.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_state.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/next_turn_panel.dart';

void main() {
  group('NextTurnPanel', () {
    late NavigationState testState;
    late RouteResponse testRoute;

    setUp(() {
      testRoute = RouteResponse(
        requestId: 'test-request-1',
        distanceMeters: 5000,
        durationSeconds: 600,
        polyline: 'test_polyline',
        provider: 'test',
        units: 1,
        steps: [
          RouteStep(
            maneuver: 'turn-left',
            instruction: 'Turn left onto Main Street',
            name: 'Main Street',
            distanceMeters: 480,
            durationSeconds: 60,
          ),
        ],
      );

      testState = NavigationState(
        route: testRoute,
        currentStepIndex: 0,
        currentStep: testRoute.steps!.first,
        distanceToNextManeuver: 480,
        distanceRemaining: 5000,
        durationRemaining: 600,
        estimatedArrival: DateTime.now().add(const Duration(minutes: 10)),
        currentSpeed: 16.67,
        isOffRoute: false,
        hasArrived: false,
        progress: 0.1,
        closestRouteIndex: 0,
      );
    });

    testWidgets('renders with default blue background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(state: testState),
          ),
        ),
      );

      // Find the container with decoration
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NextTurnPanel),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, kDefaultTurnPanelBlue);
    });

    testWidgets('renders with custom background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(
              state: testState,
              backgroundColor: Colors.green,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NextTurnPanel),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.green);
    });

    testWidgets('renders with custom text color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(
              state: testState,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      // Find distance text
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final distanceText = textWidgets.firstWhere(
        (text) => text.data?.contains('480') == true,
      );

      expect(distanceText.style?.color, Colors.black);
    });

    testWidgets('displays distance to maneuver', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(state: testState),
          ),
        ),
      );

      expect(find.textContaining('480'), findsOneWidget);
    });

    testWidgets('displays road name when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(state: testState),
          ),
        ),
      );

      expect(find.text('Main Street'), findsOneWidget);
    });

    testWidgets('returns empty widget when no step', (tester) async {
      final emptyRoute = RouteResponse(
        requestId: 'test-empty',
        distanceMeters: 0,
        durationSeconds: 0,
        polyline: '',
        provider: 'test',
        units: 0,
        steps: [],
      );

      final emptyState = NavigationState(
        route: emptyRoute,
        currentStepIndex: 0,
        currentStep: null,
        distanceToNextManeuver: 0,
        distanceRemaining: 0,
        durationRemaining: 0,
        estimatedArrival: DateTime.now(),
        currentSpeed: 0,
        isOffRoute: false,
        hasArrived: false,
        progress: 0,
        closestRouteIndex: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(state: emptyState),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextTurnPanel(
              state: testState,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NextTurnPanel));
      expect(tapped, isTrue);
    });
  });

  group('CompactNextTurnPanel', () {
    late NavigationState testState;
    late RouteResponse testRoute;

    setUp(() {
      testRoute = RouteResponse(
        requestId: 'test-request-2',
        distanceMeters: 3000,
        durationSeconds: 300,
        polyline: 'test_polyline',
        provider: 'test',
        units: 1,
        steps: [
          RouteStep(
            maneuver: 'turn-right',
            instruction: 'Turn right',
            distanceMeters: 250,
            durationSeconds: 30,
          ),
        ],
      );

      testState = NavigationState(
        route: testRoute,
        currentStepIndex: 0,
        currentStep: testRoute.steps!.first,
        distanceToNextManeuver: 250,
        distanceRemaining: 3000,
        durationRemaining: 300,
        estimatedArrival: DateTime.now().add(const Duration(minutes: 5)),
        currentSpeed: 10.0,
        isOffRoute: false,
        hasArrived: false,
        progress: 0.2,
        closestRouteIndex: 0,
      );
    });

    testWidgets('renders with default blue background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactNextTurnPanel(state: testState),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CompactNextTurnPanel),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, kDefaultTurnPanelBlue);
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactNextTurnPanel(
              state: testState,
              backgroundColor: Colors.purple,
              textColor: Colors.yellow,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CompactNextTurnPanel),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.purple);
    });

    testWidgets('displays distance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactNextTurnPanel(state: testState),
          ),
        ),
      );

      expect(find.textContaining('250'), findsOneWidget);
    });

    testWidgets('returns empty widget when no step', (tester) async {
      final emptyRoute = RouteResponse(
        requestId: 'test-empty-2',
        distanceMeters: 0,
        durationSeconds: 0,
        polyline: '',
        provider: 'test',
        units: 0,
        steps: [],
      );

      final emptyState = NavigationState(
        route: emptyRoute,
        currentStepIndex: 0,
        currentStep: null,
        distanceToNextManeuver: 0,
        distanceRemaining: 0,
        durationRemaining: 0,
        estimatedArrival: DateTime.now(),
        currentSpeed: 0,
        isOffRoute: false,
        hasArrived: false,
        progress: 0,
        closestRouteIndex: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactNextTurnPanel(state: emptyState),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
