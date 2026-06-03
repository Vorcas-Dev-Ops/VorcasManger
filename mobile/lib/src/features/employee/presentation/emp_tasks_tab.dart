import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'employee_notifiers.dart';

class EmpTasksTab extends ConsumerWidget {
  const EmpTasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskNotifierProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(taskNotifierProvider),
        child: tasks.when(
          data: (taskList) {
            final now = DateTime.now();
            final visibleTasks = taskList.where((task) {
              final status = task['status'] ?? 'PENDING';
              if (status != 'COMPLETED') return true;
              final dueDateStr = task['due_date'];
              if (dueDateStr == null) return true;
              try {
                final dueDate = DateTime.parse(dueDateStr);
                return dueDate.isAfter(now);
              } catch (e) {
                return true;
              }
            }).toList();

            final regularTasks = visibleTasks.where((t) => (t['task_type'] ?? 'TASK') == 'TASK').toList();
            final meetings = visibleTasks.where((t) => t['task_type'] == 'MEETING').toList();
            final pendingCount = visibleTasks.where((t) => t['status'] != 'COMPLETED').length;

            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                const Text('My Tasks', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary, size: 14),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 16, color: SuperAdminTheme.surfaceLighter),
                    const SizedBox(width: 16),
                    Text('$pendingCount Pending', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),

                if (meetings.isNotEmpty) ...[
                  const Text('MEETINGS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  ...meetings.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TaskCard(task: task),
                  )),
                  const SizedBox(height: 16),
                ],

                if (regularTasks.isNotEmpty) ...[
                  const Text('TASKS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  ...regularTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TaskCard(task: task),
                  )),
                ],

                if (visibleTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: const Center(child: Text('No active tasks or meetings.', style: TextStyle(color: SuperAdminTheme.textSecondary))),
                  ),
                
                const SizedBox(height: 100),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  final Map<String, dynamic> task;

  const TaskCard({required this.task, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = task['status'] ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';
    final title = task['title'] ?? 'No Title';
    final description = task['description'] ?? '';
    final dueDate = task['due_date'] ?? 'Soon';
    final taskId = task['id'];

    Color borderColor = SuperAdminTheme.primaryOrange;
    if (status == 'IN_PROGRESS') borderColor = Colors.blue;
    if (isCompleted) borderColor = SuperAdminTheme.statusPositive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTaskDetails(context, task),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCompleted ? SuperAdminTheme.surfaceCard.withOpacity(0.5) : SuperAdminTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(status.replaceAll('_', ' '), style: TextStyle(color: borderColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Icon(isCompleted ? Icons.check_circle : (status == 'PENDING' ? Icons.error_outline : Icons.sync), color: borderColor, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title, 
                style: TextStyle(
                  color: isCompleted ? SuperAdminTheme.textSecondary : Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: isCompleted ? SuperAdminTheme.textSecondary : SuperAdminTheme.textSecondary, fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(isCompleted ? Icons.done_all : Icons.access_time, color: SuperAdminTheme.textSecondary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isCompleted ? 'Completed' : 'Due ${_formatDueDate(dueDate)}', 
                            style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isCompleted)
                    PopupMenuButton<String>(
                    onSelected: (newStatus) {
                      ref.read(taskNotifierProvider.notifier).updateStatus(taskId, newStatus);
                    },
                    color: SuperAdminTheme.surfaceCard,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      _buildPopupItem('PENDING', 'TO-DO', status == 'PENDING'),
                      _buildPopupItem('IN_PROGRESS', 'IN PROGRESS', status == 'IN_PROGRESS'),
                      _buildPopupItem('COMPLETED', 'COMPLETED', status == 'COMPLETED'),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.backgroundBlack,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SuperAdminTheme.surfaceLighter),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(String dueDateStr) {
    if (dueDateStr == 'Soon') return dueDateStr;
    try {
      final date = DateTime.parse(dueDateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dueDateStr;
    }
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(task: task),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? SuperAdminTheme.primaryOrange : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          if (isSelected) const Icon(Icons.check, color: SuperAdminTheme.primaryOrange, size: 16),
        ],
      ),
    );
  }
}

class TaskDetailDialog extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailDialog({required this.task, super.key});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] ?? 'PENDING';
    final title = task['title'] ?? 'No Title';
    final description = task['description'] ?? 'No description provided.';
    final dueDate = task['due_date'] ?? 'Soon';
    final githubUrl = task['github_url'];
    final meetingLink = task['meeting_link'];
    final taskType = task['task_type'] ?? 'TASK';
    final startTime = task['start_time'];
    final createdAt = task['created_at'];
    final assignees = task['assignee_names'];

    return Dialog(
      backgroundColor: SuperAdminTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      taskType,
                      style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: SuperAdminTheme.textSecondary),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _DetailRow(label: 'Status', value: status.replaceAll('_', ' '), valueColor: status == 'COMPLETED' ? SuperAdminTheme.statusPositive : SuperAdminTheme.primaryOrange),
              const Divider(color: SuperAdminTheme.surfaceLighter, height: 32),
              const Text('DESCRIPTION', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              _DetailItem(icon: Icons.calendar_today, label: 'Due Date', value: dueDate),
              if (startTime != null) _DetailItem(icon: Icons.access_time, label: 'Start Time', value: startTime),
              if (assignees != null) _DetailItem(icon: Icons.people_outline, label: 'Assignees', value: assignees),
              if (createdAt != null) _DetailItem(icon: Icons.create, label: 'Created At', value: DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt))),
              const SizedBox(height: 16),
              if (githubUrl != null && githubUrl.toString().isNotEmpty)
                _LinkButton(
                  icon: Icons.code,
                  label: 'View on GitHub',
                  url: githubUrl,
                  color: Colors.white.withOpacity(0.1),
                ),
              if (meetingLink != null && meetingLink.toString().isNotEmpty)
                _LinkButton(
                  icon: Icons.video_call,
                  label: 'Join Meeting',
                  url: meetingLink,
                  color: Colors.blue.withOpacity(0.2),
                  textColor: Colors.blue,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SuperAdminTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;
  final Color? textColor;

  const _LinkButton({required this.icon, required this.label, required this.url, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.open_in_new, color: (textColor ?? Colors.white).withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
