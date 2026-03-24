import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/services/auth_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_listings_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_withdrawals_screen.dart';
import 'screens/admin_notifications_screen.dart';
import 'screens/admin_support_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminListingsScreen(),
    AdminOrdersScreen(),
    AdminWithdrawalsScreen(),
    AdminNotificationsScreen(),
    AdminSupportScreen(),
  ];

  final _titles = ['Dashboard', 'Người dùng', 'Tin đăng', 'Đơn hàng', 'Rút tiền', 'Thông báo', 'Hỗ trợ'];
  final _icons = [Icons.dashboard, Icons.people, Icons.inventory_2, Icons.shopping_bag, Icons.account_balance_wallet, Icons.campaign_outlined, Icons.support_agent_outlined];

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      bottomNavigationBar: isWide ? null : NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFFFF8C00),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_titles.length, (i) => NavigationDestination(
          icon: Icon(_icons[i], color: Colors.white54),
          selectedIcon: Icon(_icons[i], color: Colors.white),
          label: _titles[i],
        )),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          backgroundColor: const Color(0xFF1A1A2E),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          extended: true,
          minExtendedWidth: 200,
          selectedIconTheme: const IconThemeData(color: Color(0xFFFF8C00)),
          unselectedIconTheme: const IconThemeData(color: Colors.white54),
          selectedLabelTextStyle: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
          indicatorColor: const Color(0xFFFF8C00).withValues(alpha: 0.15),
          destinations: List.generate(_titles.length, (i) => NavigationRailDestination(
            icon: Icon(_icons[i]),
            label: Text(_titles[i]),
          )),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white54),
                  label: const Text('Đăng xuất', style: TextStyle(color: Colors.white54)),
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return _screens[_selectedIndex];
  }
}
