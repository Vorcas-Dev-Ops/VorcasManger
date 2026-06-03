import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../employee/presentation/employee_notifiers.dart';
import '../../../core/common_widgets/common_avatar.dart';

class SquadMemberDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> member;

  const SquadMemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeId = member['id'] as int;
    final tasksAsync = ref.watch(employeeTasksProvider(employeeId));
    final isOnline = member['status'] == 'ACTIVE' || member['status'] == 'ONLINE';

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: SuperAdminTheme.backgroundBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CommonAvatar(
                    radius: 140, 
                    imageUrl: member['profile_picture_url'] ?? member['avatarUrl'],
                    isSquare: true,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SuperAdminTheme.backgroundBlack,
                          Colors.transparent,
                          SuperAdminTheme.backgroundBlack.withOpacity(0.8),
                          SuperAdminTheme.backgroundBlack,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member['name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (isOnline)
                               Container(
                                 width: 10,
                                 height: 10,
                                 decoration: const BoxDecoration(color: SuperAdminTheme.statusPositive, shape: BoxShape.circle),
                               ),
                          ],
                        ),
                        Text(
                          member['role']?.toString().toUpperCase() ?? 'MEMBER',
                          style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SQUAD MEMBER DETAILS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildDetailGrid(),
                  const SizedBox(height: 40),
                  const Text('ASSIGNED TASKS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Tasks List
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No active tasks assigned', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return _TaskItem(task: task);
                  },
                  childCount: tasks.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildDetailGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _InfoCard(label: 'STATUS', value: member['status'] ?? 'ACTIVE', icon: Icons.info_outline),
        _InfoCard(label: 'PHONE', value: member['phone'] ?? 'N/A', icon: Icons.phone_android),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuperAdminTheme.surfaceLighter),
      ),
      child: Row(
        children: [
          Icon(icon, color: SuperAdminTheme.primaryOrange, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final status = task['status'] ?? 'TODO';
    final date = DateTime.tryParse(task['due_date'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(date);

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
      case 'DONE': 
        statusColor = SuperAdminTheme.statusPositive; 
        break;
      case 'IN_PROGRESS': 
        statusColor = SuperAdminTheme.primaryOrange; 
        break;
      default: 
        statusColor = SuperAdminTheme.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TaskDetailDialog(task: task),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SuperAdminTheme.surfaceLighter),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['title'] ?? 'Task', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary, size: 10),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
