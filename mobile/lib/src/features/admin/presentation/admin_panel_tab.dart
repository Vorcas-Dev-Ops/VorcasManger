import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import '../domain/department_model.dart';
import '../domain/audit_log_model.dart';
import 'department_management_screen.dart';
import 'audit_log_screen.dart';

class AdminPanelTab extends ConsumerStatefulWidget {
  const AdminPanelTab({super.key});

  @override
  ConsumerState<AdminPanelTab> createState() => _AdminPanelTabState();
}

class _AdminPanelTabState extends ConsumerState<AdminPanelTab> {
  List<DepartmentModel> _departments = [];
  List<AuditLogModel> _auditLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final depts = await ref.read(adminRepositoryProvider).getDepartments();
      final logs = await ref.read(adminRepositoryProvider).getAuditLogs();
      if (mounted) {
        setState(() {
          _departments = depts;
          _auditLogs = logs.take(3).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
      if (diff.inHours < 24) return '${diff.inHours}H AGO';
      return '${diff.inDays}D AGO';
    } catch (_) {
      return '';
    }
  }

  IconData _actionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('login')) return Icons.login;
    if (a.contains('create') || a.contains('insert')) return Icons.add_circle_outline;
    if (a.contains('update') || a.contains('edit')) return Icons.edit;
    if (a.contains('delete') || a.contains('remove')) return Icons.delete_outline;
    if (a.contains('permission') || a.contains('role')) return Icons.security;
    return Icons.info_outline;
  }

  Color _actionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('fail')) return Colors.redAccent;
    if (a.contains('create') || a.contains('success')) return Colors.greenAccent;
    if (a.contains('permission') || a.contains('role')) return SuperAdminTheme.primaryOrange;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        color: SuperAdminTheme.primaryOrange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text('RESTRICTED ACCESS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // Department Management
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DEPARTMENT MANAGEMENT', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentManagementScreen())),
                  child: const Text('View All', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Department cards from real data
            if (_departments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No departments found', style: TextStyle(color: SuperAdminTheme.textSecondary))),
              )
            else ...[
              // Show first 2 departments as cards
              Row(
                children: [
                  if (_departments.isNotEmpty)
                    Expanded(child: _DeptCard(title: _departments[0].name, description: _departments[0].description, icon: Icons.business)),
                  if (_departments.length > 1) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _DeptCard(title: _departments[1].name, description: _departments[1].description, icon: Icons.business)),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
              if (_departments.length > 2) ...[
                const SizedBox(height: 8),
                Text('+ ${_departments.length - 2} more departments', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
              ],
            ],
            const SizedBox(height: 12),

            // Add Department
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentManagementScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_business, color: SuperAdminTheme.primaryOrange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Departments', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Add, edit, or remove departments', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: SuperAdminTheme.primaryOrange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // System Audit Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SYSTEM AUDIT LOG', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.filter_list, color: SuperAdminTheme.primaryOrange, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  if (_auditLogs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No audit logs found', style: TextStyle(color: SuperAdminTheme.textSecondary)),
                    )
                  else
                    ..._auditLogs.asMap().entries.map((entry) {
                      final log = entry.value;
                      final isLast = entry.key == _auditLogs.length - 1;
                      return Column(
                        children: [
                          _AuditListTile(
                            title: log.action,
                            time: _timeAgo(log.createdAt),
                            icon: _actionIcon(log.action),
                            iconColor: _actionColor(log.action),
                            descWidget: Text(
                              '${log.target} — by ${log.userEmail}',
                              style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, height: 1.4),
                            ),
                          ),
                          if (!isLast) const Divider(color: SuperAdminTheme.surfaceLighter, height: 1),
                        ],
                      );
                    }),
                  const Divider(color: SuperAdminTheme.surfaceLighter, height: 1),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: const Center(
                        child: Text('VIEW ALL AUDIT LOGS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DeptCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _DeptCard({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SuperAdminTheme.primaryOrange, size: 24),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _AuditListTile extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Widget descWidget;

  const _AuditListTile({required this.title, required this.time, required this.icon, required this.iconColor, required this.descWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: SuperAdminTheme.backgroundBlack, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    Text(time, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),
                descWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
