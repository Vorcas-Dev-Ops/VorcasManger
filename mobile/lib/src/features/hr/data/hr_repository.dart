import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'hr_repository.g.dart';

class HrRepository {
  final Dio _dio;

  HrRepository(this._dio);

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _dio.get('/analytics/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getWorkforceStats() async {
    final response = await _dio.get('/analytics/workforce');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final response = await _dio.get('/employee/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

}

@riverpod
HrRepository hrRepository(Ref ref) {
  return HrRepository(ref.watch(dioClientProvider));
}
