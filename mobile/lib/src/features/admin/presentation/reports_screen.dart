import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _loading = true;
  final List<Map<String, dynamic>> _workforceData = [];
  final List<Map<String, dynamic>> _attendanceData = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Re-using the logic from repository or direct calls if needed
      // Here we assume the repository has methods or we add them
      // Since workforce/attendance are basic analytics, we can fetch them
      final repo = ref.read(adminRepositoryProvider);
      // We'll update the repo with these soon or use direct calls
      // For now, let's assume they are available or we add them
      
      // I'll add these to the repo in the next step to keep it clean
      // but for now let's just use the current dashboard data to mock if needed
      // or better, I'll update the repo now.
      setState(() { _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('CORE ANALYTICS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
             const Text('DATA VISUALIZATION', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
             const Text('Reports & Trends', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
             const SizedBox(height: 32),

             _SectionHeader(title: 'Workforce Distribution', icon: Icons.pie_chart_outline),
             const SizedBox(height: 20),
             const _WorkforcePieChart(),
             const SizedBox(height: 48),

             _SectionHeader(title: 'Attendance Trends (7 Days)', icon: Icons.stacked_bar_chart_outlined),
             const SizedBox(height: 20),
             const _AttendanceBarChart(),

             const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SuperAdminTheme.primaryOrange, size: 20),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _WorkforcePieChart extends ConsumerWidget {
  const _WorkforcePieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      // We'll add this method to AdminRepository
      future: ref.read(adminRepositoryProvider).getWorkforceStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Container(height: 100, decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('No correlation data available', style: TextStyle(color: SuperAdminTheme.textSecondary))));
        }
        
        final List data = snapshot.data as List;
        final colors = [
          SuperAdminTheme.primaryOrange,
          const Color(0xFF8C471E),
          Colors.blueAccent,
          Colors.indigoAccent,
          Colors.tealAccent,
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: data.asMap().entries.map((entry) {
                      final val = (entry.value['value'] ?? 0).toDouble();
                      final label = entry.value['label'] ?? 'Unknown';
                      return PieChartSectionData(
                        value: val,
                        title: '$val',
                        color: colors[entry.key % colors.length],
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        badgeWidget: _Badge(label, colors[entry.key % colors.length]),
                        badgePositionPercentageOffset: 1.4,
                      );
                    }).toList().cast<PieChartSectionData>(),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}

class _AttendanceBarChart extends ConsumerWidget {
  const _AttendanceBarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(adminRepositoryProvider).getAttendanceStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const SizedBox(height: 100, child: Center(child: Text('Insufficient historical data', style: TextStyle(color: SuperAdminTheme.textSecondary))));
        }
        
        final List data = snapshot.data as List;
        double maxVal = 1;
        for (var item in data) {
          if (item['value'].toDouble() > maxVal) maxVal = item['value'].toDouble();
        }

        return Container(
          height: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(20)),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length) return const Text('');
                      final dateStr = data[value.toInt()]['label'] ?? '';
                      // Format date to MM/DD
                      String label = dateStr;
                      try {
                        final dt = DateTime.parse(dateStr);
                        label = '${dt.month}/${dt.day}';
                      } catch (_) {}
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value['value'].toDouble(),
                      color: SuperAdminTheme.primaryOrange,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxVal * 1.2,
                        color: SuperAdminTheme.backgroundBlack,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
