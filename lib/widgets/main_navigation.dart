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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingM,
              vertical: AppTheme.paddingS,
            ),
            child: GNav(
              rippleColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.silverGrey,
              hoverColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.lightSilver,
              gap: 8,
              activeColor: isDark 
                  ? AppTheme.goldAccent 
                  : AppTheme.deepRed,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingM,
                vertical: AppTheme.paddingS,
              ),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isDark 
                  ? AppTheme.darkGrey 
                  : AppTheme.lightSilver,
              color: AppTheme.mediumGrey,
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.groups_rounded,
                  text: 'Clubs',
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
