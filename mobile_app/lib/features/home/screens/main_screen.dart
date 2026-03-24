import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_provider.dart';
import '../../chat/services/chat_provider.dart';

// Helper: kiểm tra đăng nhập, nếu chưa thì chuyển về onboarding
bool _requireAuth(BuildContext context) {
  if (!context.read<AuthProvider>().isLoggedIn) {
    context.go('/onboarding');
    return false;
  }
  return true;
}

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/conversations')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final unread = context.watch<ChatProvider>().totalUnread;

    return Scaffold(
      body: child,
      floatingActionButton: _PostButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined, activeIcon: Icons.home,
              label: 'Trang chủ', index: 0, current: currentIndex,
              onTap: () => context.go('/'),
            ),
            _NavItem(
              icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view,
              label: 'Sản phẩm', index: 1, current: currentIndex,
              onTap: () => context.go('/products'),
            ),
            const SizedBox(width: 56), // space for FAB
            _NavItem(
              icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,
              label: 'Chat', index: 3, current: currentIndex,
              badge: unread > 0 ? unread : null,
              onTap: () {
                if (_requireAuth(context)) {
                  context.read<ChatProvider>().loadConversations();
                  context.go('/conversations');
                }
              },
            ),
            _NavItem(
              icon: Icons.person_outline, activeIcon: Icons.person,
              label: 'Tài khoản', index: 4, current: currentIndex,
              onTap: () { if (_requireAuth(context)) context.go('/profile'); },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!context.read<AuthProvider>().isLoggedIn) {
          context.go('/onboarding');
          return;
        }
        context.push('/camera');
      },
      child: Container(
        width: 60, height: 60,
        decoration: const BoxDecoration(
          color: AppTheme.secondary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x554CAF50), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 24),
            Text('Đăng tin', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon,
                    color: isActive ? AppTheme.secondary : AppTheme.textSecondary, size: 24),
                if (badge != null)
                  Positioned(
                    right: -6, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppTheme.secondary : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
