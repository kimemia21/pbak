import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

Future<void> showWhyWeCollectInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final theme = Theme.of(context);
      final size = MediaQuery.of(context).size;
      final isDesktop = size.width > 800;
      final isMobile = size.width < 600;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 24 : 40,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 600 : 520,
            maxHeight: size.height * 0.9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.02),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 50,
                spreadRadius: 0,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Header with Black & White
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 20 : 28,
                        isMobile ? 24 : 28,
                        isMobile ? 12 : 16,
                        isMobile ? 24 : 28,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black,
                            Colors.grey.shade900,
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon with glassmorphic effect
                          Container(
                            width: isMobile ? 52 : 60,
                            height: isMobile ? 52 : 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: isMobile ? 28 : 32,
                            ),
                          ),
                          SizedBox(width: isMobile ? 14 : 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Privacy',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: isMobile ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Why we collect info',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Close',
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your safety is our top priority 🏍️',
                              style: GoogleFonts.inter(
                                height: 1.6,
                                fontSize: isMobile ? 15 : 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We collect your details to keep everyone safe and connected during our rides. Here\'s how we use your information:',
                              style: GoogleFonts.inter(
                                height: 1.6,
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                            
                            ...[
                              _InfoPointData(
                                icon: Icons.verified_user_rounded,
                                title: 'Rider Verification',
                                description: 'Verify participants and ensure everyone\'s safety on every ride',
                              ),
                              _InfoPointData(
                                icon: Icons.notifications_active_rounded,
                                title: 'Stay Updated',
                                description: 'Get important updates about route changes and event details',
                              ),
                              _InfoPointData(
                                icon: Icons.health_and_safety_rounded,
                                title: 'Emergency Response',
                                description: 'Quick assistance in case of emergencies or unexpected situations',
                              ),
                              _InfoPointData(
                                icon: Icons.groups_rounded,
                                title: 'Group Coordination',
                                description: 'Keep track of all riders and maintain group cohesion',
                              ),
                            ].asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == 3 ? 0 : (isMobile ? 16 : 18),
                                ),
                                child: _buildModernInfoPoint(
                                  context,
                                  data: data,
                                  isMobile: isMobile,
                                ),
                              );
                            }).toList(),
                            
                            SizedBox(height: isMobile ? 24 : 28),
                            
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.black,
                                      Colors.grey.shade900,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isMobile ? 16 : 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Got it, thanks!',
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _InfoPointData {
  final IconData icon;
  final String title;
  final String description;

  _InfoPointData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

Widget _buildModernInfoPoint(
  BuildContext context, {
  required _InfoPointData data,
  required bool isMobile,
}) {
  return Container(
    padding: EdgeInsets.all(isMobile ? 16 : 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade50,
          Colors.white,
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.black.withOpacity(0.08),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 44 : 48,
          height: isMobile ? 44 : 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.grey.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            data.icon,
            size: isMobile ? 22 : 24,
            color: Colors.white,
          ),
        ),
        SizedBox(width: isMobile ? 14 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.description,
                style: GoogleFonts.inter(
                  height: 1.5,
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}