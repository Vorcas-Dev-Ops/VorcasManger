import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'tl_repository.g.dart';

class TlRepository {
  final Dio _dio;

  TlRepository(this._dio);

  Future<Map<String, dynamic>> getDashboardStats(int tlId) async {
    final response = await _dio.get('/tl/dashboard-stats/$tlId');
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getSquad(int tlId) async {
    final response = await _dio.get('/tl/squad/$tlId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getTeamAttendance(int tlId) async {
    final response = await _dio.get('/tl/team-attendance/$tlId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getTeamTasks(int tlId) async {
    final response = await _dio.get('/tl/team-tasks/$tlId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getTeamLeaves(int tlId) async {
    final response = await _dio.get('/tl/team-leaves/$tlId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    await _dio.post('/task/create', data: taskData);
  }

  Future<List<Map<String, dynamic>>> getSquadTaskProgress(int tlId) async {
    final response = await _dio.get('/tl/squad-progress/$tlId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getUnassignedEmployees() async {
    final response = await _dio.get('/tl/unassigned-employees');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> addToSquad(int tlId, int employeeId) async {
    await _dio.post('/tl/add-to-squad', data: {
      'tlId': tlId,
      'employeeId': employeeId,
    });
  }
}


@riverpod
TlRepository tlRepository(TlRepositoryRef ref) {
  return TlRepository(ref.watch(dioClientProvider));
}
