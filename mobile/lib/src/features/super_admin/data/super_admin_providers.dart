import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'super_admin_repository.dart';

part 'super_admin_providers.g.dart';

@riverpod
Future<Map<String, dynamic>> superAdminDashboard(SuperAdminDashboardRef ref) {
  return ref.watch(superAdminRepositoryProvider).getSuperAdminDashboard();
}

@riverpod
Future<List<Map<String, dynamic>>> workforceDistribution(WorkforceDistributionRef ref) {
  return ref.watch(superAdminRepositoryProvider).getWorkforceDistribution();
}

@riverpod
Future<List<Map<String, dynamic>>> superAdminAttendanceStats(SuperAdminAttendanceStatsRef ref) {
  return ref.watch(superAdminRepositoryProvider).getAttendanceStats();
}

@riverpod
Future<Map<String, dynamic>> superAdminAttendanceOverview(SuperAdminAttendanceOverviewRef ref) {
  return ref.watch(superAdminRepositoryProvider).getAttendanceOverview();
}

@riverpod
Future<List<Map<String, dynamic>>> allEmployees(AllEmployeesRef ref) {
  return ref.watch(superAdminRepositoryProvider).getAllEmployees();
}

@riverpod
Future<List<Map<String, dynamic>>> superAdminPendingLeaves(SuperAdminPendingLeavesRef ref) {
  return ref.watch(superAdminRepositoryProvider).getPendingLeaves();
}

@riverpod
Future<List<Map<String, dynamic>>> superAdminAllTasks(SuperAdminAllTasksRef ref) {
  return ref.watch(superAdminRepositoryProvider).getAllTasks();
}

@riverpod
Future<Map<String, dynamic>> superAdminTaskOverview(SuperAdminTaskOverviewRef ref) {
  return ref.watch(superAdminRepositoryProvider).getTaskOverview();
}


@riverpod
Future<List<Map<String, dynamic>>> superAdminDepartments(SuperAdminDepartmentsRef ref) {
  return ref.watch(superAdminRepositoryProvider).getDepartments();
}
