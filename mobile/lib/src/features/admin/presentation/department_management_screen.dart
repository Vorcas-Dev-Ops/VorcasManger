import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../domain/department_model.dart';

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  ConsumerState<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends ConsumerState<DepartmentManagementScreen> {
  late Future<List<DepartmentModel>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _departmentsFuture = ref.read(adminRepositoryProvider).getDepartments();
    });
  }

  void _showDeptDialog({DepartmentModel? department}) {
    final nameController = TextEditingController(text: department?.name ?? '');
    final descController = TextEditingController(text: department?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(department == null ? 'Add Department' : 'Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Dept Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (department == null) {
                await ref.read(adminRepositoryProvider).createDepartment(nameController.text, descController.text);
              } else {
                await ref.read(adminRepositoryProvider).updateDepartment(department.id, nameController.text, descController.text);
              }
              _refresh();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: FutureBuilder<List<DepartmentModel>>(
        future: _departmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final depts = snapshot.data ?? [];
          return ListView.builder(
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return ListTile(
                title: Text(dept.name),
                subtitle: Text(dept.description),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showDeptDialog(department: dept)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeptDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
