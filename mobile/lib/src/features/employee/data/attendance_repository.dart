import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'attendance_repository.g.dart';

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<Map<String, dynamic>> getAttendanceStatus(int employeeId) async {
    try {
      final response = await _dio.get('/attendance/status/$employeeId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkIn(int employeeId, double lat, double long) async {
    try {
      await _dio.post('/attendance/check-in', data: {
        'employeeId': employeeId,
        'latitude': lat,
        'longitude': long,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkOut(int employeeId, int attendanceId, {String? reason}) async {
    try {
      final response = await _dio.post('/attendance/check-out', data: {
        'employeeId': employeeId,
        'attendanceId': attendanceId,
        'reason': reason,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startBreak(int attendanceId) async {
    try {
      await _dio.post('/attendance/break/start', data: {'attendanceId': attendanceId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> endBreak(int breakId) async {
    try {
      await _dio.post('/attendance/break/end', data: {'breakId': breakId});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(int employeeId) async {
    try {
      final response = await _dio.get('/attendance/history/$employeeId');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
AttendanceRepository attendanceRepository(AttendanceRepositoryRef ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
}
