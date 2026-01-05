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
    } else if (location.startsWith('/members')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/trips')) {
      _selectedIndex = 3;
    } else if (location.startsWith('/services')) {
      _selectedIndex = 4;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 5;
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
        context.go('/members');
        break;
      case 3:
        context.go('/trips');
        break;
      case 4:
        context.go('/services');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen width
    final bool isVerySmallScreen = screenWidth < 380;
    final bool isSmallScreen = screenWidth >= 380 && screenWidth < 600;
    final bool isLargeScreen = screenWidth >= 600;
    
    // Adjust padding based on screen size
    final double horizontalPadding = isVerySmallScreen 
        ? 8.0
        : isSmallScreen 
            ? AppTheme.paddingS 
            : AppTheme.paddingM;
            
    final double verticalPadding = isVerySmallScreen 
        ? 6.0
        : 10.0;
        
    // Adjust icon size
    final double iconSize = isVerySmallScreen ? 20 : 22;
    
    // Adjust gap between icon and text
    final double gap = isVerySmallScreen ? 3 : 6;
    
    // Adjust button padding
    final double buttonHorizontalPadding = isVerySmallScreen 
        ? 6.0
        : isSmallScreen 
            ? 10.0
            : AppTheme.paddingM;
            
    final double buttonVerticalPadding = isVerySmallScreen 
        ? 8.0
        : 10.0;

    return Scaffold(
      body: widget.child,
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
              rippleColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.silverGrey,
              hoverColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.lightSilver,
              gap: gap,
              activeColor: isDark 
                  ? AppTheme.goldAccent 
                  : AppTheme.deepRed,
              iconSize: iconSize,
              padding: EdgeInsets.symmetric(
                horizontal: buttonHorizontalPadding,
                vertical: buttonVerticalPadding,
              ),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.lightSilver,
              color: AppTheme.mediumGrey,
              tabs: [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.groups_rounded,
                  text: 'Nyumba Kumi',
                ),
                GButton(
                  icon: Icons.people_rounded,
                  text: 'Members',
                ),
                GButton(
                  icon: Icons.route_rounded,
                  text: 'Trips',
                ),
                GButton(
                  icon: Icons.build_rounded,
                  text: 'Services',
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                ),
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