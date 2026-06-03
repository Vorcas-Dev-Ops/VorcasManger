import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';

class AdminRoleDialog extends ConsumerStatefulWidget {
  final int employeeId;
  final String employeeName;
  final int currentRoleId;

  const AdminRoleDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.currentRoleId,
  });

  @override
  ConsumerState<AdminRoleDialog> createState() => _AdminRoleDialogState();
}

class _AdminRoleDialogState extends ConsumerState<AdminRoleDialog> {
  List<Map<String, dynamic>> _roles = [];
  int? _selectedRoleId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoleId = widget.currentRoleId;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await ref.read(adminRepositoryProvider).getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _save() async {
    if (_selectedRoleId == null || _selectedRoleId == widget.currentRoleId) return;

    setState(() { _saving = true; });
    try {
      await ref.read(adminRepositoryProvider).updateEmployeeRole(widget.employeeId, _selectedRoleId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() { _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update role'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  IconData _roleIcon(String roleName) {
    final name = roleName.toUpperCase();
    if (name.contains('ADMIN')) return Icons.security;
    if (name.contains('HR')) return Icons.manage_accounts;
    if (name.contains('TEAM_LEAD')) return Icons.group_work;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SuperAdminTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: SuperAdminTheme.surfaceLighter)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Role Assignment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: SuperAdminTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13),
                children: [
                   const TextSpan(text: 'Modifying permissions for '),
                   TextSpan(text: widget.employeeName, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange),
              ))
            else
              ..._roles.map((role) {
                final roleId = role['id'] as int;
                final roleName = role['roleName'] as String;
                final isSelected = _selectedRoleId == roleId;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedRoleId = roleId; }),
                    child: _RoleOption(
                      title: roleName.replaceAll('_', ' '),
                      desc: 'Access Level: ${role['hierarchyLevel']}',
                      icon: _roleIcon(roleName),
                      isSelected: isSelected,
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: SuperAdminTheme.surfaceLighter),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving || _selectedRoleId == widget.currentRoleId ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuperAdminTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRM ROLE\nCHANGE', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 10)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool isSelected;

  const _RoleOption({required this.title, required this.desc, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? SuperAdminTheme.backgroundBlack : SuperAdminTheme.surfaceLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? SuperAdminTheme.primaryOrange : Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? SuperAdminTheme.primaryOrange.withOpacity(0.15) : SuperAdminTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isSelected ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
