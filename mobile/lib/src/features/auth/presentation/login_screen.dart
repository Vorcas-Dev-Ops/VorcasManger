import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../super_admin/presentation/super_admin_main_screen.dart';
import '../../admin/presentation/admin_main_screen.dart';

import '../../hr/presentation/hr_main_screen.dart';
import '../../team_lead/presentation/team_lead_main_screen.dart';
import '../../employee/presentation/emp_main_screen.dart';
import 'auth_notifier.dart';
import '../domain/user_model.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // SUCCESS: main.dart sees AsyncData(user) and navigates automatically.
    } catch (e) {
      debugPrint('LOGIN_DEBUG_ERROR: $e');
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        String message;
        if (errStr.contains('connection') || errStr.contains('socket') || errStr.contains('network') || errStr.contains('timeout') || errStr.contains('refused')) {
          message = 'Cannot connect to server. Please check your network.';
        } else if (errStr.contains('401') || errStr.contains('invalid credentials') || errStr.contains('invalid email') || errStr.contains('not found')) {
          message = 'Invalid email or password.';
          _passwordController.clear();
        } else {
          message = 'Login failed: ${e.toString().split('\n').first}';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your workspace',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (false) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.cardBackground)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppTheme.cardBackground)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });

                    try {
                      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
                      
                      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
                      final idToken = googleAuth.idToken;

                      if (idToken != null) {
                        await ref.read(authNotifierProvider.notifier).loginWithGoogle(idToken);
                        
                        // State change in authNotifier will trigger navigation automatically via main.dart
                      } else {
                        setState(() {
                          _errorMessage = 'Failed to get Google ID Token.';
                        });
                      }
                                        } catch (e) {
                      setState(() {
                        _errorMessage = 'Google Sign-In Failed: $e';
                      });
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                  label: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cardBackground),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New to Vorcas? "),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Contact HR',
                      style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
