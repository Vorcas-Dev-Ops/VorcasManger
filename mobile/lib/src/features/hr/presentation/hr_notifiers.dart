import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/hr_repository.dart';

part 'hr_notifiers.g.dart';

@riverpod
Future<Map<String, dynamic>> hrDashboardSummary(HrDashboardSummaryRef ref) async {
  return ref.watch(hrRepositoryProvider).getDashboardSummary();
}

@riverpod
Future<List<Map<String, dynamic>>> hrWorkforceStats(HrWorkforceStatsRef ref) async {
  return ref.watch(hrRepositoryProvider).getWorkforceStats();
}

@riverpod
Future<List<Map<String, dynamic>>> hrStaffList(HrStaffListRef ref) async {
  return ref.watch(hrRepositoryProvider).getAllEmployees();
}

