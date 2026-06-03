import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'staff_attendance_notifier.dart';

class StaffAttendanceScreen extends ConsumerWidget {
  const StaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(staffAttendanceNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(staffAttendanceNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: staffState.when(
        data: (staff) => ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: staff.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final person = staff[index];
            final bool isPresent = person['status'] != 'ABSENT';
            final bool isCompleted = person['status'] == 'COMPLETED';

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPresent ? AppTheme.statusPositive.withOpacity(0.1) : AppTheme.statusNegative.withOpacity(0.1),
                  child: Icon(
                    isPresent ? Icons.person : Icons.person_off,
                    color: isPresent ? AppTheme.statusPositive : AppTheme.statusNegative,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(person['role'], style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(person['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        person['status'],
                        style: TextStyle(
                          color: _getStatusColor(person['status']),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (person['checkIn'] != null)
                      Text(
                        'In: ${person['checkIn'].substring(11, 16)}',
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT': return AppTheme.statusPositive;
      case 'COMPLETED': return AppTheme.primaryAccent;
      case 'ABSENT': return AppTheme.statusNegative;
      default: return AppTheme.textSecondary;
    }
  }
}
