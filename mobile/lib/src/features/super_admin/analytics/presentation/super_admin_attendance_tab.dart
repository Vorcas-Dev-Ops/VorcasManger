import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/super_admin_theme.dart';
import '../../data/super_admin_providers.dart';

class SuperAdminAttendanceTab extends ConsumerWidget {
  const SuperAdminAttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(superAdminAttendanceOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(superAdminAttendanceOverviewProvider),
          ),
        ],
      ),
      body: attendanceAsync.when(
        data: (data) {
          final weeklyTrends = (data['weeklyTrends'] as List).cast<Map<String, dynamic>>();
          final todayLog = (data['todayLog'] as List).cast<Map<String, dynamic>>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryMetrics(data: data),
                const SizedBox(height: 24),
                _AttendanceChart(weeklyTrends: weeklyTrends),
                const SizedBox(height: 24),
                _DailyAttendanceLog(todayLog: todayLog),
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

class _SummaryMetrics extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SummaryMetrics({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'PRESENT TODAY',
            value: data['present'].toString(),
            subtitle: '${data['dailyPresencePercent']}% average',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'EARLY CHECKOUTS',
            value: (data['earlyCheckouts'] ?? 0).toString(),
            subtitle: 'Today',
            valueColor: SuperAdminTheme.primaryOrange,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyTrends;
  const _AttendanceChart({required this.weeklyTrends});

  @override
  Widget build(BuildContext context) {
    if (weeklyTrends.isEmpty) return const SizedBox();

    final maxVal = weeklyTrends.map((e) => (e['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7-Day Attendance Trend', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < weeklyTrends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(weeklyTrends[index]['day_label'], style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                          );
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
                barGroups: List.generate(weeklyTrends.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (weeklyTrends[index]['count'] as int).toDouble(),
                        color: SuperAdminTheme.primaryOrange,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
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

class _DailyAttendanceLog extends StatelessWidget {
  final List<Map<String, dynamic>> todayLog;
  const _DailyAttendanceLog({required this.todayLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuperAdminTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Attendance Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (todayLog.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No attendance recorded yet', style: TextStyle(color: SuperAdminTheme.textSecondary))),
            )
          else
            ...todayLog.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: SuperAdminTheme.backgroundBlack,
                    child: Text(log['name']?[0] ?? '?', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('Checked in today', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    log['time'] != null ? log['time'].toString().substring(0, 5) : '--:--',
                    style: const TextStyle(
                      color: SuperAdminTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

