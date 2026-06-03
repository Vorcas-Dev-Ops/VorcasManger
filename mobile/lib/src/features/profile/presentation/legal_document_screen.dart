import 'package:flutter/material.dart';
import '../../../core/theme/super_admin_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: SuperAdminTheme.backgroundBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          content,
          style: const TextStyle(
            color: SuperAdminTheme.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
