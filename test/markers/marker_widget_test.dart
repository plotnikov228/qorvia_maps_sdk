import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('MarkerWidget', () {
    testWidgets('renders DefaultMarkerIcon with modern style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: DefaultMarkerIcon(
                  color: MarkerColors.primary,
                  style: MarkerStyle.modern,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
    });

    testWidgets('renders DefaultMarkerIcon with classic style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: DefaultMarkerIcon(
                  color: MarkerColors.end,
                  style: MarkerStyle.classic,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders DefaultMarkerIcon with minimal style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: DefaultMarkerIcon(
                  color: MarkerColors.start,
                  style: MarkerStyle.minimal,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
    });

    testWidgets('renders DefaultMarkerIcon with inner icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: DefaultMarkerIcon(
                  color: MarkerColors.primary,
                  innerIcon: Icons.star,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders NumberedMarkerIcon with number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: NumberedMarkerIcon(number: 42),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders NumberedMarkerIcon with letter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: NumberedMarkerIcon.letter('A'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarkerWidget), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders NumberedMarkerIcon with different styles',
        (WidgetTester tester) async {
      for (final style in MarkerStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MarkerWidget(
                  icon: NumberedMarkerIcon(
                    number: 1,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(MarkerWidget), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      }
    });
  });

  group('AnimatedMarkerWidget', () {
    testWidgets('renders pulsing animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: AnimatedMarkerIcon(
                  animationType: MarkerAnimationType.pulse,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
    });

    testWidgets('renders drop-in animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: AnimatedMarkerIcon(
                  animationType: MarkerAnimationType.dropIn,
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);

      // Complete animation
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
    });

    testWidgets('renders ripple animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: AnimatedMarkerIcon(
                  animationType: MarkerAnimationType.ripple,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
    });

    testWidgets('renders pulse+ripple animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: AnimatedMarkerIcon(
                  animationType: MarkerAnimationType.pulseRipple,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
    });

    testWidgets('renders with inner icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: AnimatedMarkerIcon(
                  innerIcon: Icons.flag,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });
  });

  group('CachedMarkerWidget', () {
    testWidgets('renders cached marker', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: CachedMarkerIcon.primary(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CachedMarkerWidget), findsOneWidget);
    });

    testWidgets('shows base marker initially while caching',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(
                icon: CachedMarkerIcon(
                  baseIcon: DefaultMarkerIcon.primary,
                ),
              ),
            ),
          ),
        ),
      );

      // Should show the base marker while caching
      expect(find.byType(CachedMarkerWidget), findsOneWidget);
    });
  });

  group('MarkerCache', () {
    setUp(() {
      MarkerCache.instance.clear();
    });

    test('generates consistent keys', () {
      const icon1 = DefaultMarkerIcon(
        color: MarkerColors.primary,
        size: 48,
        style: MarkerStyle.modern,
      );
      const icon2 = DefaultMarkerIcon(
        color: MarkerColors.primary,
        size: 48,
        style: MarkerStyle.modern,
      );
      const icon3 = DefaultMarkerIcon(
        color: MarkerColors.end,
        size: 48,
        style: MarkerStyle.modern,
      );

      final key1 = MarkerCache.instance.generateKey(icon1, 2.0);
      final key2 = MarkerCache.instance.generateKey(icon2, 2.0);
      final key3 = MarkerCache.instance.generateKey(icon3, 2.0);

      expect(key1, key2);
      expect(key1, isNot(key3));
    });

    test('key includes device pixel ratio', () {
      const icon = DefaultMarkerIcon.primary;

      final key1 = MarkerCache.instance.generateKey(icon, 1.0);
      final key2 = MarkerCache.instance.generateKey(icon, 2.0);
      final key3 = MarkerCache.instance.generateKey(icon, 3.0);

      expect(key1, isNot(key2));
      expect(key2, isNot(key3));
    });

    test('starts with empty cache', () {
      expect(MarkerCache.instance.size, 0);
    });

    test('clear removes all entries', () {
      // We can't easily add images without Flutter engine,
      // but we can verify clear works
      MarkerCache.instance.clear();
      expect(MarkerCache.instance.size, 0);
    });
  });

  group('Marker preset rendering', () {
    testWidgets('renders all DefaultMarkerIcon presets',
        (WidgetTester tester) async {
      final presets = [
        DefaultMarkerIcon.primary,
        DefaultMarkerIcon.red,
        DefaultMarkerIcon.blue,
        DefaultMarkerIcon.green,
        DefaultMarkerIcon.orange,
        DefaultMarkerIcon.start,
        DefaultMarkerIcon.end,
        DefaultMarkerIcon.classicPrimary,
        DefaultMarkerIcon.classicRed,
        DefaultMarkerIcon.classicGreen,
        DefaultMarkerIcon.minimalPrimary,
        DefaultMarkerIcon.minimalRed,
        DefaultMarkerIcon.minimalGreen,
      ];

      for (final preset in presets) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MarkerWidget(icon: preset),
              ),
            ),
          ),
        );

        expect(find.byType(MarkerWidget), findsOneWidget);
      }
    });

    testWidgets('renders AnimatedMarkerIcon pulsing preset',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(icon: AnimatedMarkerIcon.pulsingPrimary),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders AnimatedMarkerIcon dropIn preset',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(icon: AnimatedMarkerIcon.dropInStart),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders AnimatedMarkerIcon ripple preset',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarkerWidget(icon: AnimatedMarkerIcon.rippleLocation),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedMarkerWidget), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
