import 'package:flutter/material.dart';
import 'package:pbak/theme/app_theme.dart';

/// Modern action button for start/stop trip with better UX
class ModernActionButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final String activeLabel;
  final String inactiveLabel;

  const ModernActionButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.activeLabel = 'Stop Trip',
    this.inactiveLabel = 'Start Trip',
  });

  @override
  State<ModernActionButton> createState() => _ModernActionButtonState();
}

class _ModernActionButtonState extends State<ModernActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ModernActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isActive) {
          setState(() {
            _controller.forward();
          });
        }
      },
      onTapUp: (_) {
        if (!widget.isActive) {
          setState(() {
            _controller.reverse();
          });
        }
        widget.onPressed();
      },
      onTapCancel: () {
        if (!widget.isActive) {
          setState(() {
            _controller.reverse();
          });
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? 1.0 : _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring for active state
                if (widget.isActive)
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.brightRed.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Main button
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isActive
                          ? [
                              AppTheme.brightRed,
                              AppTheme.deepRed,
                            ]
                          : [
                              AppTheme.deepRed,
                              AppTheme.deepRed.withOpacity(0.8),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isActive
                                ? AppTheme.brightRed
                                : AppTheme.deepRed)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
