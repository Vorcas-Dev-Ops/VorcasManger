import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/super_admin_theme.dart';
import '../../data/super_admin_providers.dart';
import '../../data/super_admin_repository.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../../core/common_widgets/common_avatar.dart';

class SuperAdminLeaveTab extends ConsumerWidget {
  const SuperAdminLeaveTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(superAdminPendingLeavesProvider);

    final user = ref.watch(currentUserProvider);
    final displayRole = user?.roleName.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase()).join(' ') ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard, color: SuperAdminTheme.primaryOrange),
            const SizedBox(width: 8),
            Text(
              displayRole,
              style: const TextStyle(
                color: SuperAdminTheme.primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(superAdminPendingLeavesProvider),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CommonAvatar(
              radius: 16,
              imageUrl: user?.profilePictureUrl,
            ),
          )
        ],
      ),
      body: leavesAsync.when(
        data: (leaves) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(superAdminPendingLeavesProvider.future),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: SuperAdminTheme.primaryOrange, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('OPERATIONS LIVE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Leave Management', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(
                    '${leaves.length} pending requests require your attention.',
                    style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  _SummaryMetrics(count: leaves.length),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending Requests', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (leaves.isNotEmpty)
                        Text(
                          '${leaves.length} TOTAL',
                          style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (leaves.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text('No pending leave requests.', style: TextStyle(color: SuperAdminTheme.textSecondary)),
                      ),
                    )
                  else
                    ...leaves.map((leave) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _LeaveRequestCard(
                        leaveId: leave['id'],
                        name: '${leave['first_name']} ${leave['last_name']}',
                        role: '${leave['role_name'] ?? 'Staff'} • ${leave['department_name'] ?? 'Unknown'}',
                        startDate: leave['start_date'],
                        endDate: leave['end_date'],
                        type: leave['leave_type'],
                        reason: leave['reason'] ?? 'No reason provided',
                        profilePictureUrl: leave['profile_picture_url'],
                        onProcessed: () => ref.refresh(superAdminPendingLeavesProvider),
                      ),
                    )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  final int count;
  const _SummaryMetrics({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PENDING REQUESTS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (count > 0) const Icon(Icons.trending_up, color: SuperAdminTheme.statusNegative, size: 16),
              const SizedBox(width: 4),
              const Text('Action Required', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final int leaveId;
  final String name;
  final String role;
  final String startDate;
  final String endDate;
  final String type;
  final String reason;
  final String? profilePictureUrl;
  final VoidCallback onProcessed;

  const _LeaveRequestCard({
    required this.leaveId,
    required this.name,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reason,
    this.profilePictureUrl,
    required this.onProcessed,
  });

  Future<void> _handleProcess(BuildContext context, WidgetRef ref, String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      );

      // Get the actual current employee ID from auth state
      final approverId = ref.read(currentUserProvider)?.employeeId ?? 0;
      await ref.read(superAdminRepositoryProvider).approveLeave(leaveId, status, approverId);
      
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request $status')),
        );
        onProcessed();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: SuperAdminTheme.statusNegative),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = DateFormat('MMM dd').format(DateTime.parse(startDate));
    final end = DateFormat('MMM dd').format(DateTime.parse(endDate));
    final duration = '$start - $end';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommonAvatar(
                radius: 20,
                imageUrl: profilePictureUrl,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(role, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DURATION', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(duration, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TYPE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.backgroundBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SuperAdminTheme.surfaceLighter),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, 
                            height: 6, 
                            decoration: BoxDecoration(
                              color: type == 'VACATION' ? SuperAdminTheme.primaryOrange : Colors.blueAccent, 
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(type, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('REASON', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(reason, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleProcess(context, ref, 'REJECTED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SuperAdminTheme.backgroundBlack,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: SuperAdminTheme.surfaceLighter),
                  ),
                  child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleProcess(context, ref, 'APPROVED'),
                  child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
