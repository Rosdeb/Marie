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
import '../widgets/offices_field.dart';

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
  late TextEditingController _companyController;
  late TextEditingController _cityController;
  String? _selectedImagePath;

  /// Chosen from menus, never typed (point 1.4).
  String? _profession;
  String? _country;

  /// The offices the person works on, by code.
  List<String> _worksOnOffices = const [];

  /// The functions a reader can hold. A fixed list, as section 4.3 requires:
  /// "The profile fields are a fixed list chosen from menus, never free
  /// text." This is the job title, and is separate from the Paralegal /
  /// Attorney profile, which decides which questions are served.
  static const List<String> _functions = [
    'Paralegal',
    'Patent attorney',
    'Trade mark attorney',
    'Lawyer',
    'Trainee',
    'In-house counsel',
    'Patent engineer',
    'Formalities officer',
    'Student',
    'Other',
  ];

  /// The countries of the fifteen offices, then the rest of Europe and the
  /// larger markets. "Other" keeps the list from excluding anyone.
  static const List<String> _countries = [
    'Switzerland',
    'Germany',
    'France',
    'United Kingdom',
    'Italy',
    'Spain',
    'Netherlands',
    'Belgium',
    'Austria',
    'Sweden',
    'Denmark',
    'Finland',
    'Norway',
    'Poland',
    'Portugal',
    'Ireland',
    'United States',
    'Canada',
    'Japan',
    'South Korea',
    'China',
    'India',
    'Australia',
    'Brazil',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(accountProvider);
    _nameController = TextEditingController(text: profile.name);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _companyController = TextEditingController(text: profile.company);
    _cityController = TextEditingController(text: profile.city);
    _profession = profile.profession.isNotEmpty ? profile.profession : null;
    _country = profile.country.isNotEmpty ? profile.country : null;
    _worksOnOffices = List<String>.from(profile.worksOnOffices);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _cityController.dispose();
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
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final company = _companyController.text.trim();
    final city = _cityController.text.trim();

    if (firstName.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your first name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      FloatingErrorBar.show(context, message: 'Please enter a valid email address');
      return;
    }

    // The one name the server stores as a single column, built from the two
    // fields the reader filled in rather than asked for a third time.
    final name = [firstName, lastName].where((p) => p.isNotEmpty).join(' ');

    final success = await ref.read(accountProvider.notifier).updateProfile(
          name: name,
          firstName: firstName.isNotEmpty ? firstName : null,
          lastName: lastName.isNotEmpty ? lastName : null,
          email: email,
          // Still sent, and always empty: the server keeps the column, and
          // leaving it out would preserve whatever was typed before point
          // 1.4 removed the fields.
          phone: '',
          bio: '',
          profession: _profession,
          company: company,
          city: city,
          country: _country,
          worksOnOffices: _worksOnOffices,
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
        if (_companyController.text.isEmpty) _companyController.text = next.company;
        if (_cityController.text.isEmpty) _cityController.text = next.city;
        _profession ??= next.profession.isNotEmpty ? next.profession : null;
        _country ??= next.country.isNotEmpty ? next.country : null;
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

              // Asked once. The full name is composed from these two on
              // save; there is no separate "Full Name" field any more.
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      hint: 'First name',
                      controller: _firstNameController,
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
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
              // Point 1.4: "The function, the country and the offices the
              // person works on are chosen from lists ... No free-text bio,
              // no telephone number." The function and the country are
              // therefore menus, and the bio and the phone number are gone.
              _PickerField(
                label: 'Job title',
                hint: 'Choose your job title',
                icon: Icons.work_outline,
                value: _profession,
                options: _functions,
                onChanged: (v) => setState(() => _profession = v),
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
              // Typed, and optional - both may be left empty.
              CustomTextField(
                label: 'Company (optional)',
                hint: 'Your firm or company',
                controller: _companyController,
                prefixIcon: const Icon(Icons.business_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'City (optional)',
                hint: 'Your city',
                controller: _cityController,
                prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Country',
                hint: 'Choose your country',
                icon: Icons.public_outlined,
                value: _country,
                options: _countries,
                onChanged: (v) => setState(() => _country = v),
              ),
              const SizedBox(height: 12),

              // "the offices I work on chosen from a list" (Marie, Part 2,
              // Profile, point 3). Several, because most people work on more
              // than one, and chosen from the catalogue rather than typed.
              OfficesField(
                selected: _worksOnOffices,
                onChanged: (codes) => setState(() => _worksOnOffices = codes),
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

/// A profile field chosen from a fixed list.
///
/// Section 4.3: "The profile fields are a fixed list chosen from menus, never
/// free text." Styled to sit beside CustomTextField so the form reads as one.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // A value the list does not hold - something typed before this became a
    // menu - would make DropdownButton throw, so it is offered as its own
    // entry rather than silently dropped.
    final items = <String>[
      if (value != null && value!.isNotEmpty && !options.contains(value))
        value!,
      ...options,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              items: items
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
