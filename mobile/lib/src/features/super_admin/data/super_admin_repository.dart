import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'super_admin_repository.g.dart';

class SuperAdminRepository {
  final Dio _dio;

  SuperAdminRepository(this._dio);

  // --- Super Admin Dashboard ---
  Future<Map<String, dynamic>> getSuperAdminDashboard() async {
    try {
      final response = await _dio.get('/analytics/super-admin-dashboard');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        print('DIOR_ERROR [/analytics/super-admin-dashboard]: ${e.response?.statusCode} -> ${e.response?.data}');
      }
      rethrow;
    }
  }

  // --- Workforce Distribution ---
  Future<List<Map<String, dynamic>>> getWorkforceDistribution() async {
    final response = await _dio.get('/analytics/workforce-distribution');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Attendance Stats ---
  Future<List<Map<String, dynamic>>> getAttendanceStats() async {
    final response = await _dio.get('/analytics/attendance');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Attendance Overview ---
  Future<Map<String, dynamic>> getAttendanceOverview() async {
    final response = await _dio.get('/analytics/attendance-overview');
    return response.data as Map<String, dynamic>;
  }

  // --- Employees ---
  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final response = await _dio.get('/employee/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Leave Management ---
  Future<List<Map<String, dynamic>>> getPendingLeaves() async {
    final response = await _dio.get('/leave/pending');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> approveLeave(int leaveId, String status, int approverId) async {
    await _dio.post('/leave/approve', data: {
      'leave_id': leaveId,
      'status': status,
      'approver_id': approverId,
    });
  }

  // --- Task Management ---
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final response = await _dio.get('/task/all');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTaskOverview() async {
    final response = await _dio.get('/analytics/task-overview');
    return response.data as Map<String, dynamic>;
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    await _dio.post('/task/create', data: taskData);
  }


  // --- Departments ---
  Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await _dio.get('/department/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}

@riverpod
SuperAdminRepository superAdminRepository(SuperAdminRepositoryRef ref) {
  return SuperAdminRepository(ref.watch(dioClientProvider));
}
