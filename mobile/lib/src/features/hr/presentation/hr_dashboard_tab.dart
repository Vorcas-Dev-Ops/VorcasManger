import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'hr_notifiers.dart';
import '../../employee/presentation/employee_notifiers.dart';
import '../../leave/presentation/leave_notifier.dart';
import '../../leave/presentation/leave_approvals_screen.dart';

import '../../employee/presentation/edit_employee_screen.dart';

class HrDashboardTab extends ConsumerStatefulWidget {
  const HrDashboardTab({super.key});

  @override
  ConsumerState<HrDashboardTab> createState() => _HrDashboardTabState();
}

class _HrDashboardTabState extends ConsumerState<HrDashboardTab> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
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
      final status = ref.read(attendanceNotifierProvider).valueOrNull;
      if (status != null) {
        if (status['status'] == 'ON_BREAK' && status['currentBreakStart'] != null) {
          final startTime = DateTime.parse(status['currentBreakStart']).toLocal();
          if (mounted) {
            setState(() {
              final diff = DateTime.now().difference(startTime);
              _elapsed = diff.isNegative ? Duration.zero : diff;
            });
          }
        } else if (_elapsed != Duration.zero) {
          if (mounted) {
            setState(() {
              _elapsed = Duration.zero;
            });
          }
        }

        if (status['status'] == 'CHECKED_IN' || status['status'] == 'ON_BREAK') {
          final checkInTimeStr = status['checkInTime'];
          if (checkInTimeStr != null) {
            final checkInTime = DateTime.parse(checkInTimeStr).toLocal();
            final accumulatedBreakSeconds = status['accumulatedBreakSeconds'] ?? 0;
            int totalBreakSecs = accumulatedBreakSeconds;
            
            if (status['status'] == 'ON_BREAK' && status['currentBreakStart'] != null) {
              final startTime = DateTime.parse(status['currentBreakStart']).toLocal();
              totalBreakSecs += DateTime.now().difference(startTime).inSeconds;
            }
            
            if (mounted) {
              setState(() {
                final diff = DateTime.now().difference(checkInTime) - Duration(seconds: totalBreakSecs);
                _sessionElapsed = diff.isNegative ? Duration.zero : diff;
              });
            }
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
    final attendanceStatus = ref.watch(attendanceNotifierProvider);
    final summaryAsync = ref.watch(hrDashboardSummaryProvider);
    final workforceAsync = ref.watch(hrWorkforceStatsProvider);
    final pendingLeavesAsync = ref.watch(pendingLeaveNotifierProvider);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceNotifierProvider);
          ref.invalidate(hrDashboardSummaryProvider);
          ref.invalidate(hrWorkforceStatsProvider);
          ref.invalidate(pendingLeaveNotifierProvider);
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
                    const Text('HR Overview', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('REAL-TIME WORKFORCE INTELLIGENCE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                          if (isCheckedIn) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Session: ${_formatDuration(_sessionElapsed)}',
                              style: const TextStyle(color: SuperAdminTheme.statusPositive, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
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

            // Status Toggle (Active / Break)
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
                                  'Break Duration: ${_formatDuration(_elapsed)}',
                                  style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          else
                            Text(
                              isNotCheckedIn ? 'You are not checked in' : 'Active Status',
                              style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11),
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

            summaryAsync.when(
              data: (summary) {
                final totalEmployees = summary['totalEmployees'] ?? 0;
                final activeNow = summary['activeNow'] ?? 0;
                final newHires = summary['newHires'] ?? 0;

                return Column(
                  children: [
                    // Total Headcount
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL HEADCOUNT', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('$totalEmployees', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.0)),
                              const SizedBox(width: 8),
                              const Text('+2.4%', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text('$activeNow Active Now', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              const Text('\u2022', style: TextStyle(color: SuperAdminTheme.textSecondary)),
                              const SizedBox(width: 12),
                              Text('$newHires New Hires (30d)', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
              error: (e, st) => Text('Error loading summary: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),

            // Workforce Stats Card
            workforceAsync.when(
              data: (stats) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DIVERSITY & ROLE SNAPSHOT', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          SizedBox(
                            width: 120, height: 120,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1.0, strokeWidth: 12, color: SuperAdminTheme.surfaceLighter,
                                ),
                                CircularProgressIndicator(
                                  value: 0.7, strokeWidth: 12, color: SuperAdminTheme.primaryOrange,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('70%', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    Text('INCLUSIVE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: stats.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: SuperAdminTheme.primaryOrange, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('${s['label']}: ${s['value']}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                  ],
                                ),
                              )).toList(),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange))),
              error: (e, st) => Text('Error loading stats: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting HR Data...')));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: SuperAdminTheme.surfaceLighter),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Export Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditEmployeeScreen(employee: null),
                        ),
                      ).then((_) => ref.refresh(hrStaffListProvider));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuperAdminTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Employee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Leave Requests Section
            pendingLeavesAsync.when(
              data: (leaves) {
                final pendingCount = leaves.length;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeaveApprovalsScreen()),
                    ).then((_) => ref.invalidate(pendingLeaveNotifierProvider));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SuperAdminTheme.surfaceLighter.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PENDING LEAVE REQUESTS',
                              style: TextStyle(
                                color: SuperAdminTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Awaiting Action',
                                  style: TextStyle(
                                    color: SuperAdminTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SuperAdminTheme.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: SuperAdminTheme.primaryOrange,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
              ),
              error: (e, st) => Text('Error loading leaves: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
