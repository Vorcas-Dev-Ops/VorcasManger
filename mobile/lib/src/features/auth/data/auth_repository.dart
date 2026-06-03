import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/storage_service.dart';
import '../domain/user_model.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final userData = response.data['user'];

      await _storage.saveToken(token);
      await _storage.saveUserData(json.encode(userData));
      
      return UserModel.fromJson(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await _dio.get('/auth/roles');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> googleLogin(String idToken) async {
    try {
      final response = await _dio.post('/auth/google-login', data: {
        'idToken': idToken,
      });

      final token = response.data['token'];
      final userData = response.data['user'];

      await _storage.saveToken(token);
      await _storage.saveUserData(json.encode(userData));
      
      return UserModel.fromJson(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.post('/auth/update-fcm-token', data: {
        'fcmToken': fcmToken,
      });
    } catch (e) {
      print('AuthRepository UpdateFcmToken Error: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      final userData = response.data;
      // Merge/Save locally if needed
      return UserModel.fromJson(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/auth/profile', data: data);
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(storageServiceProvider),
  );
}

@riverpod
Future<List<Map<String, dynamic>>> roles(RolesRef ref) {
  return ref.watch(authRepositoryProvider).getRoles();
}
