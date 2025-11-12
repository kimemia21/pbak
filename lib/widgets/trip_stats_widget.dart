import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/theme/app_theme.dart';

class TripStatsWidget extends StatelessWidget {
  final double distance;
  final double currentSpeed;
  final double averageSpeed;
  final double maxSpeed;
  final String duration;
  final bool isTracking;

  const TripStatsWidget({
    super.key,
    required this.distance,
    required this.currentSpeed,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.duration,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlack,
            AppTheme.secondaryBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingS),
                decoration: BoxDecoration(
                  color: isTracking ? AppTheme.deepRed : AppTheme.darkGrey,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  isTracking ? Icons.radio_button_checked : Icons.stop_circle,
                  color: AppTheme.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              Text(
                isTracking ? 'Trip in Progress' : 'Trip Paused',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingL),
          
          // Main Stats Grid
          Row(
            children: [
              // Distance
              Expanded(
                child: _buildMainStat(
                  icon: Icons.timeline,
                  label: 'Distance',
                  value: distance.toStringAsFixed(2),
                  unit: 'km',
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(width: AppTheme.paddingM),
              
              // Duration
              Expanded(
                child: _buildMainStat(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: duration,
                  unit: '',
                  color: AppTheme.brightRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          
          // Speed Stats
          Row(
            children: [
              // Current Speed
              Expanded(
                child: _buildSecondaryStat(
                  icon: Icons.speed,
                  label: 'Current',
                  value: currentSpeed.toStringAsFixed(1),
                  unit: 'km/h',
                ),
              ),
              const SizedBox(width: AppTheme.paddingS),
              
              // Average Speed
              Expanded(
                child: _buildSecondaryStat(
                  icon: Icons.trending_flat,
                  label: 'Average',
                  value: averageSpeed.toStringAsFixed(1),
                  unit: 'km/h',
                ),
              ),
              const SizedBox(width: AppTheme.paddingS),
              
              // Max Speed
              Expanded(
                child: _buildSecondaryStat(
                  icon: Icons.trending_up,
                  label: 'Max',
                  value: maxSpeed.toStringAsFixed(1),
                  unit: 'km/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStat({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.paddingS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                  height: 1,
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
                      fontWeight: FontWeight.w500,
                      color: AppTheme.silverGrey,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.silverGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
        vertical: AppTheme.paddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.silverGrey, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.poppins(
              fontSize: 10,
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
          ),
        ],
      ),
    );
  }
}
