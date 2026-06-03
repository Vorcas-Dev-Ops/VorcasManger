import 'package:flutter/material.dart';
import '../../../core/theme/super_admin_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SuperAdminTheme.darkTheme,
      child: Scaffold(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('OPERATIONAL RECORDS', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 100, color: SuperAdminTheme.surfaceLighter),
              const SizedBox(height: 24),
              const Text('Management Schedule', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 8),
                child: Text(
                  'Team Lead shift management and operational scheduling will be finalized in the next release.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SuperAdminTheme.primaryOrange,
                  side: const BorderSide(color: SuperAdminTheme.primaryOrange),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RETURN TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
