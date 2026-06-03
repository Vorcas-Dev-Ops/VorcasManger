import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/super_admin_providers.dart';

class SuperAdminDepartmentsScreen extends ConsumerWidget {
  const SuperAdminDepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(superAdminDepartmentsProvider);

    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          title: const Text('Department Management', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(superAdminDepartmentsProvider),
            ),
          ],
        ),
        body: deptsAsync.when(
          data: (depts) {
            if (depts.isEmpty) {
              return const Center(child: Text('No departments found', style: TextStyle(color: SuperAdminTheme.textSecondary)));
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(superAdminDepartmentsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: depts.length,
                separatorBuilder: (context, index) => const Divider(color: SuperAdminTheme.surfaceLighter, height: 24),
                itemBuilder: (context, index) {
                  final dept = depts[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SuperAdminTheme.primaryOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.business, color: SuperAdminTheme.primaryOrange, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dept['name'] ?? 'No Name',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dept['description'] ?? 'No description provided.',
                                    style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Placeholder for creating department
          },
          backgroundColor: SuperAdminTheme.primaryOrange,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}
