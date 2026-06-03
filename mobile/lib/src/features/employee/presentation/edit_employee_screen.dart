import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../domain/employee_model.dart';
import '../data/employee_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../super_admin/data/super_admin_providers.dart';
import 'employee_notifier.dart';

class EditEmployeeScreen extends ConsumerStatefulWidget {
  final EmployeeModel? employee; // null = Create mode
  final bool isReadOnly;

  const EditEmployeeScreen({super.key, this.employee, this.isReadOnly = false});

  @override
  ConsumerState<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends ConsumerState<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _empIdController;
  late TextEditingController _phoneController;
  late TextEditingController _deptIdController;
  late TextEditingController _roleIdController;
  late TextEditingController _supervisorIdController;
  String _status = 'ACTIVE';

  // Create-mode only fields
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  bool get _isCreate => widget.employee == null;

  @override
  void initState() {
    super.initState();
    _firstNameController   = TextEditingController(text: widget.employee?.firstName ?? '');
    _lastNameController    = TextEditingController(text: widget.employee?.lastName ?? '');
    _empIdController       = TextEditingController(text: widget.employee?.employeeId ?? '');
    _phoneController       = TextEditingController(text: widget.employee?.phone ?? '');
    _deptIdController      = TextEditingController(text: widget.employee?.departmentId.toString() == '0' ? '' : widget.employee?.departmentId.toString() ?? '');
    _roleIdController      = TextEditingController(text: widget.employee?.roleId.toString() == '0' ? '' : widget.employee?.roleId.toString() ?? '');
    _supervisorIdController = TextEditingController(text: widget.employee?.supervisorId?.toString() ?? '');
    _status                = widget.employee?.status?.toUpperCase() ?? 'ACTIVE';
    _emailController       = TextEditingController();
    _passwordController    = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _empIdController.dispose();
    _phoneController.dispose();
    _deptIdController.dispose();
    _roleIdController.dispose();
    _supervisorIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final roleId = int.tryParse(_roleIdController.text);
    final deptId = int.tryParse(_deptIdController.text);

    if (roleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    try {
      if (_isCreate) {
        // ---------- CREATE: call /auth/register ----------
        final data = {
          'email':         _emailController.text.trim(),
          'password':      _passwordController.text,
          'role_id':       roleId,
          'employee_id':   _empIdController.text.trim(),
          'first_name':    _firstNameController.text.trim(),
          'last_name':     _lastNameController.text.trim(),
          'phone':         _phoneController.text.trim(),
          'department_id': deptId,
          'supervisor_id': _supervisorIdController.text.isEmpty
              ? null
              : int.tryParse(_supervisorIdController.text),
          'status':        _status,
        };
        await ref.read(authRepositoryProvider).registerUser(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ User created successfully!')),
          );
        }
      } else {
        // ---------- EDIT: call PUT /employee/:id ----------
        final data = {
          'employee_id':   _empIdController.text.trim(),
          'first_name':    _firstNameController.text.trim(),
          'last_name':     _lastNameController.text.trim(),
          'phone':         _phoneController.text.trim(),
          'department_id': deptId,
          'role_id':       roleId,
          'supervisor_id': _supervisorIdController.text.isEmpty
              ? null
              : int.tryParse(_supervisorIdController.text),
          'hire_date':     widget.employee!.hireDate,
          'status':        _status,
        };
        await ref.read(employeeRepositoryProvider).updateEmployee(widget.employee!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Employee updated successfully!')),
          );
        }
      }

      // Refresh the employee list and go back
      ref.read(employeeNotifierProvider.notifier).refreshEmployees();
      if (mounted) Navigator.pop(context);

    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesState = ref.watch(rolesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final myLevel = currentUser?.hierarchyLevel ?? 6;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? 'Create New User' : 'Edit Employee', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // ── Create-mode only: Account Info Section ──
            if (_isCreate) ...[
              _SectionLabel(label: 'ACCOUNT CREDENTIALS'),
              const SizedBox(height: 12),
              _buildField(_emailController, 'Email Address', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Default Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _SectionLabel(label: 'PROFILE INFORMATION'),
              const SizedBox(height: 12),
            ],

            // ── Common fields ──
            _buildField(_firstNameController, 'First Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_lastNameController, 'Last Name', Icons.person_outline),
            const SizedBox(height: 16),
            if (!_isCreate) ...[
              _buildField(_empIdController, 'Employee ID', Icons.badge_outlined),
              const SizedBox(height: 16),
            ],
            _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            // ── Department Dropdown ──
            ref.watch(superAdminDepartmentsProvider).when(
              data: (depts) {
                return DropdownButtonFormField<int>(
                  initialValue: _deptIdController.text.isNotEmpty 
                      ? int.tryParse(_deptIdController.text) 
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.business_outlined, color: SuperAdminTheme.primaryOrange),
                    labelStyle: TextStyle(color: SuperAdminTheme.textSecondary),
                  ),
                  dropdownColor: SuperAdminTheme.backgroundBlack,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: depts.map((d) => DropdownMenuItem<int>(
                        value: d['id'] as int,
                        child: Text(d['name'] as String,
                            style: const TextStyle(color: Colors.white)),
                      )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _deptIdController.text = val.toString());
                  },
                  validator: (val) => val == null ? 'Please select a department' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) =>
                  Text('Error loading departments: $err', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),

            // ── Role Dropdown (hierarchy-filtered) ──
            rolesState.when(
              data: (roles) {
                final filteredRoles = roles.where((r) {
                  final rName = r['roleName'] as String;
                  final rLevel = r['hierarchyLevel'] as int;
                  
                  // Special HR Restriction: Can only promote to TEAM_LEAD or demote to EMPLOYEE
                  if (currentUser?.roleName == 'HR') {
                    return rName == 'TEAM_LEAD' || rName == 'EMPLOYEE';
                  }

                  if (myLevel == 1) return true; // Super Admin sees all roles
                  return rLevel > myLevel;         // Others see only subordinate roles
                }).toList();

                return DropdownButtonFormField<int>(
                  initialValue: _roleIdController.text.isEmpty
                      ? null
                      : int.tryParse(_roleIdController.text),
                  decoration: const InputDecoration(
                    labelText: 'Assign Role',
                    prefixIcon: Icon(Icons.security_outlined, color: SuperAdminTheme.primaryOrange),
                    labelStyle: TextStyle(color: SuperAdminTheme.textSecondary),
                  ),
                  dropdownColor: SuperAdminTheme.backgroundBlack,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: filteredRoles
                      .map((r) => DropdownMenuItem<int>(
                            value: r['id'] as int,
                            child: Text(r['roleName'].toString().replaceAll('_', ' '),
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _roleIdController.text = val.toString());
                  },
                  validator: (val) => val == null ? 'Please select a role' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) =>
                  Text('Error loading roles: $err', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 16),
            _buildField(_supervisorIdController, 'Supervisor ID (Optional)',
                Icons.person_pin_outlined,
                keyboardType: TextInputType.number, required: false),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', 
                  prefixIcon: Icon(Icons.info_outline, color: SuperAdminTheme.primaryOrange),
                  labelStyle: TextStyle(color: SuperAdminTheme.textSecondary),
              ),
              dropdownColor: SuperAdminTheme.backgroundBlack,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: ['ACTIVE', 'ON LEAVE', 'TERMINATED']
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: widget.isReadOnly ? null : (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 40),

            // ── Save Button ──
            if (!widget.isReadOnly)
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: SuperAdminTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isCreate ? 'CREATE USER' : 'SAVE CHANGES',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            if (widget.isReadOnly)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'PROFILE IN VIEW-ONLY MODE', 
                    style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SuperAdminTheme.textSecondary),
        prefixIcon: Icon(icon, color: SuperAdminTheme.primaryOrange),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: SuperAdminTheme.surfaceLighter), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: SuperAdminTheme.primaryOrange), borderRadius: BorderRadius.circular(12)),
        errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: SuperAdminTheme.statusNegative), borderRadius: BorderRadius.circular(12)),
        focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: SuperAdminTheme.statusNegative, width: 2), borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: SuperAdminTheme.surfaceCard,
      ),
      style: const TextStyle(color: Colors.white),
      readOnly: widget.isReadOnly,
      keyboardType: keyboardType,
      validator: validator ??
          (value) {
            if (_isCreate && label == 'Employee ID') return null; // Auto-generated
            if (required && (value == null || value.isEmpty)) return 'Required field';
            return null;
          },
    );
  }
}

/// Small section header label used to visually separate form groups
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: SuperAdminTheme.primaryOrange,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}
