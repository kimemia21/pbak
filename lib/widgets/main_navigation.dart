import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pbak/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const double _contentMaxWidth = 1100;
  static const double _railBreakpoint = 900;

  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.toString();
    
    if (location.startsWith('/clubs')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/trips')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/services')) {
      _selectedIndex = 3;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 4;
    } else {
      _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent unnecessary navigation
    
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/clubs');
        break;
      case 2:
        context.go('/trips');
        break;
      case 3:
        context.go('/services');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;

    // Use a navigation rail for wide screens (web/desktop) and bottom nav for mobile.
    final bool useRail = screenWidth >= _railBreakpoint || (kIsWeb && screenWidth >= 800);

    Widget constrainedBody(Widget child) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: child,
        ),
      );
    }

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.selected,
              useIndicator: true,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.groups_rounded),
                  label: Text('Nyumba Kumi'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.route_rounded),
                  label: Text('Trips'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.build_rounded),
                  label: Text('Services'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_rounded),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  child: constrainedBody(widget.child),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bottom navigation for mobile/tablet.
    final bool isVerySmallScreen = screenWidth < 380;
    final bool isSmallScreen = screenWidth >= 380 && screenWidth < 600;

    final double horizontalPadding = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? AppTheme.paddingS
            : AppTheme.paddingM;

    final double verticalPadding = isVerySmallScreen ? 6.0 : 10.0;

    final double iconSize = isVerySmallScreen ? 20 : 22;

    final double gap = isVerySmallScreen ? 3 : 6;

    final double buttonHorizontalPadding = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 10.0
            : AppTheme.paddingM;

    final double buttonVerticalPadding = isVerySmallScreen ? 8.0 : 10.0;

    return Scaffold(
      body: constrainedBody(widget.child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: GNav(
              rippleColor: isDark ? AppTheme.darkGrey : AppTheme.silverGrey,
              hoverColor: isDark ? AppTheme.darkGrey : AppTheme.lightSilver,
              gap: gap,
              activeColor: isDark ? AppTheme.goldAccent : AppTheme.deepRed,
              iconSize: iconSize,
              padding: EdgeInsets.symmetric(
                horizontal: buttonHorizontalPadding,
                vertical: buttonVerticalPadding,
              ),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor:
                  isDark ? AppTheme.darkGrey : AppTheme.lightSilver,
              color: AppTheme.mediumGrey,
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.groups_rounded, text: 'Nyumba Kumi'),
                GButton(icon: Icons.route_rounded, text: 'Trips'),
                GButton(icon: Icons.build_rounded, text: 'Services'),
                GButton(icon: Icons.person_rounded, text: 'Profile'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}