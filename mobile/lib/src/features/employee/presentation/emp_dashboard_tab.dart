import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import 'employee_notifiers.dart';

class EmpDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback? onTasksTapped;
  const EmpDashboardTab({super.key, this.onTasksTapped});

  @override
  ConsumerState<EmpDashboardTab> createState() => _EmpDashboardTabState();
}

class _EmpDashboardTabState extends ConsumerState<EmpDashboardTab> {
  Timer? _timer;
  Duration _elapsedBreak = Duration.zero;
  Duration _sessionElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Start periodic timer to refresh UI if we're on break
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final statusData = ref.read(attendanceNotifierProvider).valueOrNull;
      if (statusData != null) {
        if (statusData['status'] == 'ON_BREAK') {
          final startTimeStr = statusData['currentBreakStart'];
          if (startTimeStr != null) {
            final startTime = DateTime.parse(startTimeStr).toLocal();
            setState(() {
              final diff = DateTime.now().difference(startTime);
              _elapsedBreak = diff.isNegative ? Duration.zero : diff;
            });
          }
        }
        
        if (statusData['status'] == 'CHECKED_IN' || statusData['status'] == 'ON_BREAK') {
          final checkInTimeStr = statusData['checkInTime'];
          if (checkInTimeStr != null) {
            final checkInTime = DateTime.parse(checkInTimeStr).toLocal();
            final accumulatedBreakSeconds = statusData['accumulatedBreakSeconds'] ?? 0;
            int totalBreakSecs = accumulatedBreakSeconds;
            
            if (statusData['status'] == 'ON_BREAK') {
              final startTimeStr = statusData['currentBreakStart'];
              if (startTimeStr != null) {
                final startTime = DateTime.parse(startTimeStr).toLocal();
                totalBreakSecs += DateTime.now().difference(startTime).inSeconds;
              }
            }
            
            setState(() {
              final diff = DateTime.now().difference(checkInTime) - Duration(seconds: totalBreakSecs);
              _sessionElapsed = diff.isNegative ? Duration.zero : diff;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final attendanceStatus = ref.watch(attendanceNotifierProvider);
    final tasks = ref.watch(taskNotifierProvider);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    final hour = now.hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceNotifierProvider);
          ref.invalidate(taskNotifierProvider);
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
                    Text('$greeting,\n${user?.firstName ?? 'Employee'}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Check-In Widget
            attendanceStatus.when(
                  data: (status) {
                    final currentStatus = status?['status'] ?? 'NOT_CHECKED_IN';
                    final isCheckedOut = currentStatus == 'CHECKED_OUT';
                    final isCheckedIn = currentStatus == 'CHECKED_IN' || currentStatus == 'ON_BREAK';
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: SuperAdminTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SuperAdminTheme.surfaceLighter),
                      ),
                      child: Column(
                        children: [
                          const Text('SHIFT STATUS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: SuperAdminTheme.backgroundBlack,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isCheckedIn ? SuperAdminTheme.statusPositive.withOpacity(0.5) : (isCheckedOut ? SuperAdminTheme.textSecondary.withOpacity(0.5) : SuperAdminTheme.primaryOrange.withOpacity(0.5))),
                            ),
                            child: Text(
                              isCheckedIn ? 'CHECKED IN' : (isCheckedOut ? 'CHECKED OUT' : 'NOT CHECKED IN'),
                              style: TextStyle(color: isCheckedIn ? SuperAdminTheme.statusPositive : (isCheckedOut ? SuperAdminTheme.textSecondary : SuperAdminTheme.primaryOrange), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: attendanceStatus.isLoading ? null : () {
                                if (isCheckedIn) {
                                  ref.read(attendanceNotifierProvider.notifier).checkOut(status!['attendanceId']);
                                } else {
                                  ref.read(attendanceNotifierProvider.notifier).checkIn();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn ? Colors.redAccent : SuperAdminTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: (isCheckedIn ? Colors.redAccent : SuperAdminTheme.primaryOrange).withOpacity(0.5),
                              ),
                              child: attendanceStatus.isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    isCheckedIn ? 'CHECK-OUT' : 'CHECK-IN',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isCheckedIn || isCheckedOut)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login, color: SuperAdminTheme.textSecondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Check-in: ${DateFormat('hh:mm a').format(DateTime.parse(status!['checkInTime']).toLocal())}', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (isCheckedIn)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_outlined, color: SuperAdminTheme.statusPositive, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Active Session: ${_formatDuration(_sessionElapsed)}', style: const TextStyle(color: SuperAdminTheme.statusPositive, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                else if (isCheckedOut && status['checkOutTime'] != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, color: SuperAdminTheme.textSecondary, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Check-out: ${DateFormat('hh:mm a').format(DateTime.parse(status['checkOutTime']).toLocal())}', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                              ],
                            )
                          else
                            const Text(
                              'Location verified: Main Headquarters (Office A)',
                              style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange),
                  )),
                  error: (e, st) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.statusNegative.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SuperAdminTheme.statusNegative.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: SuperAdminTheme.statusNegative, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          e.toString().contains('within 100m') ? 'OUTSIDE GEOFENCE' : 'ATTENDANCE ERROR',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(attendanceNotifierProvider),
                          child: const Text('RETRY', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 24),

            // Status Toggle (Active / Break)
            attendanceStatus.maybeWhen(
              data: (status) {
                final currentStatus = status?['status'] ?? 'NOT_CHECKED_IN';
                final isNotCheckedIn = currentStatus == 'NOT_CHECKED_IN' || currentStatus == 'CHECKED_OUT';
                final isOnBreak = currentStatus == 'ON_BREAK';
                final attendanceId = status?['attendanceId'];
                final breakId = status?['breakId'];
                
                final accumulatedBreakSeconds = status?['accumulatedBreakSeconds'] ?? 0;
                final totalBreakSeconds = isOnBreak ? accumulatedBreakSeconds + _elapsedBreak.inSeconds : accumulatedBreakSeconds;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SuperAdminTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current State', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (isOnBreak || totalBreakSeconds > 0)
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: SuperAdminTheme.primaryOrange, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Total Break Time: ${_formatDuration(Duration(seconds: totalBreakSeconds))}',
                                  style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          else
                            Text(
                              isNotCheckedIn ? 'You are not active' : 'You are currently Active',
                              style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                            ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: SuperAdminTheme.backgroundBlack,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: (isNotCheckedIn || !isOnBreak) ? null : () {
                                ref.read(attendanceNotifierProvider.notifier).endBreak(breakId);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isOnBreak ? SuperAdminTheme.primaryOrange.withOpacity(isNotCheckedIn ? 0.3 : 1.0) : Colors.transparent, 
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text('Active', style: TextStyle(color: !isOnBreak ? Colors.white.withOpacity(isNotCheckedIn ? 0.5 : 1.0) : SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            GestureDetector(
                              onTap: (isNotCheckedIn || isOnBreak) ? null : () {
                                ref.read(attendanceNotifierProvider.notifier).startBreak(attendanceId);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isOnBreak ? SuperAdminTheme.primaryOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text('Break', style: TextStyle(color: isOnBreak ? Colors.white : SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
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

            // My Tasks Overview
            tasks.when(
              data: (taskList) {
                final pendingCount = taskList.where((t) => t['status'] != 'COMPLETED').length;
                return GestureDetector(
                  onTap: widget.onTasksTapped,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.assignment, color: SuperAdminTheme.primaryOrange, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Tasks Overview', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$pendingCount assignments pending today.', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios, color: SuperAdminTheme.textSecondary, size: 16),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
