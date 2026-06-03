import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../attendance/presentation/geofence_config.dart';
import '../../attendance/presentation/geofence_warning_dialog.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/theme/super_admin_theme.dart';
import 'emp_dashboard_tab.dart';
import 'emp_attend_tab.dart';
import 'emp_leave_tab.dart';
import 'emp_tasks_tab.dart';
import 'employee_notifiers.dart';

import 'emp_profile_screen.dart';
import 'completed_tasks_screen.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../../core/common_widgets/common_avatar.dart';

class EmpMainScreen extends ConsumerStatefulWidget {
  const EmpMainScreen({super.key});

  @override
  ConsumerState<EmpMainScreen> createState() => _EmpMainScreenState();
}

class _EmpMainScreenState extends ConsumerState<EmpMainScreen> {
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

  late final List<Widget> _tabs = [
    EmpDashboardTab(onTasksTapped: () => setState(() => _currentIndex = 2)),
    const EmpAttendTab(),
    const EmpTasksTab(),
  ];

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
  }

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
          title: const Text('WORKFORCE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: SuperAdminTheme.primaryOrange),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlertsScreen()));
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CommonAvatar(
                radius: 16,
                imageUrl: ref.watch(currentUserProvider)?.profilePictureUrl,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmpProfileScreen()));
                },
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: SuperAdminTheme.backgroundBlack,
          child: SafeArea(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommonAvatar(
                          radius: 32,
                          imageUrl: ref.watch(currentUserProvider)?.profilePictureUrl,
                        ),
                        SizedBox(height: 12),
                        Text('My Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('EMPLOYEE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined, color: SuperAdminTheme.textSecondary),
                  title: const Text('Leave Management', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmpLeaveTab()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.task_alt, color: SuperAdminTheme.textSecondary),
                  title: const Text('Completed Tasks', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop(); // Close drawer
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompletedTasksScreen()));
                  },
                ),
                const Divider(color: SuperAdminTheme.surfaceCard),
                const Spacer(),
                const Divider(color: SuperAdminTheme.surfaceCard),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: _logout,
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 1.0),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 1.0),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'ATTENDANCE'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'TASKS'),
          ],
        ),
      ),
    );
  }
}
