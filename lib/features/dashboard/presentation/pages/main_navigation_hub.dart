import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:the_salon_app/core/presentation/theme/app_theme.dart';
import 'package:the_salon_app/features/explore/presentation/pages/adaptive_explore_page.dart';
import 'package:the_salon_app/features/ai_salon/presentation/pages/ai_diagnostic_workspace.dart';
import 'package:the_salon_app/features/ai_salon/presentation/pages/ai_smart_mirror_workspace.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdaptiveExplorePage(),
    const Scaffold(
      body: Center(child: Text('Social Hub (Reels) - Coming Soon')),
    ),
    const AiDiagnosticWorkspace(),
    const AiSmartMirrorWorkspace(),
    const Scaffold(body: Center(child: Text('Profile - Coming Soon'))),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Tablet / Desktop layout
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme: const IconThemeData(
                    color: AppTheme.primaryBlue,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppTheme.textLight,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppTheme.textLight,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: Text('Explore'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.video_collection_outlined),
                      selectedIcon: Icon(Icons.video_collection),
                      label: Text('Social'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome),
                      label: Text('AI Salon'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.camera_front_outlined),
                      selectedIcon: Icon(Icons.camera_front),
                      label: Text('AR Mirror'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
              ],
            );
          } else {
            // Mobile layout
            return Column(
              children: [
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
                _buildAnimatedBottomNavBar(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildAnimatedBottomNavBar() {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.explore_outlined,
                    Icons.explore,
                    'Explore',
                  ),
                  _buildNavItem(
                    1,
                    Icons.video_collection_outlined,
                    Icons.video_collection,
                    'Social',
                  ),
                  _buildNavItem(
                    2,
                    Icons.auto_awesome_outlined,
                    Icons.auto_awesome,
                    'AI Salon',
                  ),
                  _buildNavItem(
                    3,
                    Icons.camera_front_outlined,
                    Icons.camera_front,
                    'AR Mirror',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_outline,
                    Icons.person,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutQuad);
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
