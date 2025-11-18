import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/theme/app_theme.dart';

/// Modern collapsible trip stats panel with better visuals
class TripStatsPanel extends StatefulWidget {
  final double distance;
  final double currentSpeed;
  final double averageSpeed;
  final double maxSpeed;
  final String duration;
  final bool isTracking;
  final VoidCallback? onToggleMapView;

  const TripStatsPanel({
    super.key,
    required this.distance,
    required this.currentSpeed,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.duration,
    required this.isTracking,
    this.onToggleMapView,
  });

  @override
  State<TripStatsPanel> createState() => _TripStatsPanelState();
}

class _TripStatsPanelState extends State<TripStatsPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlack, AppTheme.secondaryBlack],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with collapse button
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
              bottom: _isExpanded
                  ? Radius.zero
                  : Radius.circular(AppTheme.radiusXL),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingM,
                      vertical: AppTheme.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isTracking
                          ? AppTheme.deepRed.withOpacity(0.2)
                          : AppTheme.darkGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: widget.isTracking
                            ? AppTheme.deepRed
                            : AppTheme.mediumGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isTracking
                                ? AppTheme.brightRed
                                : AppTheme.mediumGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.paddingS),
                        Text(
                          widget.isTracking ? 'LIVE' : 'PAUSED',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingM),

                  // Trip info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Statistics',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                          ),
                        ),
                        Text(
                          '${widget.distance.toStringAsFixed(2)} km • ${widget.duration}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.silverGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse icon
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingL,
                0,
                AppTheme.paddingL,
                AppTheme.paddingL,
              ),
              child: Column(
                children: [
                  // Main stats cards
                  Row(
                    children: [
                      // Distance card
                      Expanded(
                        child: _buildMainStatCard(
                          icon: Icons.route,
                          label: 'Distance',
                          value: widget.distance.toStringAsFixed(2),
                          unit: 'km',
                          color: AppTheme.deepRed,
                          gradient: [
                            AppTheme.deepRed.withOpacity(0.2),
                            AppTheme.brightRed.withOpacity(0.1),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingM),

                      // Current speed card
                      Expanded(
                        child: _buildMainStatCard(
                          icon: Icons.speed,
                          label: 'Speed',
                          value: widget.currentSpeed.toStringAsFixed(0),
                          unit: 'km/h',
                          color: AppTheme.goldAccent,
                          gradient: [
                            AppTheme.goldAccent.withOpacity(0.2),
                            AppTheme.goldAccent.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Speed stats row
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSmallStat(
                          icon: Icons.trending_flat,
                          label: 'Avg Speed',
                          value: widget.averageSpeed.toStringAsFixed(1),
                          unit: 'km/h',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingM,
                          ),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildSmallStat(
                          icon: Icons.trending_up,
                          label: 'Max Speed',
                          value: widget.maxSpeed.toStringAsFixed(1),
                          unit: 'km/h',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingM,
                          ),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildSmallStat(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: widget.duration,
                          unit: '',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.map_outlined,
                          label: 'Full Map',
                          onTap: widget.onToggleMapView,
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingM),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.info_outline,
                          label: 'Details',
                          onTap: () {
                            // Show detailed stats
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.silverGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.silverGrey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.silverGrey, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppTheme.silverGrey,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.silverGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingM),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.white, size: 18),
            const SizedBox(width: AppTheme.paddingS),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
