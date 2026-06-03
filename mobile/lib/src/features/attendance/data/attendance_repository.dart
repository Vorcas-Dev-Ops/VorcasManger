import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/attendance_model.dart';

part 'attendance_repository.g.dart';

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<int> checkIn(int employeeId, double latitude, double longitude) async {
    try {
      final response = await _dio.post('/attendance/check-in', data: {
        'employeeId': employeeId,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data['id'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkOut(int employeeId, int attendanceId) async {
    try {
      await _dio.post('/attendance/check-out', data: {
        'employeeId': employeeId,
        'attendanceId': attendanceId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getHistory(int employeeId) async {
    try {
      final response = await _dio.get('/attendance/history/$employeeId');
      final data = response.data;
      if (data is! List) {
        return [];
      }
      return data.map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStaffTodayAttendance() async {
    try {
      final response = await _dio.get('/attendance/staff-today');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
AttendanceRepository attendanceRepository(AttendanceRepositoryRef ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
}
