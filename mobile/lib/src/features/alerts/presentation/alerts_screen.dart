import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final notificationsAsync = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      appBar: AppBar(
        title: const Text('Recent Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppTheme.primaryAccent),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Triggering local test notification...')),
              );
              // Register the token first
              ref.read(notificationServiceProvider).syncToken();
              
              // Now show a fake local notification to test the display logic
              // Since the method is private, I will add a public test method to the service
              ref.read(notificationServiceProvider).testLocalNotification();
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.primaryAccent),
            onPressed: () => ref.read(notificationRepositoryProvider).markAllAsRead(user.id).then((_) {
              ref.invalidate(notificationsProvider(user.id));
            }),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('No recent alerts', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider(user.id)),
            color: AppTheme.primaryAccent,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case 'TASK':
        icon = Icons.assignment;
        iconColor = Colors.blue;
        break;
      case 'MEETING':
        icon = Icons.meeting_room;
        iconColor = Colors.orange;
        break;
      case 'LEAVE':
        icon = Icons.event_note;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.primaryAccent;
    }

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead 
            ? BorderSide.none 
            : const BorderSide(color: AppTheme.primaryAccent, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead && user != null) {
            ref.read(notificationRepositoryProvider).markAsRead(notification.id).then((_) {
              ref.invalidate(notificationsProvider(user.id));
            });
          }
        },
      ),
    );
  }
}
