import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import '../../auth/presentation/auth_notifier.dart';

part 'task_notifier.g.dart';

@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  Future<List<TaskModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(taskRepositoryProvider).getTasksForEmployee(user.employeeId);
  }

  Future<void> refreshTasks() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(taskRepositoryProvider).getTasksForEmployee(user.employeeId));
  }

  Future<void> updateStatus(int taskId, String status) async {
    await ref.read(taskRepositoryProvider).updateTaskStatus(taskId, status);
    await refreshTasks();
  }
}
