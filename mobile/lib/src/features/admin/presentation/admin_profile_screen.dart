import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/super_admin_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/common_widgets/common_avatar.dart';
import '../../profile/presentation/legal_document_screen.dart';
import '../../../core/constants/legal_texts.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _profilePictureUrl = user?.profilePictureUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      final String base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      setState(() {
        _profilePictureUrl = base64Image;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected. Please click Save to apply.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        profilePictureUrl: _profilePictureUrl,
      );
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: SuperAdminTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: SuperAdminTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditing)
            _isSaving 
              ? const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: SuperAdminTheme.primaryOrange))))
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('SAVE', style: TextStyle(color: SuperAdminTheme.primaryOrange, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: user == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                       CommonAvatar(
                         radius: 60,
                         imageUrl: _profilePictureUrl,
                         isSquare: true,
                         borderRadius: 20,
                       ),
                      if (_isEditing)
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SuperAdminTheme.primaryOrange, 
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isEditing) ...[
                  TextField(
                    controller: _firstNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: 'First Name', border: InputBorder.none),
                  ),
                  TextField(
                    controller: _lastNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: 'Last Name', border: InputBorder.none),
                  ),
                ] else
                  Text('${user.firstName} ${user.lastName}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 4),
                Text(user.roleName.toUpperCase(), style: const TextStyle(color: SuperAdminTheme.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!_isEditing && user != null) {
                      _firstNameController.text = user.firstName;
                      _lastNameController.text = user.lastName;
                      _phoneController.text = user.phone ?? '';
                    }
                    setState(() => _isEditing = !_isEditing);
                  },
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white, size: 16),
                  label: Text(_isEditing ? 'Cancel' : 'Edit Profile', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditing ? Colors.grey[800] : SuperAdminTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Basic Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.person, color: SuperAdminTheme.primaryOrange, size: 20),
                    SizedBox(width: 8),
                    Text('Basic Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileField(
                  label: 'PHONE NUMBER', 
                  value: user.phone ?? 'Not set', 
                  icon: Icons.phone,
                  isEditing: _isEditing,
                  controller: _phoneController,
                ),
                const SizedBox(height: 16),
                _ProfileField(
                  label: 'WORK EMAIL', 
                  value: user.email, 
                  icon: Icons.email,
                  isEditing: false, 
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Employment
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMPLOYMENT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _EmploymentRow(icon: Icons.badge, label: 'EMPLOYEE ID', value: 'EMP${user.employeeId.toString().padLeft(3, '0')}'),
                const SizedBox(height: 20),
                _EmploymentRow(icon: Icons.calendar_today, label: 'JOINED DATE', value: user.joinedDate ?? 'N/A'),
                const SizedBox(height: 20),
                _EmploymentRow(icon: Icons.group, label: 'DEPARTMENT', value: user.departmentName ?? 'Unassigned'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Legal & Security
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: SuperAdminTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEGAL & SECURITY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(title: 'Privacy Policy', content: LegalTexts.privacyPolicy)));
                  },
                  child: const _EmploymentRow(icon: Icons.privacy_tip, label: 'PRIVACY POLICY', value: 'View our privacy policy'),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentScreen(title: 'Terms & Conditions', content: LegalTexts.termsOfService)));
                  },
                  child: const _EmploymentRow(icon: Icons.description, label: 'TERMS & CONDITIONS', value: 'View terms of service'),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: SuperAdminTheme.surfaceCard,
                        title: const Text('Request Account Deletion', style: TextStyle(color: Colors.white)),
                        content: const Text('To delete your account, please contact the HR department.', style: TextStyle(color: SuperAdminTheme.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK', style: TextStyle(color: SuperAdminTheme.primaryOrange)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const _EmploymentRow(icon: Icons.delete_forever, label: 'ACCOUNT DELETION', value: 'Request account removal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isEditing;
  final TextEditingController? controller;

  const _ProfileField({
    required this.label, 
    required this.value, 
    required this.icon,
    this.isEditing = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: SuperAdminTheme.textSecondary, size: 18),
              const SizedBox(width: 16),
              Expanded(
                child: isEditing && controller != null
                  ? TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmploymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EmploymentRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: SuperAdminTheme.backgroundBlack, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: SuperAdminTheme.primaryOrange, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: SuperAdminTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
