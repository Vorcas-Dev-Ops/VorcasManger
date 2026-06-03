import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import '../../task/presentation/create_task_screen.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(adminRepositoryProvider).getTaskOverview();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _statusColor(String? status) {
    if (status == 'DONE') return Colors.greenAccent;
    if (status == 'IN_PROGRESS') return Colors.blueAccent;
    return SuperAdminTheme.primaryOrange;
  }

  String _statusLabel(String? status) {
    if (status == 'DONE') return 'COMPLETED';
    if (status == 'IN_PROGRESS') return 'IN PROGRESS';
    return 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('WORKFORCE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: SuperAdminTheme.primaryOrange,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()));
            _load();
          },
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange))
            : RefreshIndicator(
                color: SuperAdminTheme.primaryOrange,
                onRefresh: _load,
                child: Builder(builder: (context) {
                  final statusCounts = _data?['statusCounts'] as Map<String, dynamic>? ?? {};
                  final completedCount = statusCounts['DONE'] ?? 0;
                  final inProgressCount = statusCounts['IN_PROGRESS'] ?? 0;
                  final pendingCount = statusCounts['PENDING'] ?? 0;
                  final tasks = (_data?['tasks'] as List?) ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PROJECT OVERVIEW', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          Text('Tasks', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status summary
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_box, color: Colors.greenAccent),
                                  const SizedBox(height: 16),
                                  Text('$completedCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('COMPLETED', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.watch_later_outlined, color: Colors.blueAccent),
                                  const SizedBox(height: 16),
                                  Text('$inProgressCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('IN PROGRESS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions, color: SuperAdminTheme.primaryOrange),
                            const SizedBox(width: 16),
                            Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            const Text('PENDING', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: SuperAdminTheme.primaryOrange, shape: BoxShape.circle))),
                          const SizedBox(width: 8),
                          Text('ALL TASKS (${tasks.length})', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('No tasks found', style: TextStyle(color: SuperAdminTheme.textSecondary))),
                        )
                      else
                        ...tasks.map<Widget>((task) {
                          final status = task['status'] ?? 'PENDING';
                          final color = _statusColor(status);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: SuperAdminTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                        child: Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(task['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(task['description'] ?? '', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, color: SuperAdminTheme.textSecondary, size: 14),
                                          const SizedBox(width: 4),
                                          Text(task['assignedTo'] ?? 'Unassigned', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                      if (task['deadline'] != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, color: SuperAdminTheme.textSecondary, size: 14),
                                            const SizedBox(width: 4),
                                            Text(task['deadline'], style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  );
                }),
              ),
      ),
    );
  }
}
