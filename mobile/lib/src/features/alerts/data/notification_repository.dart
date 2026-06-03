import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../domain/notification_model.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<NotificationModel>> getNotifications(int userId) async {
    try {
      final response = await _dio.get('/notifications/$userId');
      return (response.data as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.post('/notifications/read/$notificationId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      await _dio.post('/notifications/read-all/$userId');
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<NotificationModel>> notifications(NotificationsRef ref, int userId) {
  return ref.watch(notificationRepositoryProvider).getNotifications(userId);
}
