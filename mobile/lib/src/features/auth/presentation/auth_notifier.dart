import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/notification_service.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserModel?> build() async {
    final storage = ref.read(storageServiceProvider);
    final userData = await storage.getUserData();
    if (userData != null) {
      try {
        return UserModel.fromJson(json.decode(userData));
      } catch (e) {
        // Handle potential parsing error by clearing invalid data
        await storage.clearAll();
        return null;
      }
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AsyncData(user);
    } catch (e) {
      // Reset to null state (not error) so main.dart keeps showing LoginScreen
      state = const AsyncData(null);
      // Rethrow so the LoginScreen's _login() catch block can show the error message
      rethrow;
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).googleLogin(idToken);
      // Sync FCM token after successful login
      ref.read(notificationServiceProvider).syncToken();
      return user;
    });
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await ref.read(authRepositoryProvider).changePassword(oldPassword, newPassword);
    
    // After successful password change, update state to say mustChangePassword is false
    if (state.value != null) {
      final updatedUser = state.value!.copyWith(mustChangePassword: false);
      state = AsyncData(updatedUser);
      // We also update local storage to match the new state
      final storage = ref.read(storageServiceProvider);
      await storage.saveUserData(json.encode(updatedUser.toJson()));
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return null;
    });
  }

  Future<void> fetchProfile() async {
    state = await AsyncValue.guard(() async {
      final updatedUser = await ref.read(authRepositoryProvider).getProfile();
      // Update local storage
      final storage = ref.read(storageServiceProvider);
      await storage.saveUserData(json.encode(updatedUser.toJson()));
      return updatedUser;
    });
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? profilePictureUrl,
  }) async {
    await ref.read(authRepositoryProvider).updateProfile({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
    });
    
    // Refresh local state
    await fetchProfile();
  }
}

@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
}
