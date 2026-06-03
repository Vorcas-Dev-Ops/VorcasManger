import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../employee/presentation/staff_directory_screen.dart';
import '../../task/presentation/tasks_screen.dart';
import '../../leave/presentation/leave_approvals_screen.dart';
import '../../task/presentation/create_task_screen.dart';
import '../../profile/presentation/profile_settings_screen.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../task/presentation/task_notifier.dart';
import '../../leave/presentation/leave_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../attendance/domain/attendance_model.dart';
import '../../attendance/presentation/attendance_notifier.dart';
import '../../attendance/presentation/staff_attendance_screen.dart';
import '../../employee/presentation/edit_employee_screen.dart';
import '../../calendar/presentation/company_calendar_screen.dart';
import 'dashboard_notifier.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final String role = user?.roleName ?? 'Employee';

    final List<Widget> screens = [DashboardHome(role: role)];
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
    ];

    if (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'HR') {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Staff'));
      screens.add(const StaffDirectoryScreen());
      
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Approvals'));
      screens.add(const LeaveApprovalsScreen());
    } else {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Tasks'));
      screens.add(const TasksScreen());
      
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Attendance'));
      screens.add(const AttendanceScreen());
    }

    if (role == 'SUPER_ADMIN' || role == 'ADMIN') {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'));
      screens.add(const CompanyCalendarScreen());
    } else {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.beach_access_outlined), label: 'Leave'));
      screens.add(const LeaveScreen());
    }

    // Ensure index is within range if role changes
    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryAccent,
        unselectedItemColor: AppTheme.textSecondary,
        items: navItems,
      ),
    );
  }
}

class DashboardHome extends ConsumerWidget {
  final String role;
  const DashboardHome({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksState = ref.watch(taskNotifierProvider);
    final isManager = ['SUPER_ADMIN', 'ADMIN', 'HR'].contains(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vorcas Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CommonAvatar(
                radius: 18,
                imageUrl: ref.watch(currentUserProvider)?.profilePictureUrl,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${ref.watch(currentUserProvider)?.firstName ?? ''} ${ref.watch(currentUserProvider)?.lastName ?? 'User'}'.trim(),
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: Colors.white, // Explicitly set to white for visibility
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here is what is happening today',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            if (isManager) ...[
              Text(
                'Workforce Overview',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ref.watch(dashboardStatsProvider).when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _MetricCard(
                      title: 'Total Employees', 
                      value: stats['totalEmployees'].toString(), 
                      icon: Icons.group_outlined
                    ),
                    _MetricCard(
                      title: 'Active Now', 
                      value: stats['activeNow'].toString(), 
                      icon: Icons.sensors_outlined
                    ),
                    _MetricCard(
                      title: 'Leave Requests', 
                      value: stats['leaveRequests'].toString(), 
                      icon: Icons.event_busy_outlined
                    ),
                    _MetricCard(
                      title: 'New Hires', 
                      value: stats['newHires'].toString(), 
                      icon: Icons.person_add_outlined
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading stats: $err')),
              ),
            ] else ...[
              ref.watch(attendanceNotifierProvider).maybeWhen(
                data: (history) {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final todayRecord = history.isNotEmpty && history.first.date.startsWith(today) ? history.first : null;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AttendanceQuickCard(record: todayRecord),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: todayRecord?.checkOutTime != null 
                            ? null 
                            : () => ref.read(attendanceNotifierProvider.notifier).checkIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: todayRecord?.checkOutTime != null ? AppTheme.backgroundLighter : AppTheme.primaryAccent,
                        ),
                        child: Text(
                          todayRecord == null ? 'CHECK IN' : (todayRecord.checkOutTime == null ? 'CHECK OUT' : 'COMPLETED'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AttendanceQuickCard(record: null),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: null,
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                orElse: () => const Center(child: Text('Failed to load attendance')),
              ),
            ],
            const SizedBox(height: 32),
            if (isManager) ...[
              Text('Management Actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Add Member',
                      icon: Icons.person_add_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditEmployeeScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'Assign Task',
                      icon: Icons.add_task,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Review Leaves',
                      icon: Icons.rate_review_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveApprovalsScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'Staff Stats',
                      icon: Icons.analytics_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffAttendanceScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Tasks', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            tasksState.when(
              data: (tasks) => tasks.isEmpty 
                ? const Center(child: Text('No tasks assigned'))
                : Column(
                    children: tasks.take(3).map((task) => Column(
                      children: [
                        _TaskItem(
                          title: task.title,
                          status: task.status,
                          due: task.dueDate ?? 'No due date',
                        ),
                        if (tasks.indexOf(task) < tasks.take(3).length - 1) const Divider(height: 32),
                      ],
                    )).toList(),
                  ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) {
                  String message = err.toString();
                  if (err is DioException && err.response?.data is Map) {
                    message = err.response?.data['error'] ?? message;
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNegative.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Error loading tasks: $message',
                      style: const TextStyle(color: AppTheme.statusNegative),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            if (isManager) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pending Approvals', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveApprovalsScreen()));
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ref.watch(pendingLeaveNotifierProvider).when(
                data: (pending) => pending.isEmpty
                  ? const Center(child: Text('No pending approvals'))
                  : Column(
                      children: pending.take(2).map((leave) => Column(
                        children: [
                          LeaveRequestItem(
                            name: leave.employeeName ?? 'Unknown',
                            type: leave.leaveType,
                            status: leave.status,
                            date: leave.startDate.substring(5),
                          ),
                          if (pending.indexOf(leave) == 0 && pending.length > 1) const Divider(height: 32),
                        ],
                      )).toList(),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppTheme.primaryAccent, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: AppTheme.primaryAccent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryAccent, size: 32),
              const SizedBox(height: 8),
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String status;
  final String due;

  const _TaskItem({required this.title, required this.status, required this.due});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Due: $due'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(status, style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 11)),
      ),
    );
  }
}

class LeaveRequestItem extends StatelessWidget {
  final String name;
  final String type;
  final String status;
  final String date;

  const LeaveRequestItem({
    super.key,
    required this.name,
    required this.type,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(type, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.toUpperCase() == 'APPROVED' ? AppTheme.statusPositive.withOpacity(0.2) : AppTheme.statusPending.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: status.toUpperCase() == 'APPROVED' ? AppTheme.statusPositive : AppTheme.statusPending,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(date, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _AttendanceQuickCard extends StatelessWidget {
  final AttendanceModel? record;
  const _AttendanceQuickCard({this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm a').format(DateTime.now()),
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo('Check In', record?.checkInTime?.substring(11, 16) ?? '--:--'),
                _buildTimeInfo('Check Out', record?.checkOutTime?.substring(11, 16) ?? '--:--'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
