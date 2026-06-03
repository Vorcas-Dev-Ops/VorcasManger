import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../domain/event_model.dart';
import 'event_notifier.dart';

class CompanyCalendarScreen extends ConsumerStatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  ConsumerState<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends ConsumerState<CompanyCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _eventType = 'Meeting'; // 'Meeting' or 'Holiday'

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<EventModel> _getEventsForDay(List<EventModel> allEvents, DateTime day) {
    return allEvents.where((e) {
      final eDate = DateTime.parse(e.eventDate).toLocal();
      return isSameDay(eDate, day);
    }).toList();
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text('Schedule Event', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _eventType,
                      decoration: const InputDecoration(labelText: 'Event Type'),
                      dropdownColor: AppTheme.cardBackground,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: ['Meeting', 'Holiday'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setStateSB(() => _eventType = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.isEmpty) return;
                    
                    final user = ref.read(currentUserProvider);
                    if (user == null) return;

                    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay ?? _focusedDay);
                    
                    final data = {
                      'title': _titleController.text,
                      'description': _descController.text.isEmpty ? null : _descController.text,
                      'eventDate': formattedDate,
                      'eventType': _eventType,
                      'createdBy': user.employeeId,
                    };

                    await ref.read(eventNotifierProvider.notifier).createEvent(data);
                    
                    _titleController.clear();
                    _descController.clear();
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Calendar'),
      ),
      body: eventsState.when(
        data: (allEvents) {
          final eventsForSelectedDay = _getEventsForDay(allEvents, _selectedDay ?? _focusedDay);

          return Column(
            children: [
              TableCalendar<EventModel>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getEventsForDay(allEvents, day),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  selectedDecoration: BoxDecoration(
                    color: AppTheme.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white70),
                  weekendStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: eventsForSelectedDay.isEmpty 
                  ? const Center(child: Text("No events on this day", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: eventsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final event = eventsForSelectedDay[index];
                      final isHoliday = event.eventType.toLowerCase() == 'holiday';
                      
                      return Card(
                        color: AppTheme.cardBackground,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isHoliday ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                            child: Icon(
                              isHoliday ? Icons.celebration : Icons.groups,
                              color: isHoliday ? Colors.redAccent : Colors.blueAccent,
                            ),
                          ),
                          title: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: event.description != null && event.description!.isNotEmpty
                              ? Text(event.description!, style: const TextStyle(color: Colors.white70))
                              : Text(event.eventType, style: const TextStyle(color: Colors.white70)),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading events:\n$err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: _showAddEventDialog,
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
