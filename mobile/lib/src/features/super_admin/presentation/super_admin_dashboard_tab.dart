import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../analytics/presentation/super_admin_analytics_main_screen.dart';
import '../data/super_admin_providers.dart';
import '../../auth/presentation/auth_notifier.dart';

class SuperAdminDashboardTab extends ConsumerWidget {
  const SuperAdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let parent background show
      body: refreshableDashboard(context, ref, dashboardAsync),
    );
  }

  Widget refreshableDashboard(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>> dashboardAsync) {
    return dashboardAsync.when(
      data: (data) {
        final metrics = data['metrics'] as Map<String, dynamic>;
        final weeklyTrends = (data['weeklyTrends'] as List).cast<Map<String, dynamic>>();
        final departments = (data['departments'] as List).cast<Map<String, dynamic>>();


        return RefreshIndicator(
          onRefresh: () => ref.refresh(superAdminDashboardProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: SuperAdminTheme.primaryOrange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      ref.watch(currentUserProvider)?.roleName.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase()).join(' ').toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        color: SuperAdminTheme.primaryOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // METRIC CARDS 2x2 GRID
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'TOTAL EMPLOYEES',
                        value: NumberFormat('#,###').format(metrics['totalEmployees']),
                        subtitle: 'Active Workforce',
                        icon: Icons.groups,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SuperAdminAnalyticsMainScreen(initialTabIndex: 2),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'ACTIVE NOW',
                        value: NumberFormat('#,###').format(metrics['activeNow']),
                        subtitle: 'Real-time pulse',
                        subtitleColor: SuperAdminTheme.primaryOrange,
                        icon: Icons.bolt,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SuperAdminAnalyticsMainScreen(initialTabIndex: 0),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: SizedBox(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'PENDING LEAVES',
                        value: metrics['pendingLeaves'].toString(),
                        subtitle: 'Approval required',
                        icon: Icons.event_busy,
                        valueStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: metrics['pendingLeaves'] > 0 ? SuperAdminTheme.statusNegative : Colors.white),
                        iconColor: metrics['pendingLeaves'] > 0 ? SuperAdminTheme.statusNegative : SuperAdminTheme.primaryOrange,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SuperAdminAnalyticsMainScreen(initialTabIndex: 1),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // GLOBAL ATTENDANCE TRENDS
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const SuperAdminAnalyticsMainScreen(initialTabIndex: 0),
                    ));
                  },
                  child: Container(
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
                            const Icon(Icons.trending_up, color: SuperAdminTheme.primaryOrange, size: 20),
                            const SizedBox(width: 8),
                            const Text('Global Attendance Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _AttendanceBarChart(weeklyTrends: weeklyTrends),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // DEPARTMENT FOCUS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SuperAdminTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Department Focus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 20),
                      ...departments.take(5).map((dept) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _DepartmentFocusBar(dept: dept['name'], percentage: dept['rate']),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: SuperAdminTheme.statusNegative, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load dashboard', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                err.toString(), 
                textAlign: TextAlign.center,
                style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => ref.refresh(superAdminDashboardProvider), child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final TextStyle? valueStyle;
  final Color? iconColor;
  final Color? subtitleColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.valueStyle,
    this.iconColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SuperAdminTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: iconColor ?? SuperAdminTheme.primaryOrange, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitleColor == SuperAdminTheme.primaryOrange) ...[
                   Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: SizedBox(
                      width: 6, height: 6,
                      child: DecoratedBox(decoration: BoxDecoration(color: SuperAdminTheme.primaryOrange, shape: BoxShape.circle)),
                     ),
                   ),
                   const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(subtitle, style: TextStyle(color: subtitleColor ?? SuperAdminTheme.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyTrends;

  const _AttendanceBarChart({required this.weeklyTrends});

  @override
  Widget build(BuildContext context) {
    if (weeklyTrends.isEmpty) {
      return const SizedBox(height: 150, child: Center(child: Text('No data', style: TextStyle(color: SuperAdminTheme.textSecondary))));
    }

    final maxVal = weeklyTrends.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    final yInterval = maxVal > 5 ? maxVal / 5 : 1.0;

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => SuperAdminTheme.surfaceLighter,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${weeklyTrends[groupIndex]['day_label']}\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < weeklyTrends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        weeklyTrends[index]['day_label'],
                        style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 28,
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
                  color: index == weeklyTrends.length - 1 ? SuperAdminTheme.primaryOrange : SuperAdminTheme.surfaceLighter,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: SuperAdminTheme.backgroundBlack.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _DepartmentFocusBar extends StatelessWidget {
  final String dept;
  final int percentage;

  const _DepartmentFocusBar({required this.dept, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(dept, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: SuperAdminTheme.surfaceLighter,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: percentage.clamp(1, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: SuperAdminTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(flex: (100 - percentage).clamp(0, 100), child: const SizedBox()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 40, child: Text('$percentage%', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
