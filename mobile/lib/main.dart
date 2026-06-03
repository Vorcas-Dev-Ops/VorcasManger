import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/dashboard/presentation/dashboard_screen.dart';
import 'src/features/super_admin/presentation/super_admin_main_screen.dart';
import 'src/features/admin/presentation/admin_main_screen.dart';
import 'src/features/hr/presentation/hr_main_screen.dart';
import 'src/features/team_lead/presentation/team_lead_main_screen.dart';
import 'src/features/employee/presentation/emp_main_screen.dart';
import 'src/features/auth/presentation/auth_notifier.dart';
import 'src/features/auth/presentation/reset_password_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'src/core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Google Sign-In for version 7.x+
  await GoogleSignIn.instance.initialize(
    serverClientId: '435932889376-s5q2vsicnaef7cnaccu5jjj7v836rm6p.apps.googleusercontent.com',
  );

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          // Initialize our local notification service
          ref.read(notificationServiceProvider).setupNotifications();
          return const VorcasManagerApp();
        },
      ),
    ),
  );
}

class VorcasManagerApp extends ConsumerWidget {
  const VorcasManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      key: ValueKey(authState.valueOrNull == null),
      title: 'Vorcas Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.maybeWhen(
        data: (user) {
          if (user == null) return const LoginScreen();
          if (user.mustChangePassword == true) return const ResetPasswordScreen();

          final role = user.roleName?.toUpperCase();
          if (role == 'SUPER_ADMIN') return const SuperAdminMainScreen();
          if (role == 'ADMIN') return const AdminMainScreen();
          if (role == 'HR') return const HrMainScreen();
          if (role == 'TEAM_LEAD') return const TeamLeadMainScreen();
          if (role == 'EMPLOYEE') return const EmpMainScreen();
          return const DashboardScreen();
        },
        // Keep LoginScreen mounted during loading and error so it can update itself
        orElse: () => const LoginScreen(),
      ),
    );
  }
}
