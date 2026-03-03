import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/speed_indicator.dart';

void main() {
  group('SpeedIndicator', () {
    testWidgets('renders current speed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(speedKmh: 60),
          ),
        ),
      );

      expect(find.text('60'), findsOneWidget);
      expect(find.text('км/ч'), findsOneWidget);
    });

    testWidgets('renders without speed limit circle when no limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(speedKmh: 50),
          ),
        ),
      );

      // Should only have speed box, not limit circle
      final containers = tester.widgetList<Container>(find.byType(Container));
      // Main row contains 1 container (speed box)
      expect(containers.length, lessThanOrEqualTo(2));
    });

    testWidgets('renders speed limit circle when limit provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(
              speedKmh: 50,
              speedLimit: 60,
            ),
          ),
        ),
      );

      // Should show both current speed and limit
      expect(find.text('50'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('shows red text when over speed limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(
              speedKmh: 70,
              speedLimit: 60,
              overLimitColor: Colors.red,
            ),
          ),
        ),
      );

      // Find the speed text
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final speedText = textWidgets.firstWhere(
        (text) => text.data == '70',
      );

      expect(speedText.style?.color, Colors.red);
    });

    testWidgets('shows normal text when under speed limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(
              speedKmh: 50,
              speedLimit: 60,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final speedText = textWidgets.firstWhere(
        (text) => text.data == '50',
      );

      expect(speedText.style?.color, Colors.black);
    });

    testWidgets('uses custom background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(
              speedKmh: 60,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final speedBox = containers.firstWhere((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == Colors.grey;
      });

      expect(speedBox, isNotNull);
    });

    testWidgets('uses custom limit border color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(
              speedKmh: 50,
              speedLimit: 60,
              limitBorderColor: Colors.purple,
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final limitCircle = containers.firstWhere((c) {
        final decoration = c.decoration as BoxDecoration?;
        final border = decoration?.border as Border?;
        return border?.top.color == Colors.purple;
      });

      expect(limitCircle, isNotNull);
    });

    testWidgets('rounds speed values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(speedKmh: 65.7),
          ),
        ),
      );

      expect(find.text('66'), findsOneWidget);
    });

    testWidgets('default colors match Yandex Navigator style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeedIndicator(speedKmh: 60),
          ),
        ),
      );

      // Check default background is white
      final containers = tester.widgetList<Container>(find.byType(Container));
      final speedBox = containers.firstWhere((c) {
        final decoration = c.decoration as BoxDecoration?;
        return decoration?.color == kDefaultSpeedBackgroundColor;
      });

      expect(speedBox, isNotNull);
    });
  });

  group('CompactSpeedIndicator', () {
    testWidgets('renders current speed only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactSpeedIndicator(speedKmh: 45),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      // No km/h label in compact version
      expect(find.text('км/ч'), findsNothing);
    });

    testWidgets('shows red text when over limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactSpeedIndicator(
              speedKmh: 80,
              speedLimit: 60,
              overLimitColor: Colors.red,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('80'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('shows normal text when under limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactSpeedIndicator(
              speedKmh: 50,
              speedLimit: 60,
              textColor: Colors.blue,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('50'));
      expect(text.style?.color, Colors.blue);
    });

    testWidgets('uses custom background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactSpeedIndicator(
              speedKmh: 60,
              backgroundColor: Colors.amber,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.amber);
    });
  });
}
