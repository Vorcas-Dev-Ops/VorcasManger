import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/super_admin_providers.dart';
import '../../task/presentation/create_task_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/common_widgets/common_avatar.dart';

class SuperAdminTasksTab extends ConsumerStatefulWidget {
  const SuperAdminTasksTab({super.key});

  @override
  ConsumerState<SuperAdminTasksTab> createState() => _SuperAdminTasksTabState();
}

class _SuperAdminTasksTabState extends ConsumerState<SuperAdminTasksTab> {
  bool _isTasksView = true;
  String _selectedFilter = 'ALL'; // ALL, PENDING, IN_PROGRESS, COMPLETED

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(superAdminAllTasksProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow shell background
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isTasksView) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
            ).then((_) => ref.refresh(superAdminAllTasksProvider));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document upload coming soon!')));
          }
        },
        backgroundColor: SuperAdminTheme.primaryOrange,
        foregroundColor: Colors.white,
        child: Icon(_isTasksView ? Icons.add : Icons.upload_file, size: 28),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          List<Map<String, dynamic>> filteredTasks = tasks;
          if (_selectedFilter != 'ALL') {
            filteredTasks = tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == _selectedFilter).toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(superAdminAllTasksProvider);
              ref.refresh(superAdminTaskOverviewProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TASK MANAGEMENT',
                            style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: SuperAdminTheme.primaryOrange),
                            onPressed: () {
                              ref.refresh(superAdminAllTasksProvider);
                              ref.refresh(superAdminTaskOverviewProvider);
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Segmented Control (Tasks / Documents)
                      Container(
                        decoration: BoxDecoration(
                          color: SuperAdminTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SuperAdminTheme.surfaceLighter),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTasksView = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isTasksView ? SuperAdminTheme.primaryOrange.withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'TASKS', 
                                    style: TextStyle(
                                      color: _isTasksView ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    )
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTasksView = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isTasksView ? SuperAdminTheme.primaryOrange.withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'DOCUMENTS', 
                                    style: TextStyle(
                                      color: !_isTasksView ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    )
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (_isTasksView) ...[
                        // Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(label: 'ALL', isSelected: _selectedFilter == 'ALL', onTap: () => setState(() => _selectedFilter = 'ALL')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'PENDING', isSelected: _selectedFilter == 'PENDING', onTap: () => setState(() => _selectedFilter = 'PENDING')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'IN PROGRESS', isSelected: _selectedFilter == 'IN_PROGRESS', onTap: () => setState(() => _selectedFilter = 'IN_PROGRESS')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'COMPLETED', isSelected: _selectedFilter == 'COMPLETED', onTap: () => setState(() => _selectedFilter = 'COMPLETED')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Task List
                        if (filteredTasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.task_alt, color: SuperAdminTheme.surfaceLighter, size: 48),
                                SizedBox(height: 16),
                                Text('No tasks found.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 16)),
                              ],
                            ),
                          )
                        else
                          ...filteredTasks.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SuperAdminTaskCard(task: t),
                          )),
                        const SizedBox(height: 80), // Padding for FAB
                      ] else ...[
                        // DOCUMENTS View Placeholder
                        const Text('CENTRAL REPOSITORY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        const _DocumentItem(title: 'Workforce_Quarterly_Report.pdf', size: '2.4 MB', date: 'Oct 12, 2026'),
                        const _DocumentItem(title: 'System_Security_Audit.docx', size: '1.2 MB', date: 'Oct 10, 2026'),
                        const _DocumentItem(title: 'Branch_Expansion_Proposal.pdf', size: '5.8 MB', date: 'Oct 05, 2026'),
                        const _DocumentItem(title: 'Role_Hierarchy_Manual.pdf', size: '0.8 MB', date: 'Oct 01, 2026'),
                        const SizedBox(height: 80), // Padding for FAB
                      ]
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : SuperAdminTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class SuperAdminTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const SuperAdminTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final status = (task['status'] ?? '').toString().toUpperCase();
    final title = task['title'] ?? 'Untitled';
    final description = task['description'] ?? 'No description provided.';
    final assigneeName = task['assignee_name'] ?? 'Unassigned';
    final assigneeProfilePic = task['profile_picture_url']; // Assuming API returns this, else null
    final deadline = task['due_date'] != null ? task['due_date'].toString().split('T')[0] : 'No deadline';
    final githubUrl = task['github_url'];

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = SuperAdminTheme.statusPositive;
        break;
      case 'IN_PROGRESS':
        statusColor = SuperAdminTheme.primaryOrange;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.blueAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              const Icon(Icons.more_horiz, color: SuperAdminTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          if (githubUrl != null && githubUrl.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(githubUrl.toString())),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blueAccent, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Repo: $githubUrl', style: const TextStyle(color: Colors.blueAccent, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: SuperAdminTheme.surfaceLighter),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CommonAvatar(
                    radius: 12,
                    imageUrl: assigneeProfilePic,
                  ),
                  const SizedBox(width: 8),
                  Text(assigneeName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: SuperAdminTheme.textSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(deadline, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final String title;
  final String size;
  final String date;

  const _DocumentItem({required this.title, required this.size, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuperAdminTheme.surfaceLighter),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SuperAdminTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_outlined, color: SuperAdminTheme.primaryOrange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$size • $date', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: SuperAdminTheme.textSecondary, size: 20),
        ],
      ),
    );
  }
}
