import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<List<Map<String, dynamic>>> getAssignedTasks(int employeeId) async {
    try {
      final response = await _dio.get('/task/assigned/$employeeId');
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    try {
      await _dio.post('/task/update-status', data: {
        'id': taskId,
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  return TaskRepository(ref.watch(dioClientProvider));
}
