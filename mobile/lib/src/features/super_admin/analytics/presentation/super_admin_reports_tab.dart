import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/super_admin_theme.dart';
import '../../data/super_admin_providers.dart';

class SuperAdminReportsTab extends ConsumerWidget {
  const SuperAdminReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(superAdminAttendanceOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(superAdminAttendanceOverviewProvider),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {}, // Future PDF/CSV export
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (data) {
          final weeklyTrends = (data['weeklyTrends'] as List).cast<Map<String, dynamic>>();
          final departments = (data['departments'] as List).cast<Map<String, dynamic>>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuickMetrics(data: data),
                const SizedBox(height: 24),
                _DetailedTrendChart(weeklyTrends: weeklyTrends),
                const SizedBox(height: 24),
                _DeptInsights(departments: departments),
                const SizedBox(height: 32),
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

class _QuickMetrics extends StatelessWidget {
  final Map<String, dynamic> data;
  const _QuickMetrics({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ReportMetric(title: 'PRESENCE RATE', value: '${data['dailyPresencePercent'] ?? 0}%', icon: Icons.percent, color: SuperAdminTheme.primaryOrange)),
            const SizedBox(width: 12),
            Expanded(child: _ReportMetric(title: 'PRESENT TODAY', value: (data['present'] ?? 0).toString(), icon: Icons.person_add, color: Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ReportMetric(title: 'LATE ARRIVALS', value: (data['lateArrivals'] ?? 0).toString(), icon: Icons.timer, color: SuperAdminTheme.statusNegative)),
            const SizedBox(width: 12),
            Expanded(child: _ReportMetric(title: 'OFF DUTY', value: ((data['total'] ?? 0) - (data['present'] ?? 0)).toString(), icon: Icons.person_off, color: SuperAdminTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportMetric({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetailedTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyTrends;
  const _DetailedTrendChart({required this.weeklyTrends});

  @override
  Widget build(BuildContext context) {
    if (weeklyTrends.isEmpty) return const SizedBox();

    final maxVal = weeklyTrends.map((e) => (e['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detailed Attendance Stats', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                maxY: maxVal * 1.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyTrends.length, (i) => FlSpot(i.toDouble(), (weeklyTrends[i]['count'] as int).toDouble())),
                    isCurved: true,
                    color: SuperAdminTheme.primaryOrange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: SuperAdminTheme.primaryOrange.withOpacity(0.1)),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        int index = v.toInt();
                        if (index >= 0 && index < weeklyTrends.length) {
                          return Text(weeklyTrends[index]['day_label'], style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptInsights extends StatelessWidget {
  final List<Map<String, dynamic>> departments;
  const _DeptInsights({required this.departments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Department Efficiency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...departments.map((dept) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(dept['department'], style: const TextStyle(color: Colors.white, fontSize: 12))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (dept['rate'] as int) / 100,
                    backgroundColor: SuperAdminTheme.surfaceLighter,
                    color: SuperAdminTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${dept['rate']}%', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
