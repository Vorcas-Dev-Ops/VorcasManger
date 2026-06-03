import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'storage_service.dart';
import '../../features/auth/presentation/auth_notifier.dart';

part 'api_client.g.dart';

@riverpod
Dio dioClient(DioClientRef ref) {
  final storage = ref.watch(storageServiceProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8081', // Special IP for Android Emulator to access localhost 10.0.2.2, 127.0.0.1(FOR USB use "adb reverse tcp:8081 tcp:8081")
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          ref.read(authNotifierProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
