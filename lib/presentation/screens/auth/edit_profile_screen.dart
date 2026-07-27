import 'dart:io';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/validators.dart';
import 'package:cashspark/core/widgets/custom_text_field.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _aboutCtrl;

  bool _isSaving = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _dobCtrl = TextEditingController(text: user?.dateOfBirth ?? '');
    _countryCtrl = TextEditingController(text: user?.country ?? '');
    _aboutCtrl = TextEditingController(text: user?.aboutMe ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _countryCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) setState(() => _profileImage = File(image.path));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        aboutMe: _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF4ADE80),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: ${e.toString().replaceAll('Exception: ', '')}'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.bgDark : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.15),
                          backgroundImage:
                              _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Text(
                                  (_nameCtrl.text.isNotEmpty
                                          ? _nameCtrl.text[0]
                                          : 'U')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentGreen,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppTheme.bgDark : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildField(
                'Full Name',
                _nameCtrl,
                Icons.person_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              _buildField('Email', _emailCtrl, Icons.email_outlined,
                  enabled: false,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Email cannot be changed',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number
              _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined,
                  isPhone: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final cleaned = v.replaceAll(RegExp(r'[\s-]'), '');
                    if (cleaned.length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  }),
              const SizedBox(height: 16),

              // Date of Birth
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: _buildField(
                    'Date of Birth',
                    _dobCtrl,
                    Icons.cake_outlined,
                    suffixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Country
              _buildField('Country', _countryCtrl, Icons.public_outlined),
              const SizedBox(height: 16),

              // About Me
              _buildField(
                'About Me',
                _aboutCtrl,
                Icons.info_outline,
                maxLines: 3,
                hint: 'Tell us about yourself',
              ),

              const SizedBox(height: 32),

              // Save
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isPhone = false,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return CustomTextField(
      controller: ctrl,
      labelText: label,
      hintText: hint ?? 'Enter $label',
      prefixIcon: icon,
      suffixIcon: suffixIcon,
      isPhone: isPhone,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
    );
  }
}
