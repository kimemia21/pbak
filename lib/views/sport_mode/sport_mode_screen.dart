import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';

class SportModeScreen extends StatelessWidget {
  const SportModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('Sport Mode'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'PERFORMANCE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepRed,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppTheme.paddingS),
            Text(
              'Track Your Ride',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.paddingXL),

            // Lean Angle Card
            _SportModeCard(
              icon: Icons.rotate_90_degrees_ccw_rounded,
              title: 'Lean Angle Monitor',
              description: 'Track your cornering performance in real-time',
              onTap: () => context.push('/sport-mode/lean-angle'),
              gradient: LinearGradient(
                colors: [
                  AppTheme.deepRed,
                  AppTheme.deepRed.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            // Coming Soon Cards
            _SportModeCard(
              icon: Icons.speed_rounded,
              title: 'Speed Tracker',
              description: 'Monitor your speed and acceleration',
              isComingSoon: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.mediumGrey.withValues(alpha: 0.3),
                  AppTheme.mediumGrey.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            _SportModeCard(
              icon: Icons.analytics_rounded,
              title: 'Performance Analytics',
              description: 'Analyze your riding patterns and statistics',
              isComingSoon: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.mediumGrey.withValues(alpha: 0.3),
                  AppTheme.mediumGrey.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: AppTheme.paddingM),

            _SportModeCard(
              icon: Icons.track_changes_rounded,
              title: 'Lap Timer',
              description: 'Time your laps on your favorite tracks',
              isComingSoon: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.mediumGrey.withValues(alpha: 0.3),
                  AppTheme.mediumGrey.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isComingSoon;
  final Gradient gradient;

  const _SportModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.isComingSoon = false,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isComingSoon
                ? AppTheme.mediumGrey.withValues(alpha: 0.3)
                : AppTheme.deepRed.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isComingSoon ? AppTheme.mediumGrey : Colors.white,
              ),
            ),
            const SizedBox(width: AppTheme.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isComingSoon ? AppTheme.mediumGrey : Colors.white,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: AppTheme.paddingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mediumGrey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            'SOON',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.mediumGrey,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isComingSoon
                          ? AppTheme.mediumGrey.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isComingSoon)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
