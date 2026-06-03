import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otpSent ? 'Check your email' : 'Forgot Password?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent 
                ? 'We have sent a 6-digit OTP to your email address. Please enter it below.' 
                : 'Enter your email address associated with your account to receive a reset OTP.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            if (!_otpSent) ...[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => setState(() => _otpSent = true),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppTheme.primaryAccent),
                child: const Text('SEND OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _OtpBox()),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppTheme.primaryAccent),
                child: const Text('VERIFY & RESET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
      ),
      child: const Center(child: TextField(textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: InputDecoration(border: InputBorder.none))),
    );
  }
}
