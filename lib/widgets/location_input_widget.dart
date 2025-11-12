import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbak/theme/app_theme.dart';

/// A clean location input widget similar to Uber/Bolt
class LocationInputWidget extends StatelessWidget {
  final String hint;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const LocationInputWidget({
    super.key,
    required this.hint,
    this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingM,
          vertical: AppTheme.paddingM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightSilver.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                  color: value != null ? AppTheme.primaryBlack : AppTheme.mediumGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              Icon(
                Icons.close,
                size: 18,
                color: AppTheme.mediumGrey,
              ),
          ],
        ),
      ),
    );
  }
}
