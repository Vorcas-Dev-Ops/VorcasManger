import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/department_model.dart';


part 'admin_repository.g.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // --- Department CRUD ---
  Future<List<DepartmentModel>> getDepartments() async {
    final response = await _dio.get('/department/');
    return (response.data as List).map((json) => DepartmentModel.fromJson(json)).toList();
  }

  Future<void> createDepartment(String name, String description) async {
    await _dio.post('/department/', data: {'name': name, 'description': description});
  }

  Future<void> updateDepartment(int id, String name, String description) async {
    await _dio.put('/department/$id', data: {'name': name, 'description': description});
  }

  Future<void> deleteDepartment(int id) async {
    await _dio.delete('/department/$id');
  }


  // --- Admin Dashboard ---
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _dio.get('/analytics/admin-dashboard');
    return response.data as Map<String, dynamic>;
  }

  // --- Attendance Overview ---
  Future<Map<String, dynamic>> getAttendanceOverview() async {
    final response = await _dio.get('/analytics/attendance-overview');
    return response.data as Map<String, dynamic>;
  }

  // --- Task Overview ---
  Future<Map<String, dynamic>> getTaskOverview() async {
    final response = await _dio.get('/analytics/task-overview');
    return response.data as Map<String, dynamic>;
  }

  // --- Roles ---
  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _dio.get('/auth/roles');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateEmployeeRole(int employeeId, int roleId) async {
    await _dio.put('/employee/$employeeId/role', data: {'role_id': roleId});
  }

  Future<List<Map<String, dynamic>>> getWorkforceStats() async {
    final response = await _dio.get('/analytics/workforce');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAttendanceStats() async {
    final response = await _dio.get('/analytics/attendance');
    return (response.data as List).cast<Map<String, dynamic>>();
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

  Future<void> createTask(Map<String, dynamic> taskData) async {
    await _dio.post('/task/create', data: taskData);
  }

  // --- Attendance Details ---
  Future<List<Map<String, dynamic>>> getStaffTodayAttendance() async {
    final response = await _dio.get('/attendance/staff-today');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateAttendanceStatus(int attendanceId, String status) async {
    // Optional: for manual overrides by Admin
    await _dio.put('/attendance/update-status', data: {
      'attendance_id': attendanceId,
      'status': status,
    });
  }
}

@riverpod
AdminRepository adminRepository(AdminRepositoryRef ref) {
  return AdminRepository(ref.watch(dioClientProvider));
}
