import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('MarkerColors', () {
    test('provides standard color palette', () {
      expect(MarkerColors.primary, const Color(0xFF6366F1));
      expect(MarkerColors.start, const Color(0xFF22C55E));
      expect(MarkerColors.end, const Color(0xFFEF4444));
      expect(MarkerColors.warning, const Color(0xFFF59E0B));
      expect(MarkerColors.info, const Color(0xFF0EA5E9));
      expect(MarkerColors.teal, const Color(0xFF14B8A6));
      expect(MarkerColors.purple, const Color(0xFF8B5CF6));
      expect(MarkerColors.pink, const Color(0xFFEC4899));
    });
  });

  group('MarkerStyle', () {
    test('has three style variants', () {
      expect(MarkerStyle.values.length, 3);
      expect(MarkerStyle.values, contains(MarkerStyle.classic));
      expect(MarkerStyle.values, contains(MarkerStyle.modern));
      expect(MarkerStyle.values, contains(MarkerStyle.minimal));
    });
  });

  group('DefaultMarkerIcon', () {
    test('has default values', () {
      const icon = DefaultMarkerIcon();
      expect(icon.color, MarkerColors.primary);
      expect(icon.size, 48);
      expect(icon.style, MarkerStyle.modern);
      expect(icon.showShadow, true);
      expect(icon.accentColor, isNull);
      expect(icon.borderWidth, 2.0);
      expect(icon.innerIcon, isNull);
      expect(icon.innerIconColor, Colors.white);
    });

    test('can create with custom values', () {
      const icon = DefaultMarkerIcon(
        color: MarkerColors.end,
        size: 64,
        style: MarkerStyle.classic,
        showShadow: false,
        borderWidth: 3.0,
        innerIcon: Icons.star,
        innerIconColor: Colors.yellow,
      );

      expect(icon.color, MarkerColors.end);
      expect(icon.size, 64);
      expect(icon.style, MarkerStyle.classic);
      expect(icon.showShadow, false);
      expect(icon.borderWidth, 3.0);
      expect(icon.innerIcon, Icons.star);
      expect(icon.innerIconColor, Colors.yellow);
    });

    test('copyWith preserves unchanged values', () {
      const original = DefaultMarkerIcon(
        color: MarkerColors.start,
        size: 32,
      );

      final copied = original.copyWith(size: 64);

      expect(copied.color, MarkerColors.start);
      expect(copied.size, 64);
      expect(copied.style, MarkerStyle.modern);
    });

    test('provides static presets', () {
      expect(DefaultMarkerIcon.primary.color, MarkerColors.primary);
      expect(DefaultMarkerIcon.red.color, MarkerColors.end);
      expect(DefaultMarkerIcon.green.color, MarkerColors.start);
      expect(DefaultMarkerIcon.orange.color, MarkerColors.warning);
    });

    test('start and end presets have inner icons', () {
      expect(DefaultMarkerIcon.start.innerIcon, Icons.flag_rounded);
      expect(DefaultMarkerIcon.end.innerIcon, Icons.place_rounded);
    });

    test('classic style presets use classic style', () {
      expect(DefaultMarkerIcon.classicPrimary.style, MarkerStyle.classic);
      expect(DefaultMarkerIcon.classicRed.style, MarkerStyle.classic);
      expect(DefaultMarkerIcon.classicGreen.style, MarkerStyle.classic);
    });

    test('minimal style presets use minimal style and smaller size', () {
      expect(DefaultMarkerIcon.minimalPrimary.style, MarkerStyle.minimal);
      expect(DefaultMarkerIcon.minimalPrimary.size, 24);
      expect(DefaultMarkerIcon.minimalRed.style, MarkerStyle.minimal);
      expect(DefaultMarkerIcon.minimalGreen.style, MarkerStyle.minimal);
    });
  });

  group('AnimatedMarkerIcon', () {
    test('has default values', () {
      const icon = AnimatedMarkerIcon();
      expect(icon.color, MarkerColors.primary);
      expect(icon.size, 48);
      expect(icon.animationType, MarkerAnimationType.pulse);
      expect(icon.style, MarkerStyle.modern);
      expect(icon.animationDuration, const Duration(milliseconds: 1500));
      expect(icon.repeat, true);
      expect(icon.showShadow, true);
      expect(icon.innerIcon, isNull);
      expect(icon.rippleColor, isNull);
      expect(icon.rippleMaxRadius, 1.5);
    });

    test('can create with custom animation type', () {
      const icon = AnimatedMarkerIcon(
        animationType: MarkerAnimationType.dropIn,
        repeat: false,
      );

      expect(icon.animationType, MarkerAnimationType.dropIn);
      expect(icon.repeat, false);
    });

    test('copyWith preserves unchanged values', () {
      const original = AnimatedMarkerIcon(
        color: MarkerColors.info,
        animationType: MarkerAnimationType.ripple,
      );

      final copied = original.copyWith(size: 64);

      expect(copied.color, MarkerColors.info);
      expect(copied.size, 64);
      expect(copied.animationType, MarkerAnimationType.ripple);
    });

    test('provides static presets', () {
      expect(AnimatedMarkerIcon.pulsingPrimary.animationType,
          MarkerAnimationType.pulse);
      expect(
          AnimatedMarkerIcon.pulsingRed.animationType, MarkerAnimationType.pulse);
      expect(AnimatedMarkerIcon.dropInStart.animationType,
          MarkerAnimationType.dropIn);
      expect(AnimatedMarkerIcon.dropInStart.repeat, false);
      expect(AnimatedMarkerIcon.rippleLocation.animationType,
          MarkerAnimationType.ripple);
      expect(AnimatedMarkerIcon.pulseRipple.animationType,
          MarkerAnimationType.pulseRipple);
    });

    test('drop-in presets have inner icons', () {
      expect(AnimatedMarkerIcon.dropInStart.innerIcon, Icons.flag_rounded);
      expect(AnimatedMarkerIcon.dropInEnd.innerIcon, Icons.place_rounded);
    });
  });

  group('CachedMarkerIcon', () {
    test('wraps a base icon', () {
      const cached = CachedMarkerIcon(
        baseIcon: DefaultMarkerIcon.primary,
      );

      expect(cached.baseIcon, DefaultMarkerIcon.primary);
      expect(cached.devicePixelRatio, 2.0);
    });

    test('can specify device pixel ratio', () {
      const cached = CachedMarkerIcon(
        baseIcon: DefaultMarkerIcon.primary,
        devicePixelRatio: 3.0,
      );

      expect(cached.devicePixelRatio, 3.0);
    });

    test('factory constructors create correct markers', () {
      final fromDefault = CachedMarkerIcon.fromDefault(
        color: MarkerColors.end,
        size: 32,
        style: MarkerStyle.classic,
      );

      expect(fromDefault.baseIcon, isA<DefaultMarkerIcon>());
      final base = fromDefault.baseIcon as DefaultMarkerIcon;
      expect(base.color, MarkerColors.end);
      expect(base.size, 32);
      expect(base.style, MarkerStyle.classic);
    });

    test('static factory methods work', () {
      final primary = CachedMarkerIcon.primary();
      expect((primary.baseIcon as DefaultMarkerIcon).color, MarkerColors.primary);

      final red = CachedMarkerIcon.red();
      expect((red.baseIcon as DefaultMarkerIcon).color, MarkerColors.end);

      final green = CachedMarkerIcon.green();
      expect((green.baseIcon as DefaultMarkerIcon).color, MarkerColors.start);
    });
  });

  group('NumberedMarkerIcon', () {
    test('can create with number', () {
      const icon = NumberedMarkerIcon(number: 1);
      expect(icon.number, 1);
      expect(icon.text, isNull);
      expect(icon.displayText, '1');
    });

    test('can create with text', () {
      const icon = NumberedMarkerIcon(text: 'A');
      expect(icon.number, isNull);
      expect(icon.text, 'A');
      expect(icon.displayText, 'A');
    });

    test('has default values', () {
      const icon = NumberedMarkerIcon(number: 1);
      expect(icon.color, MarkerColors.primary);
      expect(icon.size, 48);
      expect(icon.style, MarkerStyle.modern);
      expect(icon.showShadow, true);
      expect(icon.textColor, Colors.white);
      expect(icon.fontWeight, FontWeight.bold);
    });

    test('withNumber factory creates numbered marker', () {
      final icon = NumberedMarkerIcon.withNumber(
        42,
        color: MarkerColors.end,
        size: 64,
      );

      expect(icon.number, 42);
      expect(icon.displayText, '42');
      expect(icon.color, MarkerColors.end);
      expect(icon.size, 64);
    });

    test('letter factory creates lettered marker', () {
      final icon = NumberedMarkerIcon.letter(
        'B',
        color: MarkerColors.info,
      );

      expect(icon.text, 'B');
      expect(icon.displayText, 'B');
      expect(icon.color, MarkerColors.info);
    });

    test('letter factory truncates long text', () {
      final icon = NumberedMarkerIcon.letter('ABC');
      expect(icon.text, 'AB');
      expect(icon.displayText, 'AB');
    });

    test('copyWith preserves unchanged values', () {
      const original = NumberedMarkerIcon(
        number: 5,
        color: MarkerColors.warning,
      );

      final copied = original.copyWith(size: 32);

      expect(copied.number, 5);
      expect(copied.color, MarkerColors.warning);
      expect(copied.size, 32);
    });

    test('sequence creates list of numbered markers', () {
      final markers = NumberedMarkerIcon.sequence(
        3,
        color: MarkerColors.info,
        startFrom: 1,
      );

      expect(markers.length, 3);
      expect(markers[0].number, 1);
      expect(markers[1].number, 2);
      expect(markers[2].number, 3);
      expect(markers[0].color, MarkerColors.info);
    });

    test('sequence with custom start', () {
      final markers = NumberedMarkerIcon.sequence(
        3,
        startFrom: 10,
      );

      expect(markers[0].number, 10);
      expect(markers[1].number, 11);
      expect(markers[2].number, 12);
    });

    test('letters creates list of lettered markers', () {
      final markers = NumberedMarkerIcon.letters(
        4,
        color: MarkerColors.purple,
      );

      expect(markers.length, 4);
      expect(markers[0].text, 'A');
      expect(markers[1].text, 'B');
      expect(markers[2].text, 'C');
      expect(markers[3].text, 'D');
      expect(markers[0].color, MarkerColors.purple);
    });

    test('letters limits to 26', () {
      final markers = NumberedMarkerIcon.letters(30);
      expect(markers.length, 26);
      expect(markers.last.text, 'Z');
    });
  });

  group('MarkerAnimationType', () {
    test('has four animation types', () {
      expect(MarkerAnimationType.values.length, 4);
      expect(MarkerAnimationType.values, contains(MarkerAnimationType.pulse));
      expect(MarkerAnimationType.values, contains(MarkerAnimationType.dropIn));
      expect(MarkerAnimationType.values, contains(MarkerAnimationType.ripple));
      expect(
          MarkerAnimationType.values, contains(MarkerAnimationType.pulseRipple));
    });
  });
}
