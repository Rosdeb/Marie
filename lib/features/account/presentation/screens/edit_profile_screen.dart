import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../providers/account_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _professionController;
  late TextEditingController _bioController;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(accountProvider);
    _nameController = TextEditingController(text: profile.name);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _professionController = TextEditingController(text: profile.profession);
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  void _onSave() async {
    final name = _nameController.text.trim();
    String? firstName = _firstNameController.text.trim();
    String? lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final profession = _professionController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      FloatingErrorBar.show(context, message: 'Please enter a valid email address');
      return;
    }

    if (firstName.isEmpty && name.contains(' ')) {
      final parts = name.split(' ');
      firstName = parts.first;
      if (lastName.isEmpty && parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    final success = await ref.read(accountProvider.notifier).updateProfile(
          name: name,
          firstName: firstName.isNotEmpty ? firstName : null,
          lastName: lastName.isNotEmpty ? lastName : null,
          email: email,
          phone: phone,
          profession: profession.isNotEmpty ? profession : null,
          bio: bio,
          profileFilePath: _selectedImagePath,
        );

    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Profile updated successfully');
      context.pop();
    } else {
      final error = ref.read(accountProvider).errorMessage ?? 'Failed to update profile';
      FloatingErrorBar.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(accountProvider);

    ref.listen<ProfileState>(accountProvider, (prev, next) {
      if ((prev == null || prev.name.isEmpty) && next.name.isNotEmpty) {
        if (_nameController.text.isEmpty) _nameController.text = next.name;
        if (_firstNameController.text.isEmpty) _firstNameController.text = next.firstName;
        if (_lastNameController.text.isEmpty) _lastNameController.text = next.lastName;
        if (_emailController.text.isEmpty) _emailController.text = next.email;
        if (_phoneController.text.isEmpty) _phoneController.text = next.phone;
        if (_professionController.text.isEmpty) _professionController.text = next.profession;
        if (_bioController.text.isEmpty) _bioController.text = next.bio;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Manage Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Avatar with Edit overlay
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      AppAvatar(
                        radius: 50,
                        imageUrl: profile.avatarUrl,
                        localFilePath: _selectedImagePath,
                        name: profile.name,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      hint: 'First name',
                      controller: _firstNameController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      hint: 'Last name',
                      controller: _lastNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Profession',
                hint: 'e.g. Patent Attorney, Paralegal',
                controller: _professionController,
                prefixIcon: const Icon(Icons.work_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Bio / Study Goal',
                hint: 'Tell us about your study focus',
                controller: _bioController,
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Save Changes',
                isLoading: profile.isLoading,
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
