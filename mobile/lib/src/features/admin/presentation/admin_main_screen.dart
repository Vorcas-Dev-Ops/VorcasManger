import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';

// Import Super Admin Tabs for Reuse
import '../../super_admin/presentation/super_admin_dashboard_tab.dart';
import '../../super_admin/presentation/super_admin_users_tab.dart';
import '../../super_admin/presentation/super_admin_tasks_tab.dart';

import '../../super_admin/presentation/super_admin_departments_screen.dart';
import '../../super_admin/analytics/presentation/super_admin_analytics_main_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../../core/common_widgets/common_avatar.dart';
import 'admin_profile_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SuperAdminDashboardTab(),
    SuperAdminUsersTab(),
    SuperAdminTasksTab(),
  ];

  Future<void> _handleLogout() async {
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          elevation: 0,
          title: const Text('WORKFORCE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2.0)),
          actions: [
             IconButton(
               icon: const Icon(Icons.notifications_none, color: SuperAdminTheme.primaryOrange),
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
               },
             ),
             const SizedBox(width: 8),
             GestureDetector(
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
               child: CommonAvatar(
                 radius: 16,
                 imageUrl: user?.profilePictureUrl,
               ),
             ),
             const SizedBox(width: 16),
          ],
        ),
        drawer: Drawer(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          child: SafeArea(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: SuperAdminTheme.surfaceCard),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
                          },
                          child: CommonAvatar(
                            radius: 32,
                            imageUrl: user?.profilePictureUrl,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          ref.watch(currentUserProvider)?.roleName.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase()).join(' ') ?? 'Admin',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref.watch(currentUserProvider)?.roleName.replaceAll('_', ' ').toUpperCase() ?? 'ADMINISTRATOR',
                          style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: SuperAdminTheme.primaryOrange),
                  title: const Text('Reports & Analytics', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminAnalyticsMainScreen(initialTabIndex: 3)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business, color: SuperAdminTheme.primaryOrange),
                  title: const Text('Department Management', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminDepartmentsScreen()));
                  },
                ),
                const Spacer(),
                const Divider(color: SuperAdminTheme.surfaceCard),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          unselectedItemColor: SuperAdminTheme.textSecondary,
          selectedItemColor: SuperAdminTheme.primaryOrange,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'DASH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'USERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'TASKS',
            ),
          ],
        ),
      ),
    );
  }
}
