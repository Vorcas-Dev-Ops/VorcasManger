import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'emp_tasks_tab.dart';
import 'employee_notifiers.dart';

class CompletedTasksScreen extends ConsumerWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskNotifierProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        title: const Text('Completed Tasks', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: SuperAdminTheme.primaryOrange),
        elevation: 0,
      ),
      body: tasks.when(
        data: (taskList) {
          final completedTasks = taskList.where((t) => t['status'] == 'COMPLETED').toList();

          if (completedTasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, color: SuperAdminTheme.textSecondary, size: 64),
                  SizedBox(height: 16),
                  Text('No completed tasks yet.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: completedTasks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TaskCard(task: completedTasks[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
