import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService(this._ref);

  Future<void> setupNotifications() async {
    if (_initialized) return;

    // 1. Request Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permissions');
    } else {
      print('User declined or has not yet granted notification permissions');
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 4. Start listening for auth changes to register token
    _ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          syncToken();
        }
      });
    });

    // Also try initial sync if already logged in
    syncToken();

    _fcm.onTokenRefresh.listen(_registerToken);
    
    _initialized = true;
  }

  Future<void> syncToken() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    final user = _ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      try {
        print('Registering FCM Token for user ${user.id}: $token');
        final repository = _ref.read(authRepositoryProvider);
        await repository.updateFcmToken(token);
      } catch (e) {
        print('Error registering FCM token: $e');
      }
    }
  }

  Future<void> testLocalNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vorcas_alerts',
      'Vorcas Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      id: 999,
      title: 'Local Test Success!',
      body: 'Notifications are configured correctly on this device.',
      notificationDetails: platformDetails,
    );
  }

  Future<void> showWarningNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vorcas_alerts',
      'Vorcas Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      id: 888, // Use a specific ID for warnings so they overwrite each other
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vorcas_alerts',
      'Vorcas Alerts',
      channelDescription: 'Notifications for tasks, meetings, and leaves',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Alert',
      body: message.notification?.body ?? '',
      notificationDetails: platformDetails,
    );
  }
}

// Background Message Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling dynamic background message: ${message.messageId}');
}
