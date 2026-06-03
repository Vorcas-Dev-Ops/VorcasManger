import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';
import 'admin_role_dialog.dart';
import '../../../core/common_widgets/common_avatar.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  List<String> _departments = ['ALL'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final employees = await ref.read(adminRepositoryProvider).getAllEmployees();
      final depts = await ref.read(adminRepositoryProvider).getDepartments();
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _departments = ['ALL', ...depts.map((d) => d.name.toUpperCase())];
          _loading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allEmployees.where((emp) {
        final name = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.toLowerCase();
        final role = (emp['role_name'] ?? '').toString().toLowerCase();
        
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) || 
                             role.contains(_searchQuery.toLowerCase());
                             
        // NEW: Department filtering
        final dept = (emp['department_name'] ?? '').toString().toUpperCase();
        final matchesDept = _selectedFilter == 'ALL' || dept == _selectedFilter;
        
        return matchesSearch && matchesDept;
      }).toList();
    });
  }

  Color _statusColor(String? status) {
    if (status == 'Active') return Colors.greenAccent;
    if (status == 'On Leave') return SuperAdminTheme.primaryOrange;
    return SuperAdminTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        color: SuperAdminTheme.primaryOrange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                children: [
                  const TextSpan(text: 'Employee ', style: TextStyle(color: Colors.white)),
                  const TextSpan(text: 'Directory', style: TextStyle(color: SuperAdminTheme.primaryOrange)),
                  TextSpan(text: ' (${_filtered.length})', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'Search by name or role...',
                hintStyle: const TextStyle(color: SuperAdminTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: SuperAdminTheme.textSecondary),
                filled: true,
                fillColor: SuperAdminTheme.surfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SuperAdminTheme.primaryOrange)),
              ),
            ),
            const SizedBox(height: 20),

            // Filter pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _departments.map((dept) {
                  final isActive = _selectedFilter == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedFilter = dept; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive ? null : Border.all(color: SuperAdminTheme.surfaceLighter),
                        ),
                        child: Text(dept, style: TextStyle(color: isActive ? Colors.white : SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Employee list
            ..._filtered.map((emp) {
              final name = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}';
              final role = (emp['role_name'] ?? 'EMPLOYEE').toString().toUpperCase();
              final status = emp['status'] ?? 'Active';
              final empId = emp['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to employee detail
                  },
                  onLongPress: () async {
                    final success = await showDialog<bool>(
                      context: context,
                      builder: (context) => AdminRoleDialog(
                        employeeId: empId,
                        employeeName: name,
                        currentRoleId: emp['role_id'],
                      ),
                    );
                    if (success == true) {
                      _load(); // Refresh list on success
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CommonAvatar(
                              radius: 28,
                              imageUrl: emp['profile_picture_url'],
                              isSquare: true,
                              borderRadius: 12,
                            ),
                            Positioned(
                              bottom: -2, right: -2,
                              child: Container(width: 16, height: 16, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle, border: Border.all(color: SuperAdminTheme.surfaceCard, width: 2))),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(role, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 8),
                              Text('ID: ${emp['employee_id'] ?? empId}', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: SuperAdminTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No employees found', style: TextStyle(color: SuperAdminTheme.textSecondary))),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
