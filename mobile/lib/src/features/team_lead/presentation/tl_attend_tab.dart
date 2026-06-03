import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../employee/presentation/employee_notifiers.dart';

class TlAttendTab extends ConsumerStatefulWidget {
  const TlAttendTab({super.key});

  @override
  ConsumerState<TlAttendTab> createState() => _TlAttendTabState();
}

class _TlAttendTabState extends ConsumerState<TlAttendTab> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _parseTime(String? timeStr) {
    if (timeStr == null) return DateTime.now();
    return DateTime.parse(timeStr).toLocal();
  }


  @override
  Widget build(BuildContext context) {
    final attendanceStatus = ref.watch(attendanceNotifierProvider);
    final history = ref.watch(attendanceHistoryProvider);

    final timeStr = DateFormat('HH:mm').format(_now);
    final secondStr = DateFormat('ss').format(_now);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_now);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceNotifierProvider);
          ref.invalidate(attendanceHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Calendar Widget (Replaces Current Time Card)
            history.maybeWhen(
              data: (list) {
                final presentDates = list.map((item) {
                  return DateTime.tryParse(item['date'] ?? '')?.toLocal() ?? DateTime.now();
                }).map((d) => DateTime(d.year, d.month, d.day)).toSet();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_calendarFormat == CalendarFormat.month) {
                        _focusedDay = DateTime.now();
                        _calendarFormat = CalendarFormat.week;
                      } else {
                        _calendarFormat = CalendarFormat.month;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      availableCalendarFormats: const {
                        CalendarFormat.week: 'Week',
                        CalendarFormat.month: 'Month',
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                      ),
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                      weekendStyle: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                    ),
                    calendarBuilders: CalendarBuilders(
                      prioritizedBuilder: (context, day, focusedDay) {
                        final dateOnly = DateTime(day.year, day.month, day.day);
                        final isPresent = presentDates.contains(dateOnly);
                        final isToday = isSameDay(day, DateTime.now());
                        
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: isPresent ? Border.all(color: SuperAdminTheme.statusPositive, width: 2) : null,
                            color: isToday ? SuperAdminTheme.primaryOrange.withOpacity(0.3) : null,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isPresent ? SuperAdminTheme.statusPositive : (isToday ? SuperAdminTheme.primaryOrange : Colors.white),
                              fontWeight: (isPresent || isToday) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
              orElse: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange))),
            ),
            const SizedBox(height: 16),

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
                      const SizedBox(height: 16),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isCheckedIn) {
                              await ref.read(attendanceNotifierProvider.notifier).checkOut(status!['attendanceId']);
                            } else {
                              ref.read(attendanceNotifierProvider.notifier).checkIn();
                            }
                          },
                          icon: Icon(isCheckedIn ? Icons.logout : Icons.fingerprint, color: Colors.white, size: 22),
                          label: Text(
                            isCheckedIn ? 'CHECK-OUT NOW' : 'CHECK-IN NOW',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCheckedIn ? SuperAdminTheme.statusNegative : SuperAdminTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: (isCheckedIn ? SuperAdminTheme.statusNegative : SuperAdminTheme.primaryOrange).withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isCheckedIn 
                          ? 'Session active since: ${DateFormat('hh:mm a').format(_parseTime(status!['checkInTime']))}' 
                          : 'Location verified: Main Headquarters (Office A)',
                        style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SuperAdminTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SuperAdminTheme.surfaceLighter),
                ),
                child: Column(
                  children: [
                    const Text('VERIFYING LOCATION...', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: SuperAdminTheme.primaryOrange),
                    const SizedBox(height: 24),
                    const Text('Please wait while we check your geofence status.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              error: (e, st) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: SuperAdminTheme.statusNegative.withOpacity(0.5))),
                child: Column(
                  children: [
                    Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    TextButton(onPressed: () => ref.invalidate(attendanceNotifierProvider), child: const Text('RETRY', style: TextStyle(color: SuperAdminTheme.primaryOrange))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid (Fully dynamic)
            history.when(
              data: (list) {
                // Calculate Average In
                String avgIn = '00:00 AM';
                double totalBreakHours = 0.0;
                double totalHours = 0.0;
                
                if (list.isNotEmpty) {
                  int totalInMinutes = 0;
                  int validInDays = 0;
                  
                  for (var item in list) {
                    if (item['checkInTime'] != null) {
                      final checkIn = _parseTime(item['checkInTime']);
                      totalInMinutes += checkIn.hour * 60 + checkIn.minute;
                      validInDays++;
                    }
                    if (item['workHours'] != null) {
                      totalHours += double.parse(item['workHours'].toString());
                    }
                    if (item['breakSeconds'] != null) {
                      totalBreakHours += (double.parse(item['breakSeconds'].toString()) / 3600);
                    }
                  }
                  
                  if (validInDays > 0) {
                    final avgMinutes = (totalInMinutes / validInDays).round();
                    final avgH = avgMinutes ~/ 60;
                    final avgM = avgMinutes % 60;
                    final amPm = avgH >= 12 ? 'PM' : 'AM';
                    final displayH = avgH == 0 ? 12 : (avgH > 12 ? avgH - 12 : avgH);
                    avgIn = '${displayH.toString().padLeft(2, '0')}:${avgM.toString().padLeft(2, '0')} $amPm';
                  }
                }

                return attendanceStatus.maybeWhen(
                  data: (status) {
                    final currentStatus = status?['status'] ?? 'NOT_CHECKED_IN';
                    final isCheckedOut = currentStatus == 'CHECKED_OUT';
                    final isCheckedIn = currentStatus == 'CHECKED_IN' || currentStatus == 'ON_BREAK';
                    
                    String workedToday = '0h 00m';
                    if ((isCheckedIn || isCheckedOut) && status?['checkInTime'] != null) {
                      final checkIn = _parseTime(status!['checkInTime']);
                      final endTime = isCheckedOut && status['checkOutTime'] != null 
                          ? _parseTime(status['checkOutTime']) 
                          : DateTime.now();
                      int elapsedSeconds = endTime.difference(checkIn).inSeconds;

                      final int accumulatedBreaks = status?['accumulatedBreakSeconds'] ?? 0;
                      int currentBreakSeconds = 0;

                      if (currentStatus == 'ON_BREAK' && status?['currentBreakStart'] != null) {
                        final currentBreakStart = _parseTime(status!['currentBreakStart']);
                        currentBreakSeconds = DateTime.now().difference(currentBreakStart).inSeconds;
                      }

                      final int netActiveSeconds = elapsedSeconds - accumulatedBreaks - currentBreakSeconds;
                      final int netActiveMinutes = netActiveSeconds > 0 ? netActiveSeconds ~/ 60 : 0;

                      workedToday = '${netActiveMinutes ~/ 60}h ${netActiveMinutes % 60}m';
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        _MetricBox(
                          title: 'WORKED TODAY', 
                          value: workedToday, 
                          highlight: isCheckedIn,
                        ),
                        _MetricBox(title: 'AVERAGE IN', value: avgIn),
                        _MetricBox(
                          title: 'BREAK HOURS', 
                          value: '${totalBreakHours.toStringAsFixed(1)}h', 
                          valueColor: totalBreakHours > 1.0 ? Colors.redAccent : SuperAdminTheme.primaryOrange,
                        ),
                        _MetricBox(title: 'TOTAL HOURS', value: totalHours.toStringAsFixed(1)),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // Attendance History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance History', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: const [
                    Icon(Icons.filter_list, color: SuperAdminTheme.primaryOrange, size: 16),
                    SizedBox(width: 4),
                    Text('FILTER', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // History List
            history.when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('No attendance records yet.', style: TextStyle(color: SuperAdminTheme.textSecondary))),
                  );
                }
                return Container(
                  decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('DATE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                            Expanded(flex: 2, child: Text('CLOCK-\nIN', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                            Expanded(flex: 2, child: Text('CLOCK-\nOUT', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                            Expanded(flex: 2, child: Text('TOTAL\nHRS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: SuperAdminTheme.surfaceLighter),
                      ...list.map((item) {
                        final date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                        final dateStrShort = DateFormat('MMM d,\nyyyy').format(date);
                        final dayStr = DateFormat('EEEE').format(date).toUpperCase();
                        
                        final checkIn = item['checkInTime'] != null 
                            ? DateFormat('hh:mm\na').format(DateTime.parse(item['checkInTime']).toLocal()) 
                            : '--:--';
                        final checkOut = item['checkOutTime'] != null 
                            ? DateFormat('hh:mm\na').format(DateTime.parse(item['checkOutTime']).toLocal()) 
                            : '--:--';
                        
                        final workHours = item['workHours'] != null 
                            ? '${double.parse(item['workHours'].toString()).toStringAsFixed(1)}h' 
                            : '--';

                        return Column(
                          children: [
                            _HistoryRow(
                              date: dateStrShort, 
                              day: dayStr, 
                              clockIn: checkIn, 
                              clockOut: checkOut, 
                              total: workHours,
                            ),
                            const Divider(height: 1, color: SuperAdminTheme.surfaceLighter),
                          ],
                        );
                      }).toList(),
                      
                      // Bottom Load More
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: const BoxDecoration(
                          color: SuperAdminTheme.backgroundBlack,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                        ),
                        child: const Center(child: Text('END OF HISTORY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                      )
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String title;
  final String value;
  final bool highlight;
  final Color valueColor;

  const _MetricBox({required this.title, required this.value, this.highlight = false, this.valueColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? SuperAdminTheme.primaryOrange.withOpacity(0.05) : SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? SuperAdminTheme.primaryOrange.withOpacity(0.3) : SuperAdminTheme.surfaceLighter),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
           const SizedBox(height: 4),
           Text(value, style: TextStyle(color: highlight ? SuperAdminTheme.primaryOrange : valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String date;
  final String day;
  final String clockIn;
  final String clockOut;
  final String total;

  const _HistoryRow({required this.date, required this.day, required this.clockIn, required this.clockOut, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(day, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            )
          ),
          Expanded(flex: 2, child: Text(clockIn, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, height: 1.3))),
          Expanded(flex: 2, child: Text(clockOut, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, height: 1.3))),
          Expanded(flex: 2, child: Text(total, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
