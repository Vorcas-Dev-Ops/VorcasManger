import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../employee/presentation/employee_notifier.dart';
import '../../task/data/task_repository.dart';

class TlScheduleFormScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const TlScheduleFormScreen({super.key, this.initialDate});

  @override
  ConsumerState<TlScheduleFormScreen> createState() => _TlScheduleFormScreenState();
}

class _TlScheduleFormScreenState extends ConsumerState<TlScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _githubUrlController = TextEditingController();
  
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final List<int> _selectedEmployeeIds = [];
  
  String _selectedType = 'TASK'; // 'TASK' or 'MEETING'
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    _githubUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEmployee(int id) {
    setState(() {
      if (_selectedEmployeeIds.contains(id)) {
        _selectedEmployeeIds.remove(id);
      } else {
        _selectedEmployeeIds.add(id);
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SuperAdminTheme.primaryOrange,
            onPrimary: Colors.black,
            surface: SuperAdminTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SuperAdminTheme.primaryOrange,
            onPrimary: Colors.black,
            surface: SuperAdminTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    try {
      final startTime = _selectedTime != null 
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final currentUser = ref.read(currentUserProvider);
      await ref.read(taskRepositoryProvider).createTask({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assigned_to': _selectedEmployeeIds.isEmpty ? null : _selectedEmployeeIds,
        'task_type': _selectedType,
        'due_date': _selectedDate!.toIso8601String(),
        'start_time': startTime,
        'meeting_link': _selectedType == 'MEETING' ? _meetingLinkController.text : null,
        'github_url': _githubUrlController.text.isNotEmpty ? _githubUrlController.text.trim() : null,
        'status': 'PENDING',
        'assigned_by': currentUser?.employeeId,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduled successfully!')));
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
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('New TL Schedule', style: TextStyle(color: Colors.white)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                _buildTypeButton('TASK', Icons.assignment),
                const SizedBox(width: 12),
                _buildTypeButton('MEETING', Icons.videocam),
              ],
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g., Squad Sync',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'e.g., Weekly progress review',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            if (_selectedType == 'TASK') ...[
              _buildTextField(
                controller: _githubUrlController,
                label: 'GitHub Repo Link',
                hint: 'e.g., github.com/user/repo',
                icon: Icons.link,
                isRequired: false,
              ),
              const SizedBox(height: 16),
            ],

            if (_selectedType == 'MEETING') ...[
              _buildTextField(
                controller: _meetingLinkController,
                label: 'Meeting Link',
                hint: 'e.g., zoom.us/j/123456',
                icon: Icons.link,
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: _buildPickerTile(
                    label: 'Date',
                    value: _selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerTile(
                    label: 'Start Time',
                    value: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                    icon: Icons.access_time,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_selectedEmployeeIds.isNotEmpty) ...[
              const Text('Selected Staff', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              employeesState.when(
                data: (employees) {
                  final selectedList = employees.where((e) => _selectedEmployeeIds.contains(e.id)).toList();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedList.map((e) => Chip(
                      label: Text(e.fullName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: SuperAdminTheme.primaryOrange.withOpacity(0.2),
                      side: const BorderSide(color: SuperAdminTheme.primaryOrange),
                      deleteIcon: const Icon(Icons.close, size: 14, color: SuperAdminTheme.primaryOrange),
                      onDeleted: () => _toggleEmployee(e.id),
                    )).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ],

            const Text('Search & Assign Squad Members', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type squad member name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                filled: true,
                fillColor: SuperAdminTheme.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search, color: SuperAdminTheme.primaryOrange, size: 20),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: SuperAdminTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              ),
            ),
            
            if (_searchQuery.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: SuperAdminTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SuperAdminTheme.surfaceLighter),
                ),
                child: employeesState.when(
                  data: (employees) {
                    final results = employees.where((e) {
                      final matchesSearch = e.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
                      final notAlreadySelected = !_selectedEmployeeIds.contains(e.id);
                      
                      // Filter: Only employees belonging to this TL's squad
                      final isTeamMember = e.supervisorId == currentUser?.employeeId;
                      
                      return matchesSearch && notAlreadySelected && isTeamMember;
                    }).toList();

                    if (results.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No matching squad or HR found', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final e = results[index];
                        return ListTile(
                          dense: true,
                          title: Text(e.fullName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text(e.roleName ?? '', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                          trailing: const Icon(Icons.add_circle_outline, color: SuperAdminTheme.primaryOrange, size: 18),
                          onTap: () {
                            _toggleEmployee(e.id);
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
                  error: (e, _) => const Text('Error loading results'),
                ),
              ),

            if (_selectedEmployeeIds.isEmpty && _searchQuery.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Assigns to Me if none selected', 
                  style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            
            const SizedBox(height: 48),
            
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: SuperAdminTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SCHEDULE EVENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            filled: true,
            fillColor: SuperAdminTheme.surfaceCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 20),
          ),
          validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: SuperAdminTheme.primaryOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
