import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import '../domain/audit_log_model.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('SYSTEM RECORDS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        body: FutureBuilder<List<AuditLogModel>>(
          future: ref.read(adminRepositoryProvider).getAuditLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No audit logs recorded', style: TextStyle(color: SuperAdminTheme.textSecondary)));
            }
            
            final logs = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(color: SuperAdminTheme.surfaceLighter, height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, shape: BoxShape.circle),
                        child: Icon(_actionIcon(log.action), color: _actionColor(log.action), size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(log.action, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                Text(_timeAgo(log.createdAt), style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${log.target} — by ${log.userEmail}', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
