import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import 'attendance_notifier.dart';
import '../domain/attendance_model.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: attendanceState.when(
        data: (history) {
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayRecord = history.isNotEmpty && history.first.date.startsWith(today) ? history.first : null;

          // Days with attendance
          final attendanceDays = history.map((e) {
            try {
              return DateFormat('yyyy-MM-dd').parse(e.date);
            } catch (_) {
              return DateTime.now();
            }
          }).toSet();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(theme, todayRecord),
                const SizedBox(height: 32),
                _buildCalendar(attendanceDays),
                const SizedBox(height: 32),
                Text('Recent Activity', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: Text('No attendance history found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length > 5 ? 5 : history.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _buildHistoryItem(theme, item);
                    },
                  ),
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to load history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(attendanceNotifierProvider),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(Set<DateTime> attendanceDays) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: (day) {
            if (attendanceDays.any((d) => isSameDay(d, day))) {
              return ['attended'];
            }
            return [];
          },
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: AppTheme.primaryAccent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryAccent,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, AttendanceModel? record) {
    final checkInTime = record?.checkInTime != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(record!.checkInTime!).toLocal()) 
        : '--:--';
    final checkOutTime = record?.checkOutTime != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(record!.checkOutTime!).toLocal()) 
        : '--:--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, dd MMM').format(DateTime.now()),
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
                _buildTimeInfo('Check In', checkInTime),
                _buildTimeInfo('Check Out', checkOutTime),
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

  Widget _buildHistoryItem(ThemeData theme, AttendanceModel item) {
    String formattedDate = 'Unknown';
    try {
      formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(item.date));
    } catch (_) {}

    final checkIn = item.checkInTime != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(item.checkInTime!).toLocal()) 
        : '--:--';
    final checkOut = item.checkOutTime != null 
        ? DateFormat('hh:mm a').format(DateTime.parse(item.checkOutTime!).toLocal()) 
        : '...';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$checkIn - $checkOut', style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(
          item.workHours != null ? '${item.workHours!.toStringAsFixed(1)} hrs' : '--',
          style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
