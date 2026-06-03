import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/super_admin_providers.dart';
import '../../employee/presentation/edit_employee_screen.dart';
import '../../employee/domain/employee_model.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/common_widgets/common_avatar.dart';

class SuperAdminUsersTab extends ConsumerStatefulWidget {
  const SuperAdminUsersTab({super.key});

  @override
  ConsumerState<SuperAdminUsersTab> createState() => _SuperAdminUsersTabState();
}

class _SuperAdminUsersTabState extends ConsumerState<SuperAdminUsersTab> {
  String _searchQuery = '';
  int? _selectedRoleId;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final rolesAsync = ref.watch(rolesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final myLevel = currentUser?.hierarchyLevel ?? 99;
    final isSuperAdmin = myLevel == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(allEmployeesProvider);
              ref.refresh(rolesProvider);
            },
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          final filteredEmployees = employees.where((e) {
            final name = '${e['first_name']} ${e['last_name']}'.toLowerCase();
            final role = (e['role_name'] ?? '').toLowerCase();
            final dept = (e['department_name'] ?? '').toLowerCase();
            final roleId = e['role_id'] as int?;
            final roleLevel = e['hierarchy_level'] as int? ?? 99;

            // Hide Super Admins (level 1) from everyone else
            if (!isSuperAdmin && roleLevel == 1) return false;

            final matchesQuery = name.contains(_searchQuery.toLowerCase()) || 
                                role.contains(_searchQuery.toLowerCase()) ||
                                dept.contains(_searchQuery.toLowerCase());
            
            final matchesRole = _selectedRoleId == null || roleId == _selectedRoleId;
            
            return matchesQuery && matchesRole;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(allEmployeesProvider);
              ref.refresh(rolesProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Manage administrative access and permissions.',
                    style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or role...',
                      hintStyle: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: SuperAdminTheme.textSecondary),
                      filled: true,
                      fillColor: SuperAdminTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter and Create Buttons
                  // Create User Button
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateUser(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('CREATE NEW USER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuperAdminTheme.primaryOrange,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // FILTER BY ROLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(title: 'FILTER BY ROLE'),
                      if (_selectedRoleId != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedRoleId = null),
                          child: const Text('RESET', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  rolesAsync.when(
                    data: (roles) {
                      final availableRoles = roles.where((r) {
                        final roleLevel = r['hierarchyLevel'] as int? ?? 99;
                        if (!isSuperAdmin && roleLevel == 1) return false;
                        return true;
                      }).toList();

                      return Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: availableRoles.map((role) {
                          final roleId = role['id'] as int;
                          final roleName = (role['roleName'] as String).replaceAll('_', ' ').toUpperCase();
                          final isSelected = _selectedRoleId == roleId;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRoleId = isSelected ? null : roleId;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter),
                              ),
                              child: Text(
                                roleName,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : SuperAdminTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
                    error: (err, _) => Text('Error loading roles: $err', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 32),
                  
                  // ACTIVE DIRECTORY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(title: 'ACTIVE DIRECTORY'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IDENTITY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                              const Text('ROLE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: SuperAdminTheme.surfaceLighter),
                        if (filteredEmployees.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No employees found', style: TextStyle(color: SuperAdminTheme.textSecondary)),
                          )
                        else
                          ...filteredEmployees.map((e) => Column(
                            children: [
                                _DirectoryItem(
                                  name: '${e['first_name']} ${e['last_name']}',
                                  email: e['employee_id'] ?? '',
                                  role: e['role_name'] ?? 'Staff',
                                  initials: e['first_name']?[0] ?? '?',
                                  profilePictureUrl: e['profile_picture_url'],
                                  onTap: () {
                                  final targetLevel = e['hierarchy_level'] as int? ?? 99;
                                  if (!isSuperAdmin && targetLevel <= myLevel) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Access Denied: You cannot modify this role level.')),
                                    );
                                    return;
                                  }
                                  _navigateToEditUser(context, e);
                                },
                              ),
                              if (filteredEmployees.indexOf(e) != filteredEmployees.length - 1)
                                const Divider(height: 1, color: SuperAdminTheme.surfaceLighter),
                            ],
                          )),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateUser(context),
        backgroundColor: SuperAdminTheme.primaryOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _navigateToCreateUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditEmployeeScreen(employee: null)),
    ).then((_) => ref.refresh(allEmployeesProvider));
  }

  void _navigateToEditUser(BuildContext context, Map<String, dynamic> e) {
    // Build a partial EmployeeModel from the directory map for editing
    final emp = EmployeeModel(
      id: e['id'] as int,
      userId: (e['user_id'] as int?) ?? 0,
      employeeId: (e['employee_id'] as String?) ?? '',
      firstName: (e['first_name'] as String?) ?? '',
      lastName: (e['last_name'] as String?) ?? '',
      phone: (e['phone'] as String?) ?? '',
      departmentId: (e['department_id'] as int?) ?? 0,
      roleId: (e['role_id'] as int?) ?? 0,
      supervisorId: e['supervisor_id'] as int?,
      hireDate: (e['hire_date'] as String?) ?? '',
      status: (e['status'] as String?) ?? 'ACTIVE',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEmployeeScreen(employee: emp)),
    ).then((_) => ref.refresh(allEmployeesProvider));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: SuperAdminTheme.primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ],
    );
  }
}
class _DirectoryItem extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String initials;
  final Color? roleColor;
  final String? profilePictureUrl;
  final VoidCallback? onTap;

  const _DirectoryItem({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
    this.roleColor,
    this.profilePictureUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          CommonAvatar(
            radius: 20,
            imageUrl: profilePictureUrl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: SuperAdminTheme.surfaceLighter),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: roleColor ?? SuperAdminTheme.primaryOrange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
