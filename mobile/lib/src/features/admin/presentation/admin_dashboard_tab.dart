import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import 'admin_leave_requests_screen.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(adminRepositoryProvider).getAdminDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      );
    }

    final totalEmployees = _data?['totalEmployees'] ?? 0;
    final activeTasks = _data?['activeTasks'] ?? 0;
    final pendingLeaves = _data?['pendingLeaves'] ?? 0;
    final presenceRate = (_data?['presenceRate'] ?? 0).toDouble();
    final weeklyAttendance = (_data?['weeklyAttendance'] as List?) ?? [];
    final alerts = (_data?['alerts'] as List?) ?? [];

    // Calculate max for bar chart scaling
    double maxCount = 1;
    for (final entry in weeklyAttendance) {
      final c = (entry['count'] ?? 0).toDouble();
      if (c > maxCount) maxCount = c;
    }

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        color: SuperAdminTheme.primaryOrange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text('SYSTEM ADMINISTRATOR', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const Text('Admin Dashboard', style: TextStyle(color: SuperAdminTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: SuperAdminTheme.primaryOrange, shape: BoxShape.circle))),
                const SizedBox(width: 8),
                Text('System Online • ${_data?['activeNow'] ?? 0} active now', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            // Total Employees Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Positioned(right: -10, top: -10, child: Icon(Icons.people, color: SuperAdminTheme.surfaceLighter, size: 80)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL EMPLOYEES', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Text('$totalEmployees', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(height: 3, width: 200, color: SuperAdminTheme.primaryOrange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Tasks + Pending Leave
            Row(
              children: [
                Expanded(
                  child: _HalfCard(title: 'ACTIVE TASKS', value: '$activeTasks', icon: Icons.assignment),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HalfCard(
                    title: 'PENDING LEAVE',
                    value: '$pendingLeaves',
                    icon: Icons.calendar_today,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLeaveRequestsScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Workforce Overview (Weekly Attendance Bar Chart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WORKFORCE OVERVIEW', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 175,
                    child: weeklyAttendance.isEmpty
                        ? const Center(child: Text('No attendance data', style: TextStyle(color: SuperAdminTheme.textSecondary)))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: weeklyAttendance.map<Widget>((entry) {
                              final count = (entry['count'] ?? 0).toDouble();
                              final label = (entry['day_label'] ?? '').toString().substring(0, 3);
                              final barHeight = (count / maxCount) * 140;
                              final pct = totalEmployees > 0 ? '${(count / totalEmployees * 100).round()}%' : '';
                              final isMax = count == maxCount;
                              return _Bar(height: barHeight.clamp(8, 140), label: label, isActive: isMax, valueLabel: isMax ? pct : null);
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: SuperAdminTheme.surfaceLighter),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('PRESENCE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('$presenceRate%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('ACTIVE NOW', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('${_data?['activeNow'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Alerts
            const Text('RECENT ACTIVITY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              const _AlertCard(title: 'No recent activity', subtitle: 'All clear', icon: Icons.check_circle_outline)
            else
              ...alerts.map<Widget>((alert) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlertCard(
                    title: alert['title'] ?? '',
                    subtitle: alert['subtitle'] ?? '',
                    icon: Icons.event_note_outlined,
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _HalfCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _HalfCard({required this.title, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SuperAdminTheme.primaryOrange, size: 20),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final String label;
  final bool isActive;
  final String? valueLabel;

  const _Bar({required this.height, required this.label, this.isActive = false, this.valueLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: height,
          width: 40,
          decoration: BoxDecoration(
            color: isActive ? SuperAdminTheme.primaryOrange : const Color(0xFF8C471E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          alignment: Alignment.topCenter,
          child: isActive && valueLabel != null ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(valueLabel!, style: const TextStyle(color: SuperAdminTheme.backgroundBlack, fontSize: 10, fontWeight: FontWeight.bold)),
          ) : null,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isActive ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AlertCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: SuperAdminTheme.textSecondary),
        ],
      ),
    );
  }
}
