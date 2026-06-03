import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/leave_repository.dart';
import '../domain/leave_model.dart';
import '../../auth/presentation/auth_notifier.dart';

class LeaveApprovalsScreen extends ConsumerStatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  ConsumerState<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends ConsumerState<LeaveApprovalsScreen> {
  late Future<List<LeaveModel>> _pendingLeavesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingLeavesFuture = ref.read(leaveRepositoryProvider).getPendingLeaves();
    });
  }

  Future<void> _updateStatus(int leaveId, String status) async {
    final currentUser = ref.read(currentUserProvider);
    final approverId = currentUser?.employeeId ?? 0;

    try {
      await ref.read(leaveRepositoryProvider).updateStatus(
        leaveId: leaveId,
        approverId: approverId,
        status: status,
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approvals'),
      ),
      body: FutureBuilder<List<LeaveModel>>(
        future: _pendingLeavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final leaves = snapshot.data ?? [];
          if (leaves.isEmpty) {
            return const Center(child: Text('No pending leave requests'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: leaves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final leave = leaves[index];
                return _LeaveApprovalCard(
                  leave: leave,
                  onApprove: () => _updateStatus(leave.id, 'APPROVED'),
                  onReject: () => _updateStatus(leave.id, 'REJECTED'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LeaveApprovalCard extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveApprovalCard({
    required this.leave,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
                    leave.employeeName ?? 'Employee #${leave.employeeId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    _TypeBadge(type: leave.status.replaceAll('_', ' ')),
                    const SizedBox(width: 8),
                    _TypeBadge(type: leave.leaveType),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${leave.startDate.substring(0, 10)} to ${leave.endDate.substring(0, 10)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              leave.reason ?? 'No reason provided',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusNegative,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusPositive,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
