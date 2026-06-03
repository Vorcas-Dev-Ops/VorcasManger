import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_notifier.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../super_admin/presentation/super_admin_main_screen.dart';
import '../../admin/presentation/admin_main_screen.dart';
import '../../hr/presentation/hr_main_screen.dart';
import '../../team_lead/presentation/team_lead_main_screen.dart';
import '../../employee/presentation/emp_main_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "New passwords don't match.");
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = "New password must be at least 6 characters.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      // State change in authNotifier will trigger navigation automatically via main.dart
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update password. Check old password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        automaticallyImplyLeading: false, // Force them to change
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 64, color: AppTheme.primaryAccent),
              const SizedBox(height: 16),
              Text(
                'Security Requirement',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'For your security, you must change your password upon your first login.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(
                  hintText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: Icon(Icons.lock_open, color: AppTheme.textSecondary),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  hintText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock, color: AppTheme.textSecondary),
                ),
                obscureText: true,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.statusNegative),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   ref.read(authNotifierProvider.notifier).logout();
                },
                child: const Text('Cancel & Logout', style: TextStyle(color: AppTheme.statusNegative)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
