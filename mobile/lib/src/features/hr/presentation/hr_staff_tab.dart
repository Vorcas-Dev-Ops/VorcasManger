import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../employee/domain/employee_model.dart';
import '../../employee/presentation/edit_employee_screen.dart';
import 'hr_notifiers.dart';
import '../../../core/common_widgets/common_avatar.dart';

class HrStaffTab extends ConsumerStatefulWidget {
  const HrStaffTab({super.key});

  @override
  ConsumerState<HrStaffTab> createState() => _HrStaffTabState();
}

class _HrStaffTabState extends ConsumerState<HrStaffTab> {
  String _activeFilter = 'ALL'; // 'ALL', 'TEAM LEAD', 'EMPLOYEE'

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final staffAsync = ref.watch(hrStaffListProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hrStaffListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text('Global Directory',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
            const SizedBox(height: 12),
            

            // Add Employee Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditEmployeeScreen(employee: null),
                    ),
                  ).then((_) => ref.refresh(hrStaffListProvider));
                },
                icon:
                    const Icon(Icons.person_add, color: Colors.white, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuperAdminTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                label: const Text('ADD EMPLOYEE',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 24),

            // Filter Bar
            _buildFilterBar(),
            const SizedBox(height: 24),

            staffAsync.when(
              data: (staff) {
                if (staff.isEmpty) {
                  return const Center(
                      child: Text('No staff records found.',
                          style:
                              TextStyle(color: SuperAdminTheme.textSecondary)));
                }

                // 1. Initial Hierarchy Filter (Subordinates only)
                final currentLevel = currentUser?.hierarchyLevel ?? 99;
                var filteredStaff = staff.where((emp) {
                  final empLevel = emp['hierarchy_level'] as int? ?? 99;
                  if (empLevel == 99 && currentLevel == 99) return true;
                  return empLevel >= currentLevel;
                }).toList();

                // 2. Role Filter
                if (_activeFilter == 'TEAM LEAD') {
                  filteredStaff = filteredStaff
                      .where((emp) => emp['role_name'] == 'TEAM_LEAD')
                      .toList();
                } else if (_activeFilter == 'EMPLOYEE') {
                  filteredStaff = filteredStaff
                      .where((emp) => emp['role_name'] == 'EMPLOYEE')
                      .toList();
                }

                if (filteredStaff.isEmpty) {
                  return const Center(
                      child: Text('No matching records found.',
                          style:
                              TextStyle(color: SuperAdminTheme.textSecondary)));
                }

                // 3. Group by Team (Department)
                final Map<String, List<Map<String, dynamic>>> groupedStaff = {};
                for (final emp in filteredStaff) {
                  final teamName = emp['department_name'] ?? 'Unassigned';
                  if (!groupedStaff.containsKey(teamName)) {
                    groupedStaff[teamName] = [];
                  }
                  groupedStaff[teamName]!.add(emp);
                }

                // 4. Sort each group: Team Lead (level 5-ish) before Employee (level 6)
                for (final team in groupedStaff.keys) {
                  groupedStaff[team]!.sort((a, b) {
                    final aLevel = a['hierarchy_level'] as int? ?? 99;
                    final bLevel = b['hierarchy_level'] as int? ?? 99;
                    return aLevel.compareTo(bLevel);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedStaff.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(title: entry.key.toUpperCase()),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (context, index) {
                            final emp = entry.value[index];
                            return _EmployeeGridCard(
                              emp: emp,
                              name: '${emp['first_name']} ${emp['last_name']}',
                              role: emp['role_name'] ?? 'Staff',
                              dept: emp['department_name'] ?? 'No Dept',
                              status: emp['status'] ?? 'Active',
                              avatarUrl: emp['profile_picture_url'],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: SuperAdminTheme.primaryOrange)),
              error: (e, st) => Text('Error loading staff: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All Members',
            isActive: _activeFilter == 'ALL',
            onTap: () => setState(() => _activeFilter = 'ALL'),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Team Leads',
            isActive: _activeFilter == 'TEAM LEAD',
            onTap: () => setState(() => _activeFilter = 'TEAM LEAD'),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Employees',
            isActive: _activeFilter == 'EMPLOYEE',
            onTap: () => setState(() => _activeFilter = 'EMPLOYEE'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : SuperAdminTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
          style: const TextStyle(
            color: SuperAdminTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _EmployeeGridCard extends ConsumerWidget {
  final Map<String, dynamic> emp;
  final String name;
  final String role;
  final String dept;
  final String status;
  final String? avatarUrl;

  const _EmployeeGridCard({
    required this.emp,
    required this.name,
    required this.role,
    required this.dept,
    required this.status,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuperAdminTheme.surfaceLighter.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonAvatar(
                radius: 20,
                imageUrl: avatarUrl,
                isSquare: true,
                borderRadius: 10,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.toUpperCase() == 'ACTIVE' 
                      ? SuperAdminTheme.statusPositive.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status.toUpperCase() == 'ACTIVE' 
                        ? SuperAdminTheme.statusPositive 
                        : Colors.redAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role.replaceAll('_', ' '),
                style: const TextStyle(
                  color: SuperAdminTheme.primaryOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                final employee = EmployeeModel(
                  id: emp['id'],
                  userId: emp['user_id'] ?? 0,
                  employeeId: emp['employee_id'],
                  firstName: emp['first_name'],
                  lastName: emp['last_name'],
                  phone: emp['phone'],
                  departmentId: emp['department_id'] ?? 0,
                  roleId: emp['role_id'] ?? 0,
                  supervisorId: emp['supervisor_id'],
                  hireDate: emp['hire_date'],
                  status: emp['status'],
                  hierarchyLevel: emp['hierarchy_level'],
                  roleName: emp['role_name'],
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEmployeeScreen(employee: employee),
                  ),
                ).then((_) => ref.refresh(hrStaffListProvider));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SuperAdminTheme.backgroundBlack,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text(
                'VIEW',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
