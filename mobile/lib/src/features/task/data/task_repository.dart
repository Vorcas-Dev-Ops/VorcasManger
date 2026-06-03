import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/task_model.dart';

part 'task_repository.g.dart';

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<List<TaskModel>> getTasksForEmployee(int employeeId) async {
    try {
      final response = await _dio.get('/task/assigned/$employeeId');
      final List data = response.data;
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      await _dio.post('/task/create', data: taskData);
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
