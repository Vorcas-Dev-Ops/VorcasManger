import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/leave_repository.dart';
import '../domain/leave_model.dart';
import '../../auth/presentation/auth_notifier.dart';

part 'leave_notifier.g.dart';

@riverpod
class LeaveNotifier extends _$LeaveNotifier {
  @override
  Future<List<LeaveModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(leaveRepositoryProvider).getHistory(user.employeeId);
  }

  Future<void> submitRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(leaveRepositoryProvider).requestLeave(
            employeeId: user.employeeId,
            leaveType: leaveType,
            startDate: startDate.toIso8601String().split('T')[0],
            endDate: endDate.toIso8601String().split('T')[0],
            reason: reason,
          );
      
      state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getHistory(user.employeeId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshHistory() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getHistory(user.employeeId));
  }
}

@riverpod
class PendingLeaveNotifier extends _$PendingLeaveNotifier {
  @override
  Future<List<LeaveModel>> build() async {
    return ref.read(leaveRepositoryProvider).getPendingLeaves();
  }

  Future<void> approveLeave(int leaveId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(leaveRepositoryProvider).updateStatus(
            leaveId: leaveId,
            approverId: user.employeeId,
            status: 'APPROVED',
          );
      state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getPendingLeaves());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectLeave(int leaveId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(leaveRepositoryProvider).updateStatus(
            leaveId: leaveId,
            approverId: user.employeeId,
            status: 'REJECTED',
          );
      state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getPendingLeaves());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
