import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../employee/presentation/employee_notifier.dart';
import '../../super_admin/data/super_admin_providers.dart';
import '../data/task_repository.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  int? _selectedEmployeeId;
  int? _selectedDepartmentId;
  DateTime? _dueDate;
  String _targetType = 'individual'; // 'individual', 'department', 'global'
  String _selectedType = 'TASK'; // 'TASK' or 'MEETING'

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _githubUrlController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final isValidEmployee = _targetType == 'individual' && _selectedEmployeeId != null;
    final isValidDept = _targetType == 'department' && _selectedDepartmentId != null;
    final isGlobal = _targetType == 'global';

    if (!_formKey.currentState!.validate() || (!isValidEmployee && !isValidDept && !isGlobal) || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      await ref.read(taskRepositoryProvider).createTask({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assigned_to': _targetType == 'individual' ? _selectedEmployeeId : null,
        'department_id': _targetType == 'department' ? _selectedDepartmentId : null,
        'github_url': _selectedType == 'TASK' && _githubUrlController.text.isNotEmpty ? _githubUrlController.text.trim() : null,
        'task_type': _selectedType,
        'meeting_link': _selectedType == 'MEETING' ? _meetingLinkController.text : null,
        'due_date': _dueDate!.toIso8601String(),
        'status': 'PENDING',
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'TASK', label: Text('TASK'), icon: Icon(Icons.assignment)),
                ButtonSegment(value: 'MEETING', label: Text('MEETING'), icon: Icon(Icons.videocam)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primaryAccent,
                selectedForegroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                side: const BorderSide(color: AppTheme.primaryAccent),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title', prefixIcon: Icon(Icons.title)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (_selectedType == 'TASK')
              TextFormField(
                controller: _githubUrlController,
                decoration: const InputDecoration(labelText: 'GitHub Repo Link (Optional)', prefixIcon: Icon(Icons.link)),
                keyboardType: TextInputType.url,
              ),
            if (_selectedType == 'MEETING')
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(labelText: 'Meeting Link', prefixIcon: Icon(Icons.link)),
                keyboardType: TextInputType.url,
                validator: (v) => v!.isEmpty ? 'Required for meetings' : null,
              ),
            const SizedBox(height: 16),
            const Text('Assign Task To:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'individual', label: Text('Single Staff'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'department', label: Text('Department'), icon: Icon(Icons.business)),
                ButtonSegment(value: 'global', label: Text('All'), icon: Icon(Icons.public)),
              ],
              selected: {_targetType},
              onSelectionChanged: (val) => setState(() => _targetType = val.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primaryAccent,
                selectedForegroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                side: const BorderSide(color: AppTheme.primaryAccent),
              ),
            ),
            const SizedBox(height: 16),
            if (_targetType == 'individual')
              employeesState.when(
                data: (employees) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Employee', prefixIcon: Icon(Icons.person_outline)),
                  dropdownColor: AppTheme.cardBackground,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setState(() => _selectedEmployeeId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error loading staff: $err'),
              ),
            if (_targetType == 'department')
              ref.watch(superAdminDepartmentsProvider).when(
                data: (depts) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Department', prefixIcon: Icon(Icons.business_outlined)),
                  dropdownColor: AppTheme.cardBackground,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: depts.map((d) => DropdownMenuItem<int>(value: d['id'] as int, child: Text(d['name'] as String, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setState(() => _selectedDepartmentId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error loading departments: $err'),
              ),
            if (_targetType == 'global')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('This task will be visible to all employees.', style: TextStyle(color: Colors.blue, fontSize: 12))),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryAccent),
              title: const Text('Due Date'),
              subtitle: Text(_dueDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(_dueDate!)),
              trailing: TextButton(
                onPressed: () => _selectDate(context),
                child: const Text('PICK DATE'),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppTheme.primaryAccent,
              ),
              child: const Text('CREATE TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
