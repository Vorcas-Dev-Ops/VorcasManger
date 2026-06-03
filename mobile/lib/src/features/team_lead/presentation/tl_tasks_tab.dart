import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'tl_notifiers.dart';
import '../../../core/common_widgets/common_avatar.dart';

class TlTasksTab extends ConsumerWidget {
  const TlTasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tlTeamTasksProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: tasksAsync.when(
        data: (tasks) {
          final todoTasks = tasks.where((t) => t['status'] == 'TODO' || t['status'] == 'PENDING').toList();
          final progressTasks = tasks.where((t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'ACTIVE').toList();
          final doneTasks = tasks.where((t) => t['status'] == 'DONE' || t['status'] == 'COMPLETED').toList();

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const Text('Sprint Execution', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 8),
              const Text('Real-time task tracking for your squad.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, height: 1.4)),
              const SizedBox(height: 32),

              if (todoTasks.isNotEmpty) ...[
                _buildHeader('TO-DO', SuperAdminTheme.textSecondary),
                ...todoTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _TaskCard(
                    priority: 'ASSIGNED',
                    priorityColor: SuperAdminTheme.textSecondary,
                    title: t['title'] ?? 'No Title',
                    description: 'Assigned to: ${t['assignedTo']}',
                    progress: 0.0,
                    avatars: [t['profile_picture_url'] ?? ''],
                  ),
                )),
                const SizedBox(height: 32),
              ],

              if (progressTasks.isNotEmpty) ...[
                _buildHeader('IN-PROGRESS', SuperAdminTheme.primaryOrange),
                ...progressTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _TaskCard(
                    priority: 'ACTIVE',
                    priorityColor: SuperAdminTheme.primaryOrange,
                    title: t['title'] ?? 'No Title',
                    description: 'Assigned to: ${t['assignedTo']}',
                    progress: 0.5,
                    avatars: [t['profile_picture_url'] ?? ''],
                  ),
                )),
                const SizedBox(height: 32),
              ],
              
              if (tasks.isEmpty)
                const Center(child: Text('No tasks found for the squad', style: TextStyle(color: SuperAdminTheme.textSecondary))),

              const SizedBox(height: 120), // Fab space
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SuperAdminTheme.surfaceLighter),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('TOTAL TASKS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(tasksAsync.value?.length.toString() ?? '0', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Text('tasks', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String priority;
  final Color priorityColor;
  final String title;
  final String description;
  final double progress;
  final List<String> avatars;

  const _TaskCard({
    required this.priority,
    required this.priorityColor,
    required this.title,
    required this.description,
    required this.progress,
    required this.avatars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: priorityColor.withOpacity(0.5)),
            ),
            child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: SuperAdminTheme.backgroundBlack,
                  valueColor: AlwaysStoppedAnimation<Color>(priorityColor == SuperAdminTheme.primaryOrange ? SuperAdminTheme.primaryOrange : Colors.white),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 60,
                height: 32,
                child: Stack(
                  children: List.generate(
                    avatars.length,
                    (index) => Positioned(
                      right: index * 20.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SuperAdminTheme.surfaceCard, width: 2),
                        ),
                        child: CommonAvatar(
                          radius: 14,
                          imageUrl: avatars[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
