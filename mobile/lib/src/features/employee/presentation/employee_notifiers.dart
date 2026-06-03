import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/attendance_repository.dart';
import '../data/leave_repository.dart';
import '../data/task_repository.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../attendance/presentation/geofence_config.dart';

part 'employee_notifiers.g.dart';

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  Future<Map<String, dynamic>?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return await ref.read(attendanceRepositoryProvider).getAttendanceStatus(user.employeeId);
  }

  Future<void> checkIn() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final position = await _determinePosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        GeofenceConfig.officeLatitude,
        GeofenceConfig.officeLongitude,
      );

      if (distance > GeofenceConfig.radiusLimit) {
        throw 'Please be within 100m of office to check in.';
      }

      await ref.read(attendanceRepositoryProvider).checkIn(user.employeeId, position.latitude, position.longitude);
      state = AsyncValue.data(await ref.read(attendanceRepositoryProvider).getAttendanceStatus(user.employeeId));
      ref.invalidate(attendanceHistoryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>?> checkOut(int attendanceId, {String? reason}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;

    state = const AsyncValue.loading();
    try {
      final result = await ref.read(attendanceRepositoryProvider).checkOut(user.employeeId, attendanceId, reason: reason);
      state = AsyncValue.data(await ref.read(attendanceRepositoryProvider).getAttendanceStatus(user.employeeId));
      ref.invalidate(attendanceHistoryProvider);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> startBreak(int attendanceId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(attendanceRepositoryProvider).startBreak(attendanceId);
      state = AsyncValue.data(await ref.read(attendanceRepositoryProvider).getAttendanceStatus(user.employeeId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> endBreak(int breakId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(attendanceRepositoryProvider).endBreak(breakId);
      state = AsyncValue.data(await ref.read(attendanceRepositoryProvider).getAttendanceStatus(user.employeeId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
Future<List<Map<String, dynamic>>> attendanceHistory(AttendanceHistoryRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(attendanceRepositoryProvider).getAttendanceHistory(user.employeeId);
}

@riverpod
class LeaveNotifier extends _$LeaveNotifier {
  @override
  Future<void> build() async {}

  Future<void> requestLeave(Map<String, dynamic> leaveData) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        leaveData['employee_id'] = user.employeeId;
      }
      await ref.read(leaveRepositoryProvider).requestLeave(leaveData);
      state = const AsyncValue.data(null);
      ref.invalidate(leaveHistoryProvider);
      ref.invalidate(leaveBalancesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

@riverpod
Future<List<Map<String, dynamic>>> leaveHistory(LeaveHistoryRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(leaveRepositoryProvider).getLeaveHistory(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> leaveBalances(LeaveBalancesRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(leaveRepositoryProvider).getLeaveBalances(user.employeeId);
}

@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return await ref.read(taskRepositoryProvider).getAssignedTasks(user.employeeId);
  }

  Future<void> updateStatus(int taskId, String status) async {
    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(taskId, status);
      ref.invalidateSelf();
    } catch (e) {
      // In a real app, handle error via state or snackbar
    }
  }
}

@riverpod
Future<List<Map<String, dynamic>>> employeeTasks(EmployeeTasksRef ref, int employeeId) async {
  return await ref.read(taskRepositoryProvider).getAssignedTasks(employeeId);
}
