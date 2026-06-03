import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../data/admin_repository.dart';

class AdminAttendanceTab extends ConsumerStatefulWidget {
  const AdminAttendanceTab({super.key});

  @override
  ConsumerState<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends ConsumerState<AdminAttendanceTab> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _staffAttendance = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getAttendanceOverview();
      final staff = await repo.getStaffTodayAttendance();
      if (mounted) {
        setState(() {
          _data = data;
          _staffAttendance = staff;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load attendance: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: SuperAdminTheme.primaryOrange)),
      );
    }

    final dailyPresence = (_data?['dailyPresencePercent'] ?? 0).toDouble();
    final lateArrivals = _data?['lateArrivals'] ?? 0;
    final earlyCheckouts = _data?['earlyCheckouts'] ?? 0;
    final weeklyTrends = (_data?['weeklyTrends'] as List?) ?? [];
    final peakDay = _data?['peakDay'] ?? 'N/A';
    final departments = (_data?['departments'] as List?) ?? [];
    final present = _data?['present'] ?? 0;
    final total = _data?['total'] ?? 0;

    // Calculate max for chart
    double maxCount = 1;
    for (final entry in weeklyTrends) {
      final c = (entry['count'] ?? 0).toDouble();
      if (c > maxCount) maxCount = c;
    }

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      body: RefreshIndicator(
        color: SuperAdminTheme.primaryOrange,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SYSTEM ANALYTICS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    Text('Attendance', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
                  child: Text('$present / $total today', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daily Presence Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SuperAdminTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SuperAdminTheme.primaryOrange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAILY PRESENCE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${dailyPresence.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      const Text('%', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule, color: Colors.lightBlueAccent),
                        const SizedBox(height: 16),
                        Text(lateArrivals.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('LATE ARRIVALS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_busy, color: Colors.pinkAccent),
                        const SizedBox(height: 16),
                        Text(earlyCheckouts.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('EARLY CHECKOUTS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('WEEKLY TRENDS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: weeklyTrends.isEmpty
                        ? const Center(child: Text('No data', style: TextStyle(color: SuperAdminTheme.textSecondary)))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: weeklyTrends.map<Widget>((entry) {
                              final count = (entry['count'] ?? 0).toDouble();
                              final label = (entry['day_label'] ?? '').toString().substring(0, 3);
                              final barHeight = (count / maxCount) * 100;
                              final isPeak = entry['day_label'] == peakDay;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${count.toInt()}', style: TextStyle(color: isPeak ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barHeight.clamp(4, 100),
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: isPeak ? SuperAdminTheme.primaryOrange : const Color(0xFF8C471E),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(label, style: TextStyle(color: isPeak ? SuperAdminTheme.primaryOrange : SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: SuperAdminTheme.surfaceLighter),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PEAK ACTIVITY', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(peakDay, style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('DEPARTMENT PERFORMANCE', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            if (departments.isEmpty)
              const Text('No department data', style: TextStyle(color: SuperAdminTheme.textSecondary))
            else
              ...departments.take(3).map<Widget>((dept) {
                final rate = (dept['rate'] ?? 0) / 100.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.business, color: SuperAdminTheme.primaryOrange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${dept['department'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            Text('${dept['totalMembers'] ?? 0} Members', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                          ],
                        )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${dept['rate'] ?? 0}%', style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(width: 60, child: LinearProgressIndicator(value: rate.clamp(0.0, 1.0), backgroundColor: SuperAdminTheme.backgroundBlack, valueColor: const AlwaysStoppedAnimation<Color>(SuperAdminTheme.primaryOrange), minHeight: 4, borderRadius: BorderRadius.circular(2))),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            const Text('TODAY\'S STAFF STATUS', style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            if (_staffAttendance.isEmpty)
              const Center(child: Text('No attendance records for today', style: TextStyle(color: SuperAdminTheme.textSecondary)))
            else
              ..._staffAttendance.map((staff) {
                final String status = staff['status'] ?? 'ABSENT';
                final Color statusColor = status == 'PRESENT' ? Colors.greenAccent : (status == 'ABSENT' ? Colors.redAccent : Colors.orangeAccent);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SuperAdminTheme.backgroundBlack,
                        child: Text(staff['name']?[0] ?? '?', style: const TextStyle(color: SuperAdminTheme.primaryOrange)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(staff['role'] ?? 'Employee', style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          if (staff['checkIn'] != null)
                            Text(_formatTime(staff['checkIn']), style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }
}
