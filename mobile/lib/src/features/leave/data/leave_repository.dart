import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/leave_model.dart';

part 'leave_repository.g.dart';

class LeaveRepository {
  final Dio _dio;

  LeaveRepository(this._dio);

  Future<void> requestLeave({
    required int employeeId,
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      await _dio.post('/leave/request', data: {
        'employee_id': employeeId,
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeaveModel>> getHistory(int employeeId) async {
    try {
      final response = await _dio.get('/leave/history/$employeeId');
      return (response.data as List).map((json) => LeaveModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeaveModel>> getPendingLeaves() async {
    try {
      final response = await _dio.get('/leave/pending');
      return (response.data as List).map((json) => LeaveModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatus({
    required int leaveId,
    required int approverId,
    required String status,
  }) async {
    try {
      await _dio.post('/leave/approve', data: {
        'leave_id': leaveId,
        'approver_id': approverId,
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
LeaveRepository leaveRepository(LeaveRepositoryRef ref) {
  return LeaveRepository(ref.watch(dioClientProvider));
}
