import 'package:flutter/material.dart';

/// Lightweight UI primitives to give screens the same "clean premium" look
/// as `SettingsScreen` (rounded cards, soft shadows, icon chips, etc.).
class PremiumUI {
  /// Neutral background used in Settings.
  static Color scaffoldBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA);
  }

  /// Premium accent (no red).
  ///
  /// Light: deep "ink" navy.
  /// Dark: warm champagne gold (matches premium dark UI nicely).
  static Color accent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? const Color(0xFFE6C77D) : const Color(0xFF0B1F3B);
  }

  static Color accentSoft(BuildContext context) =>
      accent(context).withValues(alpha: 0.12);

  static Color accentBorder(BuildContext context) =>
      accent(context).withValues(alpha: 0.28);

  static List<Color> appBarGradient(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Settings-like gradient, but using our accent instead of red.
    if (isDark) {
      return [const Color(0xFF2D2D2D), const Color(0xFF141414)];
    }

    final a = accent(context);
    return [a, a.withValues(alpha: 0.82)];
  }
}

/// A Settings-like chip wrapper (used by progress header / small badges).
class PremiumChip extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? PremiumUI.accent(context) : cs.surfaceContainerHighest;
    final fg = selected ? Colors.white : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? bg.withValues(alpha: 0.65) : bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? PremiumUI.accent(context) : cs.outlineVariant,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(color: fg, size: 18),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PremiumSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const PremiumSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
