import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/tl_repository.dart';

part 'tl_notifiers.g.dart';

@riverpod
Future<Map<String, dynamic>> tlDashboardStats(TlDashboardStatsRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return await ref.read(tlRepositoryProvider).getDashboardStats(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> tlSquad(TlSquadRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(tlRepositoryProvider).getSquad(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> tlTeamAttendance(TlTeamAttendanceRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(tlRepositoryProvider).getTeamAttendance(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> tlTeamTasks(TlTeamTasksRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(tlRepositoryProvider).getTeamTasks(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> tlSquadProgress(TlSquadProgressRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(tlRepositoryProvider).getSquadTaskProgress(user.employeeId);
}

@riverpod
Future<List<Map<String, dynamic>>> tlTeamLeaves(TlTeamLeavesRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return await ref.read(tlRepositoryProvider).getTeamLeaves(user.employeeId);
}
