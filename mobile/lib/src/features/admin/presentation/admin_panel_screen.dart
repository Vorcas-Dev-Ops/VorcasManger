import 'package:flutter/material.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'department_management_screen.dart';
import 'audit_log_screen.dart';
import 'reports_screen.dart';
import 'schedule_screen.dart';
import 'admin_users_tab.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('ADMINISTRATION', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('SYSTEM CONTROLS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const Text('Management Console', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            _AdminTile(
              title: 'Department Management',
              subtitle: 'Manage company departments and teams',
              icon: Icons.business_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentManagementScreen())),
            ),
            const SizedBox(height: 16),
            
            _AdminTile(
              title: 'User Roles & Permissions',
              subtitle: 'Configure staff access levels',
              icon: Icons.security_outlined,
              onTap: () {
                // Navigate to a standalone Users list for role management
                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  backgroundColor: SuperAdminTheme.backgroundBlack,
                  appBar: AppBar(title: const Text('ROLE MANAGEMENT')),
                  body: const AdminUsersTab(),
                )));
              },
            ),
            const SizedBox(height: 16),
            
            _AdminTile(
              title: 'Audit Logs',
              subtitle: 'View system activity and history',
              icon: Icons.history_edu_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
            ),
            const SizedBox(height: 16),
            
            _AdminTile(
              title: 'Analytics & Reports',
              subtitle: 'View company performance metrics',
              icon: Icons.bar_chart_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
            const SizedBox(height: 16),
            
            _AdminTile(
              title: 'Operational Schedule',
              subtitle: 'Team Lead shift management',
              icon: Icons.calendar_month_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: SuperAdminTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
