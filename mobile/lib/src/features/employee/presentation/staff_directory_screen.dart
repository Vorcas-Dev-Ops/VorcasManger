import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'employee_notifier.dart';
import '../domain/employee_model.dart';
import 'employee_detail_screen.dart';
import 'edit_employee_screen.dart';
import '../../../core/common_widgets/common_avatar.dart';

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesState = ref.watch(employeeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                fillColor: AppTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // TODO: Implement search filtering
              },
            ),
          ),
        ),
      ),
      body: employeesState.when(
        data: (employees) => RefreshIndicator(
          onRefresh: () => ref.read(employeeNotifierProvider.notifier).refreshEmployees(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _EmployeeCard(employee: employee);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditEmployeeScreen()),
          );
        },
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CommonAvatar(
          radius: 20,
          imageUrl: employee.profilePictureUrl,
        ),
        title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${employee.status ?? 'Unknown'} • Dept ID: ${employee.departmentId}'),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDetailScreen(employee: employee),
            ),
          );
        },
      ),
    );
  }
}
