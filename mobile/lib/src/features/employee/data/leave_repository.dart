import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'leave_repository.g.dart';

class LeaveRepository {
  final Dio _dio;

  LeaveRepository(this._dio);

  Future<void> requestLeave(Map<String, dynamic> leaveData) async {
    try {
      await _dio.post('/leave/request', data: leaveData);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveHistory(int employeeId) async {
    try {
      final response = await _dio.get('/leave/history/$employeeId');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveBalances(int employeeId) async {
    try {
      final response = await _dio.get('/leave/balances/$employeeId');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
LeaveRepository leaveRepository(LeaveRepositoryRef ref) {
  return LeaveRepository(ref.watch(dioClientProvider));
}
