import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Standard app logo used across the application.
///
/// Uses an SVG with transparent background. Optionally tints the logo to better
/// fit light/dark themes.
class AppLogo extends StatelessWidget {
  final double size;

  /// If true, tints the SVG to [color]. If false, uses original SVG colors.
  final bool tint;

  /// Tint color used when [tint] is true.
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 28,
    this.tint = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.onSurface;

    return SvgPicture.asset(
      'assets/images/pbak-logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: tint ? ColorFilter.mode(resolvedColor, BlendMode.srcIn) : null,
      // SVG already has transparent background; no further work needed.
      // If an SVG includes a background rect, remove it from the asset.
    );
  }
}
