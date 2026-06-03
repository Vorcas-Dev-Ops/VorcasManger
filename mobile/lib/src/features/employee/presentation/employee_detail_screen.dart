import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import '../domain/employee_model.dart';
import '../data/employee_repository.dart';
import 'edit_employee_screen.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final EmployeeModel employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditEmployeeScreen(employee: employee)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CommonAvatar(
                    radius: 50,
                    imageUrl: employee.profilePictureUrl,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employee.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    employee.employeeId ?? 'N/A',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: employee.status ?? 'UNKNOWN'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _DetailSection(
              title: 'Contact Information',
              items: [
                _DetailItem(icon: Icons.phone_outlined, label: 'Phone', value: employee.phone ?? 'Not provided'),
                const _DetailItem(icon: Icons.email_outlined, label: 'Email', value: 'Not provided'),
              ],
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Employment Details',
              items: [
                _DetailItem(icon: Icons.work_outline, label: 'Department ID', value: employee.departmentId.toString()),
                _DetailItem(icon: Icons.badge_outlined, label: 'Role ID', value: employee.roleId.toString()),
                _DetailItem(icon: Icons.calendar_today_outlined, label: 'Hire Date', value: employee.hireDate != null && employee.hireDate!.length >= 10 ? employee.hireDate!.substring(0, 10) : 'N/A'),
                _DetailItem(icon: Icons.person_pin_outlined, label: 'Supervisor ID', value: employee.supervisorId?.toString() ?? 'None'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(employeeRepositoryProvider).deleteEmployee(employee.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _DetailSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Card(
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.primaryAccent),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'Active' ? AppTheme.statusPositive : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
