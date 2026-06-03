import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import '../../employee/data/employee_repository.dart';
import 'hr_notifiers.dart';

class HrTeamManagementScreen extends ConsumerStatefulWidget {
  const HrTeamManagementScreen({super.key});

  @override
  ConsumerState<HrTeamManagementScreen> createState() => _HrTeamManagementScreenState();
}

class _HrTeamManagementScreenState extends ConsumerState<HrTeamManagementScreen> {
  int? _selectedLeadId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(hrStaffListProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Team Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: staffAsync.when(
        data: (staff) {
          final teamLeads = staff.where((e) => e['role_name'] == 'TEAM_LEAD').toList();
          final allEmployees = staff.where((e) => e['role_name'] == 'EMPLOYEE').toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (isWide) {
                return Row(
                  children: [
                    _buildLeadsSidebar(teamLeads, allEmployees),
                    Expanded(
                      child: _selectedLeadId == null
                          ? const Center(child: Text('Select a Team Lead to manage their squad', style: TextStyle(color: SuperAdminTheme.textSecondary)))
                          : _buildSquadManager(teamLeads.firstWhere((l) => l['id'] == _selectedLeadId), allEmployees),
                    ),
                  ],
                );
              } else {
                // Mobile Vertical Layout
                return Column(
                  children: [
                    _buildLeadsHorizontalList(teamLeads, allEmployees),
                    Expanded(
                      child: _selectedLeadId == null
                          ? const Center(child: Text('Select a Team Lead above', style: TextStyle(color: SuperAdminTheme.textSecondary)))
                          : _buildSquadManager(teamLeads.firstWhere((l) => l['id'] == _selectedLeadId), allEmployees, isMobile: true),
                    ),
                  ],
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildLeadsSidebar(List<Map<String, dynamic>> teamLeads, List<Map<String, dynamic>> allEmployees) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: SuperAdminTheme.surfaceLighter)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('TEAM LEADS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: teamLeads.length,
              itemBuilder: (context, index) {
                final lead = teamLeads[index];
                final isSelected = _selectedLeadId == lead['id'];
                final squadCount = allEmployees.where((e) => e['supervisor_id'] == lead['id']).length;

                return ListTile(
                  onTap: () => setState(() => _selectedLeadId = lead['id']),
                  selected: isSelected,
                  selectedTileColor: SuperAdminTheme.primaryOrange.withOpacity(0.1),
                  leading: CommonAvatar(
                    radius: 18,
                    imageUrl: lead['profile_picture_url'],
                  ),
                  title: Text('${lead['first_name']} ${lead['last_name']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('$squadCount members', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                  trailing: isSelected ? const Icon(Icons.chevron_right, color: SuperAdminTheme.primaryOrange, size: 18) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsHorizontalList(List<Map<String, dynamic>> teamLeads, List<Map<String, dynamic>> allEmployees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('SELECT TEAM LEAD', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: teamLeads.length,
            itemBuilder: (context, index) {
              final lead = teamLeads[index];
              final isSelected = _selectedLeadId == lead['id'];
              final squadCount = allEmployees.where((e) => e['supervisor_id'] == lead['id']).length;

              return GestureDetector(
                onTap: () => setState(() => _selectedLeadId = lead['id']),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${lead['first_name']} ${lead['last_name'][0]}.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$squadCount Squad',
                        style: TextStyle(color: isSelected ? Colors.black.withOpacity(0.7) : SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(color: SuperAdminTheme.surfaceLighter, height: 1),
      ],
    );
  }

  Widget _buildSquadManager(Map<String, dynamic> lead, List<Map<String, dynamic>> allEmployees, {bool isMobile = false}) {
    final squad = allEmployees.where((e) => e['supervisor_id'] == lead['id']).toList();
    final nonSquad = allEmployees.where((e) => e['supervisor_id'] != lead['id'] && 
                                              (e['first_name'] + ' ' + e['last_name']).toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSquadHeader(lead),
                  const SizedBox(height: 16),
                  _buildSearchField(fullWidth: true),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSquadHeader(lead),
                  _buildSearchField(fullWidth: false),
                ],
              ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            children: [
              _buildSectionHeader('CURRENT SQUAD', SuperAdminTheme.statusPositive),
              const SizedBox(height: 12),
              if (squad.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No members assigned yet.', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12)),
                )
              else
                ...squad.map((member) => _buildMemberTile(member, isSelected: true)),

              const SizedBox(height: 32),
              _buildSectionHeader('GLOBAL DIRECTORY', SuperAdminTheme.textSecondary),
              const SizedBox(height: 12),
              ...nonSquad.take(15).map((member) => _buildMemberTile(member, isSelected: false)),
              if (nonSquad.length > 15)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Search to find more employees...', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10))),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSquadHeader(Map<String, dynamic> lead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${lead['first_name']}\'s Squad', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Manage team assignments below', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildSearchField({required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 280,
      height: 44,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: SuperAdminTheme.primaryOrange, size: 18),
          filled: true,
          fillColor: SuperAdminTheme.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SuperAdminTheme.primaryOrange, width: 1)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuperAdminTheme.surfaceLighter.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CommonAvatar(
            radius: 18,
            imageUrl: member['profile_picture_url'],
            isSquare: true,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${member['first_name']} ${member['last_name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(member['department_name'] ?? 'General', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSelected)
            _IconButton(
              icon: Icons.remove_circle_outline,
              color: Colors.redAccent,
              onPressed: () => _updateSupervisor(member['id'], null),
            )
          else
            _IconButton(
              icon: Icons.add_circle_outline,
              color: SuperAdminTheme.primaryOrange,
              onPressed: () => _updateSupervisor(member['id'], _selectedLeadId),
            ),
        ],
      ),
    );
  }

  Future<void> _updateSupervisor(int employeeId, int? supervisorId) async {
    try {
      final repo = ref.read(employeeRepositoryProvider);
      final fullEmpData = await repo.getEmployeeById(employeeId);
      final Map<String, dynamic> updatePayload = {
        ...fullEmpData.toJson(),
        'supervisor_id': supervisorId,
      };
      
      await repo.updateEmployee(employeeId, updatePayload);
      ref.invalidate(hrStaffListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supervisorId == null ? 'Member removed' : 'Member added'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: SuperAdminTheme.surfaceLighter,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
