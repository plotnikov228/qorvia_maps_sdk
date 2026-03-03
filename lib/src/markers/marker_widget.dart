import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_svg/flutter_svg.dart';
import 'marker_icon.dart';

/// Widget that renders a marker icon.
class MarkerWidget extends StatelessWidget {
  final MarkerIcon icon;

  const MarkerWidget({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon is SvgMarkerIcon) {
      return _buildSvgIcon(icon as SvgMarkerIcon);
    } else if (icon is AssetMarkerIcon) {
      return _buildAssetIcon(icon as AssetMarkerIcon);
    } else if (icon is NetworkMarkerIcon) {
      return _buildNetworkIcon(icon as NetworkMarkerIcon);
    } else if (icon is WidgetMarkerIcon) {
      return _buildWidgetIcon(icon as WidgetMarkerIcon);
    } else if (icon is AnimatedMarkerIcon) {
      return AnimatedMarkerWidget(icon: icon as AnimatedMarkerIcon);
    } else if (icon is CachedMarkerIcon) {
      return CachedMarkerWidget(icon: icon as CachedMarkerIcon);
    } else if (icon is NumberedMarkerIcon) {
      return _NumberedMarkerWidget(icon: icon as NumberedMarkerIcon);
    } else if (icon is DefaultMarkerIcon) {
      return _buildDefaultIcon(icon as DefaultMarkerIcon);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSvgIcon(SvgMarkerIcon icon) {
    return SvgPicture.asset(
      icon.assetPath,
      width: icon.size,
      height: icon.size,
      colorFilter: icon.color != null
          ? ColorFilter.mode(icon.color!, BlendMode.srcIn)
          : null,
    );
  }

  Widget _buildAssetIcon(AssetMarkerIcon icon) {
    return Image.asset(
      icon.assetPath,
      width: icon.width,
      height: icon.height,
    );
  }

  Widget _buildNetworkIcon(NetworkMarkerIcon icon) {
    return Image.network(
      icon.url,
      width: icon.width,
      height: icon.height,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultIcon(const DefaultMarkerIcon());
      },
    );
  }

  Widget _buildWidgetIcon(WidgetMarkerIcon icon) {
    return SizedBox(
      width: icon.width,
      height: icon.height,
      child: icon.child,
    );
  }

  Widget _buildDefaultIcon(DefaultMarkerIcon icon) {
    switch (icon.style) {
      case MarkerStyle.classic:
        return CustomPaint(
          size: Size(icon.size, icon.size * 1.3),
          painter: _ClassicPinPainter(
            color: icon.color,
            showShadow: icon.showShadow,
          ),
        );
      case MarkerStyle.modern:
        return _ModernMarkerWidget(icon: icon);
      case MarkerStyle.minimal:
        return CustomPaint(
          size: Size(icon.size, icon.size),
          painter: _MinimalPinPainter(
            color: icon.color,
            showShadow: icon.showShadow,
            borderWidth: icon.borderWidth,
          ),
        );
    }
  }
}

/// Modern marker widget with glassmorphism effect and optional inner icon.
class _ModernMarkerWidget extends StatelessWidget {
  final DefaultMarkerIcon icon;

  const _ModernMarkerWidget({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: icon.size,
      height: icon.size * 1.4,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Shadow layer
          if (icon.showShadow)
            Positioned(
              top: 4,
              child: CustomPaint(
                size: Size(icon.size, icon.size * 1.4),
                painter: _ModernPinShadowPainter(),
              ),
            ),
          // Main marker
          CustomPaint(
            size: Size(icon.size, icon.size * 1.4),
            painter: _ModernPinPainter(
              color: icon.color,
              accentColor: icon.accentColor,
              borderWidth: icon.borderWidth,
            ),
          ),
          // Inner icon or circle
          Positioned(
            top: icon.size * 0.12,
            child: _buildInnerContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerContent() {
    final innerSize = icon.size * 0.45;

    if (icon.innerIcon != null) {
      return Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon.innerIcon,
          size: innerSize * 0.6,
          color: icon.color,
        ),
      );
    }

    // Default inner circle with gradient
    return Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Numbered marker widget that displays a number or letter inside.
class _NumberedMarkerWidget extends StatelessWidget {
  final NumberedMarkerIcon icon;

  const _NumberedMarkerWidget({required this.icon});

  @override
  Widget build(BuildContext context) {
    final heightMultiplier =
        icon.style == MarkerStyle.minimal ? 1.0 : 1.4;

    return SizedBox(
      width: icon.size,
      height: icon.size * heightMultiplier,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Shadow layer (for modern style)
          if (icon.showShadow && icon.style == MarkerStyle.modern)
            Positioned(
              top: 4,
              child: CustomPaint(
                size: Size(icon.size, icon.size * 1.4),
                painter: _ModernPinShadowPainter(),
              ),
            ),
          // Main marker shape
          _buildMarkerShape(),
          // Number/text overlay
          Positioned(
            top: icon.style == MarkerStyle.minimal
                ? icon.size * 0.15
                : icon.size * 0.08,
            child: _buildNumberContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerShape() {
    switch (icon.style) {
      case MarkerStyle.classic:
        return CustomPaint(
          size: Size(icon.size, icon.size * 1.4),
          painter: _ClassicPinPainter(
            color: icon.color,
            showShadow: icon.showShadow,
          ),
        );
      case MarkerStyle.modern:
        return CustomPaint(
          size: Size(icon.size, icon.size * 1.4),
          painter: _ModernPinPainter(
            color: icon.color,
            borderWidth: 2.0,
          ),
        );
      case MarkerStyle.minimal:
        return CustomPaint(
          size: Size(icon.size, icon.size),
          painter: _MinimalPinPainter(
            color: icon.color,
            showShadow: icon.showShadow,
            borderWidth: 2.0,
          ),
        );
    }
  }

  Widget _buildNumberContent() {
    final displayText = icon.displayText;
    final innerSize = icon.style == MarkerStyle.minimal
        ? icon.size * 0.7
        : icon.size * 0.5;

    // Calculate font size based on text length
    double fontSize;
    if (displayText.length == 1) {
      fontSize = innerSize * 0.6;
    } else if (displayText.length == 2) {
      fontSize = innerSize * 0.5;
    } else {
      fontSize = innerSize * 0.4;
    }

    return SizedBox(
      width: innerSize,
      height: innerSize,
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: icon.textColor,
            fontSize: fontSize,
            fontWeight: icon.fontWeight,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Custom painter for classic pin marker with gradient and improved shadow.
class _ClassicPinPainter extends CustomPainter {
  final Color color;
  final bool showShadow;

  _ClassicPinPainter({
    required this.color,
    this.showShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final pinRadius = size.width / 2 - 2;
    final pinHeight = size.height;

    // Create pin path (reused for shadow and body)
    Path createPinPath() {
      return Path()
        ..moveTo(centerX, pinHeight)
        ..quadraticBezierTo(
          centerX - pinRadius * 0.8,
          pinHeight - pinRadius * 1.5,
          centerX - pinRadius,
          pinRadius,
        )
        ..arcTo(
          Rect.fromCircle(center: Offset(centerX, pinRadius), radius: pinRadius),
          3.14159,
          -3.14159,
          false,
        )
        ..quadraticBezierTo(
          centerX + pinRadius * 0.8,
          pinHeight - pinRadius * 1.5,
          centerX,
          pinHeight,
        );
    }

    // Draw drop shadow (larger, softer)
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = const Color(0x40000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(createPinPath().shift(const Offset(2, 3)), shadowPaint);
    }

    // Draw pin body with gradient
    final pinPath = createPinPath();
    final gradientPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _lighten(color, 0.15),
          color,
          _darken(color, 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(pinPath, gradientPaint);

    // Draw subtle highlight on top edge
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, pinRadius * 2));
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, pinRadius), radius: pinRadius - 1),
      3.14159 * 1.2,
      -3.14159 * 0.6,
      false,
      highlightPaint,
    );

    // Draw inner circle with subtle shadow
    final innerShadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(centerX + 0.5, pinRadius + 1),
      pinRadius * 0.38,
      innerShadowPaint,
    );

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX, pinRadius),
      pinRadius * 0.38,
      innerPaint,
    );

    // Draw inner circle highlight
    final innerHighlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, pinRadius),
        radius: pinRadius * 0.38,
      ));
    canvas.drawCircle(
      Offset(centerX, pinRadius),
      pinRadius * 0.38,
      innerHighlightPaint,
    );
  }

  /// Lighten a color by the given amount (0.0 to 1.0).
  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darken a color by the given amount (0.0 to 1.0).
  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _ClassicPinPainter oldDelegate) {
    return color != oldDelegate.color || showShadow != oldDelegate.showShadow;
  }
}

/// Shadow painter for modern pin marker.
class _ModernPinShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final pinRadius = size.width / 2 - 4;
    final pinHeight = size.height;

    // Draw soft elliptical shadow at the bottom
    final shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, pinHeight - 4),
        width: pinRadius * 1.2,
        height: pinRadius * 0.4,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for modern pin marker with glassmorphism effect.
class _ModernPinPainter extends CustomPainter {
  final Color color;
  final Color? accentColor;
  final double borderWidth;

  _ModernPinPainter({
    required this.color,
    this.accentColor,
    this.borderWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final pinRadius = size.width / 2 - 4;
    final pinHeight = size.height;

    // Create modern pin path with smoother curves
    Path createModernPinPath() {
      final path = Path();
      final tailLength = pinHeight - pinRadius * 2;

      // Start from bottom tip
      path.moveTo(centerX, pinHeight);

      // Left curve to circle
      path.cubicTo(
        centerX - pinRadius * 0.3,
        pinHeight - tailLength * 0.3,
        centerX - pinRadius,
        pinRadius * 1.8,
        centerX - pinRadius,
        pinRadius,
      );

      // Top circle arc
      path.arcTo(
        Rect.fromCircle(center: Offset(centerX, pinRadius), radius: pinRadius),
        3.14159,
        -3.14159,
        false,
      );

      // Right curve back to tip
      path.cubicTo(
        centerX + pinRadius,
        pinRadius * 1.8,
        centerX + pinRadius * 0.3,
        pinHeight - tailLength * 0.3,
        centerX,
        pinHeight,
      );

      return path;
    }

    final pinPath = createModernPinPath();

    // Draw main body with rich gradient
    final effectiveAccent = accentColor ?? _darken(color, 0.15);
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lighten(color, 0.1),
          color,
          effectiveAccent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(pinPath, bodyPaint);

    // Draw glassmorphism highlight overlay
    final highlightPath = Path();
    highlightPath.moveTo(centerX - pinRadius * 0.7, pinRadius * 0.5);
    highlightPath.quadraticBezierTo(
      centerX,
      pinRadius * 0.2,
      centerX + pinRadius * 0.5,
      pinRadius * 0.6,
    );
    highlightPath.quadraticBezierTo(
      centerX + pinRadius * 0.3,
      pinRadius * 1.2,
      centerX - pinRadius * 0.3,
      pinRadius * 1.1,
    );
    highlightPath.quadraticBezierTo(
      centerX - pinRadius * 0.8,
      pinRadius * 0.9,
      centerX - pinRadius * 0.7,
      pinRadius * 0.5,
    );

    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, pinRadius * 2));

    canvas.drawPath(highlightPath, highlightPaint);

    // Draw subtle border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = Colors.white.withValues(alpha: 0.3);

      canvas.drawPath(pinPath, borderPaint);
    }
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _ModernPinPainter oldDelegate) {
    return color != oldDelegate.color ||
        accentColor != oldDelegate.accentColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// Custom painter for minimal dot-style marker.
class _MinimalPinPainter extends CustomPainter {
  final Color color;
  final bool showShadow;
  final double borderWidth;

  _MinimalPinPainter({
    required this.color,
    this.showShadow = true,
    this.borderWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw shadow
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);
    }

    // Draw outer ring
    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          _lighten(color, 0.15),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outerPaint);

    // Draw white border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = Colors.white;
      canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);
    }

    // Draw inner dot
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawCircle(center, radius * 0.35, innerPaint);
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _MinimalPinPainter oldDelegate) {
    return color != oldDelegate.color ||
        showShadow != oldDelegate.showShadow ||
        borderWidth != oldDelegate.borderWidth;
  }
}

/// Animated marker widget with various animation effects.
class AnimatedMarkerWidget extends StatefulWidget {
  final AnimatedMarkerIcon icon;

  const AnimatedMarkerWidget({
    super.key,
    required this.icon,
  });

  @override
  State<AnimatedMarkerWidget> createState() => _AnimatedMarkerWidgetState();
}

class _AnimatedMarkerWidgetState extends State<AnimatedMarkerWidget>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;

  // Pulse animations
  late Animation<double> _scaleAnimation;

  // Drop-in animations
  late Animation<double> _dropAnimation;
  late Animation<double> _bounceAnimation;

  // Ripple animations
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    final icon = widget.icon;

    // Primary controller for main animation
    _primaryController = AnimationController(
      vsync: this,
      duration: icon.animationDuration,
    );

    // Secondary controller for ripple (slightly different timing)
    _secondaryController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (icon.animationDuration.inMilliseconds * 1.2).round(),
      ),
    );

    switch (icon.animationType) {
      case MarkerAnimationType.pulse:
        _setupPulseAnimation();
        break;
      case MarkerAnimationType.dropIn:
        _setupDropInAnimation();
        break;
      case MarkerAnimationType.ripple:
        _setupRippleAnimation();
        break;
      case MarkerAnimationType.pulseRipple:
        _setupPulseAnimation();
        _setupRippleAnimation();
        break;
    }

    _startAnimation();
  }

  void _setupPulseAnimation() {
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_primaryController);
  }

  void _setupDropInAnimation() {
    _dropAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.05).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: const Interval(0.6, 1.0),
      ),
    );

    // Default scale if not animating
    _scaleAnimation = _bounceAnimation;
  }

  void _setupRippleAnimation() {
    _rippleScale = Tween<double>(begin: 1.0, end: widget.icon.rippleMaxRadius)
        .animate(CurvedAnimation(
      parent: _secondaryController,
      curve: Curves.easeOut,
    ));

    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _secondaryController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startAnimation() {
    final icon = widget.icon;

    if (icon.animationType == MarkerAnimationType.dropIn) {
      _primaryController.forward();
    } else if (icon.repeat) {
      _primaryController.repeat();
      if (icon.animationType == MarkerAnimationType.ripple ||
          icon.animationType == MarkerAnimationType.pulseRipple) {
        _secondaryController.repeat();
      }
    } else {
      _primaryController.forward();
      if (icon.animationType == MarkerAnimationType.ripple ||
          icon.animationType == MarkerAnimationType.pulseRipple) {
        _secondaryController.forward();
      }
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final baseMarker = DefaultMarkerIcon(
      color: icon.color,
      size: icon.size,
      style: icon.style,
      showShadow: icon.showShadow,
      innerIcon: icon.innerIcon,
    );

    switch (icon.animationType) {
      case MarkerAnimationType.pulse:
        return _buildPulseMarker(baseMarker);
      case MarkerAnimationType.dropIn:
        return _buildDropInMarker(baseMarker);
      case MarkerAnimationType.ripple:
        return _buildRippleMarker(baseMarker);
      case MarkerAnimationType.pulseRipple:
        return _buildPulseRippleMarker(baseMarker);
    }
  }

  Widget _buildPulseMarker(DefaultMarkerIcon baseMarker) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: MarkerWidget(icon: baseMarker),
    );
  }

  Widget _buildDropInMarker(DefaultMarkerIcon baseMarker) {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        final dropValue = _primaryController.value < 0.6
            ? _dropAnimation.value
            : 0.0;
        final scaleValue = _primaryController.value >= 0.6
            ? _bounceAnimation.value
            : 1.0;

        return Transform.translate(
          offset: Offset(0, dropValue),
          child: Transform.scale(
            scale: scaleValue,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: MarkerWidget(icon: baseMarker),
    );
  }

  Widget _buildRippleMarker(DefaultMarkerIcon baseMarker) {
    final icon = widget.icon;
    final rippleColor = icon.rippleColor ?? icon.color.withValues(alpha: 0.4);

    return SizedBox(
      width: icon.size * icon.rippleMaxRadius,
      height: icon.size * icon.rippleMaxRadius * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple layer
          AnimatedBuilder(
            animation: _secondaryController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  icon.size * icon.rippleMaxRadius,
                  icon.size * icon.rippleMaxRadius,
                ),
                painter: _RipplePainter(
                  color: rippleColor,
                  scale: _rippleScale.value,
                  opacity: _rippleOpacity.value,
                ),
              );
            },
          ),
          // Marker layer
          MarkerWidget(icon: baseMarker),
        ],
      ),
    );
  }

  Widget _buildPulseRippleMarker(DefaultMarkerIcon baseMarker) {
    final icon = widget.icon;
    final rippleColor = icon.rippleColor ?? icon.color.withValues(alpha: 0.4);

    return SizedBox(
      width: icon.size * icon.rippleMaxRadius,
      height: icon.size * icon.rippleMaxRadius * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple layer
          AnimatedBuilder(
            animation: _secondaryController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  icon.size * icon.rippleMaxRadius,
                  icon.size * icon.rippleMaxRadius,
                ),
                painter: _RipplePainter(
                  color: rippleColor,
                  scale: _rippleScale.value,
                  opacity: _rippleOpacity.value,
                ),
              );
            },
          ),
          // Pulsing marker layer
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: MarkerWidget(icon: baseMarker),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for ripple effect.
class _RipplePainter extends CustomPainter {
  final Color color;
  final double scale;
  final double opacity;

  _RipplePainter({
    required this.color,
    required this.scale,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;
    final currentRadius = baseRadius * scale;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - (scale - 1.0) / 0.5).clamp(0.3, 1.0);

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return scale != oldDelegate.scale ||
        opacity != oldDelegate.opacity ||
        color != oldDelegate.color;
  }
}

/// Global cache for rendered marker painters.
///
/// This singleton manages cached painter outputs to improve performance
/// when displaying many markers with the same appearance.
/// Uses RepaintBoundary + GlobalKey approach for actual image caching.
class MarkerCache {
  MarkerCache._();

  static final MarkerCache instance = MarkerCache._();

  final Map<String, ui.Image> _cache = {};

  /// Maximum number of cached images (LRU eviction).
  static const int maxCacheSize = 100;

  final List<String> _accessOrder = [];

  /// Generates a cache key for a marker icon.
  String generateKey(MarkerIcon icon, double devicePixelRatio) {
    if (icon is DefaultMarkerIcon) {
      return 'default_${icon.color.toARGB32()}_${icon.size}_${icon.style.name}_'
          '${icon.showShadow}_${icon.borderWidth}_${icon.innerIcon?.codePoint}_'
          '$devicePixelRatio';
    }
    // Fallback for other types
    return '${icon.hashCode}_$devicePixelRatio';
  }

  /// Checks if an image is cached.
  bool contains(String key) => _cache.containsKey(key);

  /// Gets a cached image.
  ui.Image? get(String key) {
    if (_cache.containsKey(key)) {
      _updateAccessOrder(key);
      return _cache[key];
    }
    return null;
  }

  /// Stores an image in cache.
  void put(String key, ui.Image image) {
    _cache[key] = image;
    _updateAccessOrder(key);
    _evictIfNeeded();
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  void _evictIfNeeded() {
    while (_cache.length > maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      final image = _cache.remove(oldestKey);
      image?.dispose();
    }
  }

  /// Clears the entire cache.
  void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _accessOrder.clear();
  }

  /// Removes a specific marker from the cache.
  void remove(MarkerIcon icon, {double devicePixelRatio = 2.0}) {
    final key = generateKey(icon, devicePixelRatio);
    final image = _cache.remove(key);
    image?.dispose();
    _accessOrder.remove(key);
  }

  /// Returns the current cache size.
  int get size => _cache.length;
}

/// Widget that displays a cached marker image.
///
/// This widget captures the marker to an image on first render
/// and uses the cached image for subsequent renders.
class CachedMarkerWidget extends StatefulWidget {
  final CachedMarkerIcon icon;

  const CachedMarkerWidget({
    super.key,
    required this.icon,
  });

  @override
  State<CachedMarkerWidget> createState() => _CachedMarkerWidgetState();
}

class _CachedMarkerWidgetState extends State<CachedMarkerWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  ui.Image? _cachedImage;
  bool _needsCapture = true;

  String get _cacheKey => MarkerCache.instance.generateKey(
        widget.icon.baseIcon,
        widget.icon.devicePixelRatio,
      );

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  @override
  void didUpdateWidget(CachedMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.icon.baseIcon != oldWidget.icon.baseIcon ||
        widget.icon.devicePixelRatio != oldWidget.icon.devicePixelRatio) {
      _checkCache();
    }
  }

  void _checkCache() {
    final cached = MarkerCache.instance.get(_cacheKey);
    if (cached != null) {
      setState(() {
        _cachedImage = cached;
        _needsCapture = false;
      });
    } else {
      setState(() {
        _cachedImage = null;
        _needsCapture = true;
      });
      // Schedule capture after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
    }
  }

  Future<void> _captureImage() async {
    if (!mounted || !_needsCapture) return;

    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null || boundary.debugNeedsPaint) {
      // Widget not ready yet, try again
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
      return;
    }

    try {
      final image = await boundary.toImage(
        pixelRatio: widget.icon.devicePixelRatio,
      );

      MarkerCache.instance.put(_cacheKey, image);

      if (mounted) {
        setState(() {
          _cachedImage = image;
          _needsCapture = false;
        });
      }
    } catch (e) {
      // Capture failed, keep showing the live widget
      debugPrint('MarkerCache: Failed to capture marker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached image, show it
    if (_cachedImage != null && !_needsCapture) {
      return RawImage(
        image: _cachedImage,
        width: _cachedImage!.width / widget.icon.devicePixelRatio,
        height: _cachedImage!.height / widget.icon.devicePixelRatio,
        fit: BoxFit.contain,
      );
    }

    // Show the live widget wrapped in RepaintBoundary for capture
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: MarkerWidget(icon: widget.icon.baseIcon),
    );
  }
}
