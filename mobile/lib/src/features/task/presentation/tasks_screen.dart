import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'task_notifier.dart';
import '../domain/task_model.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(taskNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: tasksState.when(
        data: (tasks) => RefreshIndicator(
          onRefresh: () => ref.read(taskNotifierProvider.notifier).refreshTasks(),
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks assigned'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskCard(task: task);
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description, style: theme.textTheme.bodyMedium),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (task.dueDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${task.dueDate!.substring(0, 10)}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                PopupMenuButton<String>(
                  initialValue: task.status,
                  onSelected: (status) {
                    ref.read(taskNotifierProvider.notifier).updateStatus(task.id, status);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'PENDING', child: Text('Pending')),
                    const PopupMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                    const PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
                  ],
                  child: const Row(
                    children: [
                      Text('Update Status', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_drop_down, color: AppTheme.primaryAccent),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED': color = AppTheme.statusPositive; break;
      case 'IN_PROGRESS': color = AppTheme.statusPending; break;
      default: color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
