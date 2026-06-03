import 'package:flutter/material.dart';
import '../../../../core/theme/super_admin_theme.dart';
import 'super_admin_reports_tab.dart';
import 'super_admin_leave_tab.dart';
import 'super_admin_attendance_tab.dart';
import 'super_admin_workforce_tab.dart';

class SuperAdminAnalyticsMainScreen extends StatefulWidget {
  final int initialTabIndex;
  const SuperAdminAnalyticsMainScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SuperAdminAnalyticsMainScreen> createState() => _SuperAdminAnalyticsMainScreenState();
}

class _SuperAdminAnalyticsMainScreenState extends State<SuperAdminAnalyticsMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  final List<Widget> _screens = [
    const SuperAdminAttendanceTab(),
    const SuperAdminLeaveTab(),
    const SuperAdminWorkforceTab(),
    const SuperAdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'ATTENDANCE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_busy_outlined),
              activeIcon: Icon(Icons.event_busy),
              label: 'LEAVE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'WORKFORCE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart),
              label: 'REPORTS',
            ),
          ],
        ),
      ),
    );
  }
}
