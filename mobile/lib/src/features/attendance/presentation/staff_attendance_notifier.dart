import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/attendance_repository.dart';

part 'staff_attendance_notifier.g.dart';

@riverpod
class StaffAttendanceNotifier extends _$StaffAttendanceNotifier {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    return ref.read(attendanceRepositoryProvider).getStaffTodayAttendance();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}
