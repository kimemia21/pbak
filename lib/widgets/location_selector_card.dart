import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/theme/app_theme.dart';

/// Modern location selector card with icon and value display
class LocationSelectorCard extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isRequired;

  const LocationSelectorCard({
    super.key,
    required this.label,
    this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        decoration: BoxDecoration(
          color: hasValue
              ? AppTheme.deepRed.withOpacity(0.05)
              : AppTheme.lightSilver.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: hasValue
                ? AppTheme.deepRed.withOpacity(0.3)
                : AppTheme.lightSilver,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: AppTheme.paddingM),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mediumGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brightRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? value! : 'Tap to select',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue ? AppTheme.primaryBlack : AppTheme.mediumGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow or check icon
            Icon(
              hasValue ? Icons.check_circle : Icons.arrow_forward_ios,
              color: hasValue ? AppTheme.deepRed : AppTheme.mediumGrey,
              size: hasValue ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}
