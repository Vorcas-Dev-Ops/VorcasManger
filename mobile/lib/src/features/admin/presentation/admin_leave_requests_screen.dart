import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/common_widgets/common_avatar.dart';

class AdminLeaveRequestsScreen extends ConsumerStatefulWidget {
  const AdminLeaveRequestsScreen({super.key});

  @override
  ConsumerState<AdminLeaveRequestsScreen> createState() => _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends ConsumerState<AdminLeaveRequestsScreen> {
  List<Map<String, dynamic>> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(adminRepositoryProvider).getPendingLeaves();
      if (mounted) setState(() { _leaves = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _handleAction(int leaveId, String status) async {
    try {
      final user = ref.read(currentUserProvider);
      final approverId = user?.employeeId ?? 0;
      await ref.read(adminRepositoryProvider).approveLeave(leaveId, status, approverId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave ${status.toLowerCase()} successfully'),
          backgroundColor: status == 'APPROVED' ? Colors.green : Colors.redAccent,
        ),
      );
      _load(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update leave request'), backgroundColor: Colors.red),
      );
    }
  }

  Color _typeColor(String? type) {
    if (type == null) return SuperAdminTheme.primaryOrange;
    final t = type.toLowerCase();
    if (t.contains('sick')) return Colors.blueAccent;
    if (t.contains('casual')) return const Color(0xFF8C471E);
    if (t.contains('annual') || t.contains('vacation')) return SuperAdminTheme.primaryOrange;
    return SuperAdminTheme.primaryOrange;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  int _daysBetween(String? start, String? end) {
    if (start == null || end == null) return 1;
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return e.difference(s).inDays + 1;
    } catch (_) {
      return 1;
    }
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
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange))
            : RefreshIndicator(
                color: SuperAdminTheme.primaryOrange,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    const Text('OPERATIONS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const Text('Leave Requests', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Manage pending absence requests across your\ndepartment.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PENDING', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                const SizedBox(height: 8),
                                Text('${_leaves.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STATUS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                SizedBox(height: 8),
                                Text('AWAITING', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Leave list
                    if (_leaves.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                              SizedBox(height: 16),
                              Text('No pending requests', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('All leave requests have been processed.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._leaves.map((leave) => _buildLeaveCard(leave)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final name = leave['employee_name'] ?? '${leave['first_name'] ?? ''} ${leave['last_name'] ?? ''}';
    final leaveType = leave['leave_type'] ?? 'Leave';
    final startDate = leave['start_date'] ?? '';
    final endDate = leave['end_date'] ?? '';
    final reason = leave['reason'] ?? 'No reason provided';
    final leaveId = leave['id'];
    final days = _daysBetween(startDate, endDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CommonAvatar(radius: 16, imageUrl: leave['profile_picture_url']),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _typeColor(leaveType).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(leaveType.toUpperCase(), style: TextStyle(color: _typeColor(leaveType), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary, size: 14),
                const SizedBox(width: 8),
                Text('${_formatDate(startDate)} — ${_formatDate(endDate)} ($days ${days == 1 ? 'DAY' : 'DAYS'})',
                    style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text('"$reason"', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(leaveId, 'REJECTED'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: SuperAdminTheme.surfaceLighter),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(leaveId, 'APPROVED'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuperAdminTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
