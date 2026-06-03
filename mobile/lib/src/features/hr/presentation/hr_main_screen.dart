import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../attendance/presentation/geofence_config.dart';
import '../../attendance/presentation/geofence_warning_dialog.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../employee/presentation/emp_leave_tab.dart';
import 'hr_dashboard_tab.dart';
import 'hr_staff_tab.dart';

import 'hr_data_tab.dart';
import 'hr_schedule_screen.dart';
import 'hr_team_management_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../../core/common_widgets/common_avatar.dart';
import 'hr_profile_screen.dart';
import '../../employee/presentation/employee_notifiers.dart';

class HrMainScreen extends ConsumerStatefulWidget {
  const HrMainScreen({super.key});

  @override
  ConsumerState<HrMainScreen> createState() => _HrMainScreenState();
}

class _HrMainScreenState extends ConsumerState<HrMainScreen> {
  int _currentIndex = 0;
  Timer? _breakMonitoringTimer;
  DateTime? _geofenceWarningStartTime;
  bool _isWarningDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Start monitoring break duration and geofence every 30 seconds
    _breakMonitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final statusData = ref.read(attendanceNotifierProvider).valueOrNull;
      if (statusData == null) return;

      final currentStatus = statusData['status'];

      if (currentStatus == 'CHECKED_IN') {
        _checkGeofence(statusData['attendanceId']);
      } else {
        // If ON_BREAK or NOT_CHECKED_IN, reset geofence warning
        _geofenceWarningStartTime = null;
        if (_isWarningDialogShowing) {
           _isWarningDialogShowing = false;
           Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (currentStatus == 'ON_BREAK') {
        final startTimeStr = statusData['currentBreakStart'];
        if (startTimeStr != null) {
          final startTime = DateTime.parse(startTimeStr).toLocal();
          final elapsed = DateTime.now().difference(startTime);
          
          if (elapsed.inMinutes >= 60) {
            _handleAutoLogout();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _breakMonitoringTimer?.cancel();
    super.dispose();
  }

  void _checkGeofence(int attendanceId) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        GeofenceConfig.officeLatitude,
        GeofenceConfig.officeLongitude,
      );

      if (distance > GeofenceConfig.radiusLimit) {
        if (_geofenceWarningStartTime == null) {
          _geofenceWarningStartTime = DateTime.now();
          _showGeofenceWarningDialog(attendanceId);
          ref.read(notificationServiceProvider).showWarningNotification(
            'Outside Geofence', 
            'Please turn on your break or return to the office within 15 minutes, or you will be automatically checked out.',
          );
        } else {
          final elapsed = DateTime.now().difference(_geofenceWarningStartTime!);
          if (elapsed.inMinutes >= 15) {
            _geofenceWarningStartTime = null;
            if (_isWarningDialogShowing) {
               _isWarningDialogShowing = false;
               Navigator.of(context, rootNavigator: true).pop();
            }
            _handleGeofenceCheckOut(attendanceId);
          }
        }
      } else {
        // User returned to geofence
        _geofenceWarningStartTime = null;
        if (_isWarningDialogShowing) {
           _isWarningDialogShowing = false;
           Navigator.of(context, rootNavigator: true).pop();
        }
      }
    } catch (e) {
      print('Geofence check failed: $e');
    }
  }

  void _showGeofenceWarningDialog(int attendanceId) {
    if (!mounted || _geofenceWarningStartTime == null || _isWarningDialogShowing) return;
    _isWarningDialogShowing = true;
    final expiry = _geofenceWarningStartTime!.add(const Duration(minutes: 15));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GeofenceWarningDialog(
        expiryTime: expiry,
        onDismiss: () {
          _isWarningDialogShowing = false;
          Navigator.pop(context);
        },
        onTurnOnBreak: () {
          _isWarningDialogShowing = false;
          ref.read(attendanceNotifierProvider.notifier).startBreak(attendanceId);
        },
      ),
    ).then((_) {
      _isWarningDialogShowing = false;
    });
  }

  void _handleGeofenceCheckOut(int attendanceId) async {
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: SuperAdminTheme.surfaceCard,
        title: const Text('Outside Geofence', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You are outside the 100m office radius. You have been automatically checked out for attendance accuracy.',
          style: TextStyle(color: SuperAdminTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.primaryOrange),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    await ref.read(attendanceNotifierProvider.notifier).checkOut(attendanceId, reason: 'Automatic check-out: Outside geofence');
  }

  void _handleAutoLogout() async {
    _breakMonitoringTimer?.cancel();
    if (!mounted) return;
    
    // Show dialog before logout
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: SuperAdminTheme.surfaceCard,
        title: const Text('Session Expired', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have been on break for more than 1 hour. For security, you have been logged out. Please log in again.',
          style: TextStyle(color: SuperAdminTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.primaryOrange),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    await ref.read(authNotifierProvider.notifier).logout();
  }

  final List<Widget> _tabs = [
    const HrDashboardTab(),
    const HrStaffTab(),
    const HrScheduleScreen(),
    const HrDataTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: SuperAdminTheme.primaryOrange),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: const Text('Vorcas Tech Lab HR', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: SuperAdminTheme.primaryOrange),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
              },
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrProfileScreen())),
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CommonAvatar(
                  radius: 16,
                  imageUrl: ref.watch(currentUserProvider)?.profilePictureUrl,
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: SuperAdminTheme.surfaceCard,
          child: SafeArea(
            child: Column(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack),
                  child: Center(child: Text('Vorcas Tech Lab HR', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [

                      ListTile(
                        leading: const Icon(Icons.dashboard, color: SuperAdminTheme.textSecondary),
                        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setState(() => _currentIndex = 0);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: SuperAdminTheme.textSecondary),
                        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.leave_bags_at_home, color: SuperAdminTheme.textSecondary),
                        title: const Text('Leave Management', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmpLeaveTab()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.groups, color: SuperAdminTheme.textSecondary),
                        title: const Text('Team Management', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HrTeamManagementScreen()));
                        },
                      ),
                      const Divider(color: SuperAdminTheme.surfaceLighter),
                      ListTile(
                        leading: const Icon(Icons.settings, color: SuperAdminTheme.textSecondary),
                        title: const Text('Settings', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: SuperAdminTheme.surfaceCard),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          currentIndex: _currentIndex,
          selectedItemColor: SuperAdminTheme.primaryOrange,
          unselectedItemColor: SuperAdminTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'STAFF'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'SCHEDULE'),
            BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'DATA'),
          ],
        ),
      ),
    );
  }
}
