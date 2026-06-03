import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'leave_notifier.dart';
import '../domain/leave_model.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveState = ref.watch(leaveNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      body: leaveState.when(
        data: (history) => _buildContent(context, ref, history, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showApplyLeaveSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<LeaveModel> history, ThemeData theme) {
    final pastLeaves = history.where((l) => l.status == 'APPROVED' || l.status == 'REJECTED').toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(leaveNotifierProvider.notifier).refreshHistory(),
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSummaryCard(history, theme),
          const SizedBox(height: 32),
          Text('Leave History', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (pastLeaves.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No past leave history found'),
            ))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastLeaves.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final leave = pastLeaves[index];
                return _buildLeaveItem(leave, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<LeaveModel> history, ThemeData theme) {
    final approved = history.where((l) => l.status == 'APPROVED').length;
    final pending = history.where((l) => l.status.startsWith('PENDING')).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Approved', approved.toString(), AppTheme.statusPositive),
            _buildSummaryItem('Pending', pending.toString(), AppTheme.statusPending),
            _buildSummaryItem('Available', '12', AppTheme.primaryAccent), // Hardcoded entitlement
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildLeaveItem(LeaveModel leave, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${leave.startDate} to ${leave.endDate}', 
                   style: theme.textTheme.bodyMedium,
                   overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(leave.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            leave.status.replaceAll('_', ' '),
            style: TextStyle(
              color: _getStatusColor(leave.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.toUpperCase().startsWith('PENDING')) return AppTheme.statusPending;
    switch (status.toUpperCase()) {
      case 'APPROVED': return AppTheme.statusPositive;
      case 'REJECTED': return AppTheme.statusNegative;
      default: return AppTheme.textSecondary;
    }
  }

  void _showApplyLeaveSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundLighter,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: _ApplyLeaveForm(),
        ),
      ),
    );
  }
}

class _ApplyLeaveForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends ConsumerState<_ApplyLeaveForm> {
  String _leaveType = 'Sick Leave';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Apply for Leave', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _leaveType,
            dropdownColor: AppTheme.cardBackground,
            decoration: const InputDecoration(
              labelText: 'Leave Type',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: ['Sick Leave', 'Casual Leave', 'Vacation', 'Other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _leaveType = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Reason (Optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(leaveNotifierProvider.notifier).submitRequest(
                leaveType: _leaveType,
                startDate: _startDate,
                endDate: _endDate,
                reason: _reasonController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('SUBMIT REQUEST'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
