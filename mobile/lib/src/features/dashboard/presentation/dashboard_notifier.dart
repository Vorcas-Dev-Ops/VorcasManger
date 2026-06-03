import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';

part 'dashboard_notifier.g.dart';

@riverpod
class DashboardStats extends _$DashboardStats {
  @override
  Future<Map<String, dynamic>> build() async {
    final response = await ref.read(dioClientProvider).get('/analytics/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(dioClientProvider).get('/analytics/summary');
      return response.data as Map<String, dynamic>;
    });
  }
}
