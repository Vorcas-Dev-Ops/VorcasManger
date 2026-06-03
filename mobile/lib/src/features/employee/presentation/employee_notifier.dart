import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/employee_repository.dart';
import '../domain/employee_model.dart';

part 'employee_notifier.g.dart';

@riverpod
class EmployeeNotifier extends _$EmployeeNotifier {
  @override
  Future<List<EmployeeModel>> build() async {
    return ref.read(employeeRepositoryProvider).getEmployees();
  }

  Future<void> refreshEmployees() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(employeeRepositoryProvider).getEmployees());
  }
}
