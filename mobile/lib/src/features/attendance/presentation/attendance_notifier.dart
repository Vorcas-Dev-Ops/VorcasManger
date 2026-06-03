import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

part 'attendance_notifier.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  Future<List<AttendanceModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(attendanceRepositoryProvider).getHistory(user.employeeId);
  }

  Future<void> checkIn(BuildContext context) async {
    print('DEBUG: checkIn button TAPPED');
    final user = ref.read(currentUserProvider);
    if (user == null) {
      print('DEBUG: user is NULL in checkIn');
      return;
    }
    print('DEBUG: user found, ID: ${user.employeeId}');
    
    final messenger = ScaffoldMessenger.of(context);
    
    state = const AsyncValue.loading();
    try {
      print('Attendance: Determining position...');
      final position = await _determinePosition(context);
      print('Attendance: Position found - ${position.latitude}, ${position.longitude}');
      
      print('Attendance: Sending check-in request for employee ${user.employeeId}...');
      await ref.read(attendanceRepositoryProvider).checkIn(
            user.employeeId,
            position.latitude,
            position.longitude,
          );
      
      print('Attendance: Check-in successful, refreshing history...');
      state = await AsyncValue.guard(() => ref.read(attendanceRepositoryProvider).getHistory(user.employeeId));
      
      messenger.showSnackBar(const SnackBar(content: Text('Checked in successfully!'), backgroundColor: Colors.green));
    } catch (e, st) {
      print('Attendance: Check-in ERROR - $e');
      state = AsyncValue.error(e, st);
      messenger.showSnackBar(SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> checkOut(BuildContext context, int attendanceId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);

    state = const AsyncValue.loading();
    try {
      await ref.read(attendanceRepositoryProvider).checkOut(user.employeeId, attendanceId);
      state = await AsyncValue.guard(() => ref.read(attendanceRepositoryProvider).getHistory(user.employeeId));
      messenger.showSnackBar(const SnackBar(content: Text('Checked out successfully!'), backgroundColor: Colors.green));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      messenger.showSnackBar(SnackBar(content: Text('Check-out failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<Position> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text('Vorcas Manager collects location data to verify your attendance check-ins against the office geofence.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I UNDERSTAND'),
              ),
            ],
          ),
        );
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    ).catchError((e) async {
      print('Attendance: getCurrentPosition timed out or failed ($e), trying last known...');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw Exception('Could not determine location: $e');
    });
  }
}
