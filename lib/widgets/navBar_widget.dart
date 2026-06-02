import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String role; // 'admin' or 'user'
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.role,
    required this.currentIndex,
  });

  // Admin navigation items
  List<_NavItem> get _adminItems => [
    _NavItem(
      assetName: 'home',
      route: '/dashboard',
    ),
    _NavItem(
      assetName: 'kPelanggan',
      route: '/kelolaPelanggan',
    ),
    _NavItem(
      assetName: 'kLayanan',
      route: '/kelolaLayanan',
    ),
    _NavItem(
      assetName: 'profile',
      route: '/profile',
    ),
  ];

  // User navigation items
  List<_NavItem> get _userItems => [
    _NavItem(
      assetName: 'home',
      route: '/dashboard',
    ),
    _NavItem(
      assetName: 'tagihan',
      route: '/tagihan',
    ),
    _NavItem(
      assetName: 'profile',
      route: '/profile',
    ),
  ];

  List<_NavItem> get items {
    return role.toLowerCase() == 'admin' ? _adminItems : _userItems;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4B85),
            Color(0xFF043265),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isActive) {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top active indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 32 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon (full-color PNG — do not use Image.color, it breaks non-mask assets)
                      Opacity(
                        opacity: isActive ? 1.0 : 0.55,
                        child: Image.asset(
                          isActive
                              ? 'assets/navBar_icons/${item.assetName}.png'
                              : 'assets/navBar_icons/${item.assetName}_outline.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.circle,
                              size: 26,
                              color: Colors.white.withOpacity(isActive ? 1.0 : 0.55),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String assetName;
  final String route;

  _NavItem({
    required this.assetName,
    required this.route,
  });
}