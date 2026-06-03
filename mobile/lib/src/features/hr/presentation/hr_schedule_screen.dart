import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../task/presentation/task_notifier.dart';
import '../../task/domain/task_model.dart';
import 'schedule_form_screen.dart';

class HrScheduleScreen extends ConsumerStatefulWidget {
  const HrScheduleScreen({super.key});

  @override
  ConsumerState<HrScheduleScreen> createState() => _HrScheduleScreenState();
}

class _HrScheduleScreenState extends ConsumerState<HrScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskNotifierProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: tasksAsync.when(
        data: (tasks) {
          final events = _groupTasksByDate(tasks);
          final selectedEvents = events[DateTime(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              )] ??
              [];

          return Column(
            children: [
              _buildCalendar(events),
              const SizedBox(height: 16),
              Expanded(
                child: _buildAgenda(selectedEvents),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SuperAdminTheme.primaryOrange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleFormScreen(initialDate: _selectedDay),
            ),
          ).then((_) => ref.read(taskNotifierProvider.notifier).refreshTasks());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<TaskModel>> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuperAdminTheme.surfaceLighter.withOpacity(0.5)),
      ),
      child: TableCalendar<TaskModel>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
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
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: SuperAdminTheme.primaryOrange),
          rightChevronIcon: Icon(Icons.chevron_right, color: SuperAdminTheme.primaryOrange),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white70),
          weekendTextStyle: const TextStyle(color: Colors.white38),
          selectedDecoration: const BoxDecoration(
            color: SuperAdminTheme.primaryOrange,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: SuperAdminTheme.primaryOrange.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: SuperAdminTheme.primaryOrange,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildAgenda(List<TaskModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: SuperAdminTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No scheduled items for this day',
                style: TextStyle(color: SuperAdminTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        final isMeeting = event.taskType == 'MEETING';

        return GestureDetector(
          onTap: () => _showTaskDetail(context, event),
          child: Container(
            decoration: BoxDecoration(
              color: SuperAdminTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuperAdminTheme.surfaceLighter.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMeeting ? Colors.blue.withOpacity(0.1) : SuperAdminTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMeeting ? Icons.videocam : Icons.assignment,
                            size: 12,
                            color: isMeeting ? Colors.blue : SuperAdminTheme.primaryOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMeeting ? 'MEETING' : 'TASK',
                            style: TextStyle(
                              color: isMeeting ? Colors.blue : SuperAdminTheme.primaryOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (event.startTime != null)
                          Text(
                            event.startTime!.substring(0, 5),
                            style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: SuperAdminTheme.textSecondary, size: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.assigneeNames != null && event.assigneeNames!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: SuperAdminTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.assigneeNames!,
                            style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTaskDetail(BuildContext context, TaskModel event) {
    final isMeeting = event.taskType == 'MEETING';
    final statusColor = event.status == 'DONE'
        ? SuperAdminTheme.statusPositive
        : event.status == 'IN_PROGRESS'
            ? Colors.blue
            : SuperAdminTheme.primaryOrange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SuperAdminTheme.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: type badge + status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isMeeting ? Colors.blue.withOpacity(0.15) : SuperAdminTheme.primaryOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(isMeeting ? Icons.videocam : Icons.assignment,
                                  size: 14, color: isMeeting ? Colors.blue : SuperAdminTheme.primaryOrange),
                              const SizedBox(width: 6),
                              Text(
                                isMeeting ? 'MEETING' : 'TASK',
                                style: TextStyle(
                                  color: isMeeting ? Colors.blue : SuperAdminTheme.primaryOrange,
                                  fontWeight: FontWeight.bold, fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.status.replaceAll('_', ' '),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(event.title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Description
                    Text(event.description,
                        style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),

                    // Date & Time
                    _detailRow(Icons.calendar_today, 'Date',
                        event.dueDate != null
                            ? '${DateTime.parse(event.dueDate!).day}/${DateTime.parse(event.dueDate!).month}/${DateTime.parse(event.dueDate!).year}'
                            : 'No date'),
                    if (event.startTime != null)
                      _detailRow(Icons.access_time, 'Start Time', event.startTime!.substring(0, 5)),

                    // Assignees
                    if (event.assigneeNames != null && event.assigneeNames!.isNotEmpty)
                      _detailRow(Icons.people_outline, 'Assigned To', event.assigneeNames!),

                    // Meeting link
                    if (isMeeting && event.meetingLink != null && event.meetingLink!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _detailRow(Icons.link, 'Meeting Link', event.meetingLink!),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('JOIN MEETING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: SuperAdminTheme.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Map<DateTime, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    final Map<DateTime, List<TaskModel>> data = {};
    for (final task in tasks) {
      if (task.dueDate != null) {
        final date = DateTime.parse(task.dueDate!);
        final key = DateTime(date.year, date.month, date.day);
        if (data[key] == null) data[key] = [];
        data[key]!.add(task);
      }
    }
    return data;
  }
}
