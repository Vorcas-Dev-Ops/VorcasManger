import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/super_admin_theme.dart';
import '../../data/super_admin_providers.dart';

class SuperAdminWorkforceTab extends ConsumerWidget {
  const SuperAdminWorkforceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(workforceDistributionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workforce Distribution', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(workforceDistributionProvider),
          ),
        ],
      ),
      body: distributionAsync.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RolePieChart(data: data),
                const SizedBox(height: 24),
                _RoleList(data: data),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _RolePieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RolePieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [
      SuperAdminTheme.primaryOrange,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Employee Breakdown by Role', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: List.generate(data.length, (index) {
                  final item = data[index];
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: (item['value'] as int).toDouble(),
                    title: '${item['value']}',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RoleList({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [
      SuperAdminTheme.primaryOrange,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Headcount by Role', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...List.generate(data.length, (index) {
            final item = data[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(item['label'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  Text('${item['value']}', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
