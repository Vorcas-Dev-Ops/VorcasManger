import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../employee/presentation/employee_notifiers.dart';
import '../../leave/data/leave_repository.dart';
import 'tl_notifiers.dart';
import 'tl_schedule_form_screen.dart';
import 'tl_task_report_screen.dart';
import '../../../core/common_widgets/common_avatar.dart';

class TlDashboardTab extends ConsumerStatefulWidget {
  const TlDashboardTab({super.key});

  @override
  ConsumerState<TlDashboardTab> createState() => _TlDashboardTabState();
}

class _TlDashboardTabState extends ConsumerState<TlDashboardTab> {
  Timer? _timer;
  Duration _elapsedBreak = Duration.zero;
  Duration _sessionElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final status = ref.read(attendanceNotifierProvider).valueOrNull;
      if (status != null) {
        if (status['status'] == 'ON_BREAK' && status['currentBreakStart'] != null) {
          final startTime = DateTime.parse(status['currentBreakStart']).toLocal();
          setState(() {
            final diff = DateTime.now().difference(startTime);
            _elapsedBreak = diff.isNegative ? Duration.zero : diff;
          });
        } else if (_elapsedBreak != Duration.zero) {
          setState(() {
            _elapsedBreak = Duration.zero;
          });
        }

        final currentStatus = status['status'];
        if (currentStatus == 'CHECKED_IN' || currentStatus == 'ON_BREAK' || currentStatus == 'CHECKED_OUT') {
          final checkInTimeStr = status['checkInTime'];
          if (checkInTimeStr != null) {
            final checkInTime = DateTime.parse(checkInTimeStr).toLocal();
            
            // Use check-out time if available, otherwise use now
            final endTime = (currentStatus == 'CHECKED_OUT' && status['checkOutTime'] != null)
                ? DateTime.parse(status['checkOutTime']).toLocal()
                : DateTime.now();

            final accumulatedBreakSeconds = status['accumulatedBreakSeconds'] ?? 0;
            int totalBreakSecs = accumulatedBreakSeconds;
            
            if (currentStatus == 'ON_BREAK' && status['currentBreakStart'] != null) {
              final startTime = DateTime.parse(status['currentBreakStart']).toLocal();
              totalBreakSecs += DateTime.now().difference(startTime).inSeconds;
            }
            
            setState(() {
              final diff = endTime.difference(checkInTime) - Duration(seconds: totalBreakSecs);
              _sessionElapsed = diff.isNegative ? Duration.zero : diff;
            });
          }
        }
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final statsAsync = ref.watch(tlDashboardStatsProvider);
    final attendanceStatus = ref.watch(attendanceNotifierProvider);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: statsAsync.when(
        data: (stats) {
          final taskOverview = stats['taskOverview'] ?? {'TODO': 0, 'IN_PROGRESS': 0, 'DONE': 0};
          final todo = taskOverview['TODO'] ?? 0;
          final inProgress = taskOverview['IN_PROGRESS'] ?? 0;
          final done = taskOverview['DONE'] ?? 0;
          final totalTasks = todo + inProgress + done;
          final completionRate = totalTasks > 0 ? (done / totalTasks * 100).toInt() : 0;

          final teamCount = stats['teamCount'] ?? 0;
          final presentCount = stats['presentCount'] ?? 0;
          final metrics = stats['metrics'] ?? {'velocity': '0', 'bugs': '0', 'uptime': '100%'};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tlDashboardStatsProvider);
              ref.invalidate(attendanceNotifierProvider);
              ref.invalidate(tlTeamLeavesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        const Text('Team Dashboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Squad Snapshot \u2022 Sprint Real-time', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    attendanceStatus.when(
                      data: (status) {
                        final currentStatus = status?['status'] ?? 'NOT_CHECKED_IN';
                        final isCheckedIn = currentStatus == 'CHECKED_IN' || currentStatus == 'ON_BREAK';
                        final isCheckedOut = currentStatus == 'CHECKED_OUT';
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: attendanceStatus.isLoading ? null : () {
                                if (isCheckedIn) {
                                  ref.read(attendanceNotifierProvider.notifier).checkOut(status!['attendanceId']);
                                } else {
                                  ref.read(attendanceNotifierProvider.notifier).checkIn();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn 
                                  ? Colors.redAccent 
                                  : SuperAdminTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide.none,
                                ),
                                elevation: 4,
                              ),
                              child: attendanceStatus.isLoading 
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    isCheckedIn ? 'CHECK-OUT' : 'CHECK-IN', 
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                                  ),
                            ),
                            if ((isCheckedIn || isCheckedOut) && status?['checkInTime'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'In: ${DateFormat('hh:mm a').format(DateTime.parse(status!['checkInTime']).toLocal())}',
                                style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Session: ${_formatDuration(_sessionElapsed)}',
                                style: const TextStyle(color: SuperAdminTheme.statusPositive, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: SuperAdminTheme.surfaceLighter.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SuperAdminTheme.primaryOrange)),
                      ),
                      error: (e, st) => IconButton(
                        icon: const Icon(Icons.error_outline, color: SuperAdminTheme.statusNegative, size: 20),
                        onPressed: () => ref.invalidate(attendanceNotifierProvider),
                        tooltip: e.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Toggle (Active / Break) - MOVED HERE
                attendanceStatus.maybeWhen(
                  data: (status) {
                    final currentStatus = status?['status'] ?? 'NOT_CHECKED_IN';
                    final isNotCheckedIn = currentStatus == 'NOT_CHECKED_IN';
                    final isOnBreak = currentStatus == 'ON_BREAK';
                    final attendanceId = status?['attendanceId'];
                    final breakId = status?['breakId'];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SuperAdminTheme.surfaceLighter),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current State', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (isOnBreak) 
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: SuperAdminTheme.primaryOrange, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Current Break: ${_formatDuration(_elapsedBreak)}',
                                      style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isNotCheckedIn ? 'You are not checked in' : 'Active Status',
                                      style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11),
                                    ),
                                    if (!isNotCheckedIn) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total Break: ${((status!['accumulatedBreakSeconds'] ?? 0) / 60).toStringAsFixed(1)}m',
                                        style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: SuperAdminTheme.backgroundBlack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: (isNotCheckedIn || !isOnBreak) ? null : () {
                                    ref.read(attendanceNotifierProvider.notifier).endBreak(breakId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !isOnBreak ? SuperAdminTheme.primaryOrange.withOpacity(isNotCheckedIn ? 0.3 : 1.0) : Colors.transparent, 
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Active', style: TextStyle(color: !isOnBreak ? Colors.white.withOpacity(isNotCheckedIn ? 0.5 : 1.0) : SuperAdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: (isNotCheckedIn || isOnBreak) ? null : () {
                                    ref.read(attendanceNotifierProvider.notifier).startBreak(attendanceId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOnBreak ? SuperAdminTheme.primaryOrange : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Break', style: TextStyle(color: isOnBreak ? Colors.white : SuperAdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),

              // Task Overview Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SuperAdminTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SuperAdminTheme.surfaceLighter),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: SuperAdminTheme.primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.analytics_rounded, color: SuperAdminTheme.primaryOrange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text('Task Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('Current sprint real-time progress', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: SuperAdminTheme.backgroundBlack,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: SuperAdminTheme.primaryOrange.withOpacity(0.3)),
                          ),
                          child: Text('$completionRate% DONE', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Key Stats Row
                    Row(
                      children: [
                        _buildQuickStat('OVERDUE', stats['overdueCount']?.toString() ?? '0', Colors.red),
                        const SizedBox(width: 12),
                        _buildQuickStat('PRIORITY', stats['highPriorityCount']?.toString() ?? '0', SuperAdminTheme.primaryOrange),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _ProgressBarRow(
                      label: 'TO-DO', 
                      count: '$todo', 
                      progress: totalTasks > 0 ? todo / totalTasks : 0, 
                      color: SuperAdminTheme.textSecondary.withOpacity(0.5)
                    ),
                    const SizedBox(height: 16),
                    _ProgressBarRow(
                      label: 'IN-PROGRESS', 
                      count: '$inProgress', 
                      progress: totalTasks > 0 ? inProgress / totalTasks : 0, 
                      color: SuperAdminTheme.primaryOrange
                    ),
                    const SizedBox(height: 16),
                    _ProgressBarRow(
                      label: 'COMPLETED', 
                      count: '$done', 
                      progress: totalTasks > 0 ? done / totalTasks : 0, 
                      color: SuperAdminTheme.statusPositive
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => const TlTaskReportScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SuperAdminTheme.primaryOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              shadowColor: SuperAdminTheme.primaryOrange.withOpacity(0.4),
                            ),
                            child: const Text('VIEW DETAILED REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => const TlScheduleFormScreen()));
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: SuperAdminTheme.backgroundBlack,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: SuperAdminTheme.surfaceLighter.withOpacity(0.8)),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Icon(Icons.add_task_rounded, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),


              // Who's In Today
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Who\'s In Today', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Team Attendance\nSnapshot', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$presentCount / $teamCount\nPresent', textAlign: TextAlign.right, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('TODAY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (stats['squad'] != null && (stats['squad'] as List).isNotEmpty)
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: (stats['squad'] as List).length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final member = (stats['squad'] as List)[index];
                            final isOnline = member['status'] == 'ONLINE';
                            return Column(
                              children: [
                                Stack(
                                  children: [
                                    CommonAvatar(
                                      radius: 20,
                                      imageUrl: member['profile_picture_url'],
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isOnline ? SuperAdminTheme.statusPositive : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: SuperAdminTheme.surfaceCard, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (member['name'] as String? ?? 'Unknown').split(' ').first,
                                  style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      const Text('No squad members assigned', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Pending Leave Requests Section
              const Text('PENDING ACTIONS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              const Text('Leave Requests', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ref.watch(tlTeamLeavesProvider).when(
                data: (leaves) {
                  if (leaves.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Text('No pending leave requests', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: leaves.map((leave) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _LeaveActionCard(
                        leaveId: leave['id'],
                        name: leave['name'] ?? 'Unknown',
                        role: leave['role'] ?? 'Employee',
                        avatarUrl: leave['avatarUrl'],
                        type: leave['type']?.toString().toUpperCase() ?? 'LEAVE',
                        durationText: '${DateFormat('MMM d').format(DateTime.parse(leave['startDate']))} - ${DateFormat('MMM d').format(DateTime.parse(leave['endDate']))}',
                        daysText: '${DateTime.parse(leave['endDate']).difference(DateTime.parse(leave['startDate'])).inDays + 1} Days',
                        reason: leave['reason'] ?? '',
                        onApprove: () async {
                          try {
                            final user = ref.read(currentUserProvider);
                            if (user == null) return;
                            
                            await ref.read(leaveRepositoryProvider).updateStatus(
                              leaveId: leave['id'],
                              approverId: user.employeeId,
                              status: 'APPROVED',
                            );
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Leave request approved')),
                              );
                              ref.invalidate(tlTeamLeavesProvider);
                              ref.invalidate(tlDashboardStatsProvider);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        onReject: () async {
                          try {
                            final user = ref.read(currentUserProvider);
                            if (user == null) return;
                            
                            await ref.read(leaveRepositoryProvider).updateStatus(
                              leaveId: leave['id'],
                              approverId: user.employeeId,
                              status: 'REJECTED',
                            );
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Leave request rejected'), backgroundColor: Colors.red),
                              );
                              ref.invalidate(tlTeamLeavesProvider);
                              ref.invalidate(tlDashboardStatsProvider);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
                error: (e, st) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Error loading leaves: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    ),
  );
}

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SuperAdminTheme.backgroundBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final String count;
  final double progress;
  final Color color;

  const _ProgressBarRow({required this.label, required this.count, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: SuperAdminTheme.backgroundBlack,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _MetricTile({required this.icon, required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.0)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(unit, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceAvatarCard extends StatelessWidget {
  final String name;
  final String status;
  final Color dotColor;
  final String avatarUrl;

  const _AttendanceAvatarCard({required this.name, required this.status, required this.dotColor, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    // We want a 2-column or 3-column wrap. With spacing, maybe calculate fixed width.
    // Let's just use fixed width to mimic the screenshot grid.
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 40 - 40 - 12) / 2; // margins

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Stack(
            children: [
               CommonAvatar(
                  radius: 20,
                  imageUrl: avatarUrl,
                  isSquare: true,
                  borderRadius: 8,
               ),
               Positioned(
                 bottom: -2,
                 right: -2,
                 child: Container(
                   width: 12,
                   height: 12,
                   decoration: BoxDecoration(
                     color: dotColor,
                     shape: BoxShape.circle,
                     border: Border.all(color: SuperAdminTheme.backgroundBlack, width: 2),
                   ),
                 ),
               ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 4),
                Text(status, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveActionCard extends StatelessWidget {
  final int leaveId;
  final String name;
  final String role;
  final String? avatarUrl;
  final String type;
  final String durationText;
  final String daysText;
  final String reason;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveActionCard({
    required this.leaveId,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.type,
    required this.durationText,
    required this.daysText,
    required this.reason,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: SuperAdminTheme.surfaceLighter)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CommonAvatar(radius: 20, imageUrl: avatarUrl),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(role, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: SuperAdminTheme.primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(type, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _LeaveDetailRow(label: 'DURATION', value: durationText),
              Container(width: 1, height: 24, color: SuperAdminTheme.surfaceLighter, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _LeaveDetailRow(label: 'DAYS', value: daysText),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('REASON', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Text(reason, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('REJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SuperAdminTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('APPROVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _LeaveDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
