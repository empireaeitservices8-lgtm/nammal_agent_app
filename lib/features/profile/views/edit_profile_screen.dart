import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../../home/views/home_screen.dart';
import '../../wallet/views/wallet_screen.dart';
import '../models/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _bioController;

  String _selectedIdType = 'Aadhaar Card (UIDAI Direct)';
  int _calculatedAge = 0;
  String? _pickedImagePath;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final profileState = ref.read(profileViewModelProvider);
    final authState = ref.read(authViewModelProvider);
    final storage = ref.read(storageServiceProvider);

    final user = authState.user;
    final profile = profileState.profile;

    // Dynamically resolve values from user, profile, or storage without hardcoding
    final initialName =
        profile?.name.isNotEmpty == true && profile!.name != 'Agent'
        ? profile.name
        : (user?.name?.isNotEmpty == true
              ? user!.name!
              : (storage.getUserName() ?? ''));

    final initialDob = user?.dateOfBirth?.isNotEmpty == true
        ? user!.dateOfBirth!
        : (profile?.dateOfBirth?.isNotEmpty == true
              ? profile!.dateOfBirth!
              : (storage.getDob() ?? ''));

    final initialIdType = user?.idType?.isNotEmpty == true
        ? user!.idType!
        : (profile?.idType?.isNotEmpty == true
              ? profile!.idType!
              : (storage.getIdType() ?? 'Aadhaar Card (UIDAI Direct)'));

    final initialIdNumber = user?.idNumber?.isNotEmpty == true
        ? user!.idNumber!
        : (profile?.idNumber?.isNotEmpty == true
              ? profile!.idNumber!
              : (storage.getIdNumber() ?? ''));

    final initialBio = user?.bio?.isNotEmpty == true
        ? user!.bio!
        : (profile?.bio?.isNotEmpty == true
              ? profile!.bio!
              : (storage.getBio() ?? ''));

    _nameController = TextEditingController(text: initialName);
    _dobController = TextEditingController(text: initialDob);
    _idNumberController = TextEditingController(text: initialIdNumber);
    _bioController = TextEditingController(text: initialBio);
    _selectedIdType = initialIdType;

    if (user?.age != null && user!.age! > 0) {
      _calculatedAge = user.age!;
    }

    if (initialDob.isNotEmpty) {
      _calculateAgeFromDob(initialDob);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _calculateAgeFromDob(String dobString) {
    try {
      final clean = dobString.replaceAll(' ', '').trim();
      DateTime? parsed;
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          parsed = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } else if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            parsed = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            parsed = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      }

      if (parsed != null) {
        final now = DateTime.now();
        int age = now.year - parsed.year;
        if (now.month < parsed.month ||
            (now.month == parsed.month && now.day < parsed.day)) {
          age--;
        }
        if (age > 0 && age < 120) {
          setState(() {
            _calculatedAge = age;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate = DateTime(1996, 8, 14);
    if (_dobController.text.isNotEmpty) {
      try {
        final clean = _dobController.text.replaceAll(' ', '');
        final parts = clean.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = DateFormat('dd / MM / yyyy').format(picked);
      _dobController.text = formatted;
      _calculateAgeFromDob(formatted);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newName = _nameController.text.trim();
    final newDob = _dobController.text.trim();
    final newBio = _bioController.text.trim();
    final newIdType = _selectedIdType;
    final newIdNumber = _idNumberController.text.trim();
    final newAge = _calculatedAge > 0 ? _calculatedAge : null;
    final currentUser = ref.read(authViewModelProvider).user;

    final response = await ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(
          name: newName,
          gender: currentUser?.gender,
          bio: newBio,
          dob: newDob,
          age: newAge,
          idType: newIdType,
          idNumber: newIdNumber,
          avatarPath: _pickedImagePath,
        );

    if (response != null) {
      UserModel? updatedUser;
      if (response['user'] is Map<String, dynamic>) {
        updatedUser = UserModel.fromJson(
          response['user'] as Map<String, dynamic>,
        );
      } else if (response['profile'] is Map<String, dynamic>) {
        updatedUser = UserModel.fromJson(response);
      }

      final finalUser = (updatedUser ?? currentUser)?.copyWith(
        name: response['name']?.toString() ?? newName,
        bio: newBio,
        dateOfBirth: response['dob']?.toString() ?? newDob,
        age: (response['age'] as num?)?.toInt() ?? newAge,
        idType: newIdType,
        idNumber: response['id_proof_number']?.toString() ?? newIdNumber,
        avatar: _pickedImagePath ?? currentUser?.avatar,
      );

      if (finalUser != null) {
        ref.read(authViewModelProvider.notifier).state = ref
            .read(authViewModelProvider)
            .copyWith(user: finalUser);
      }

      // Refresh Home dashboard state so home screen reflects updated profile immediately
      ref.read(homeViewModelProvider.notifier).fetchHomeData();
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (response != null) {
        final serverMessage = response['message']?.toString() ??
            'Agent profile updated successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serverMessage),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        final error =
            ref.read(profileViewModelProvider).errorMessage ??
            'Failed to update profile. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final storage = ref.watch(storageServiceProvider);

    final user = authState.user;
    final profile = profileState.profile;

    // Dynamic agent ID
    final rawUserId = user?.id.isNotEmpty == true
        ? user!.id
        : (profile?.id.isNotEmpty == true
              ? profile!.id
              : (storage.getUserId() ?? '88492'));
    final formattedAgentId = 'ID #NAM-${rawUserId.padLeft(5, '0')}';

    // Dynamic phone
    final rawPhone = user?.phoneNumber?.isNotEmpty == true
        ? user!.phoneNumber!
        : (profile?.phoneNumber?.isNotEmpty == true
              ? profile!.phoneNumber!
              : (storage.getPhone() ?? '98765 43210'));

    final displayPhone = rawPhone.startsWith('+91')
        ? rawPhone
        : '+91 ${rawPhone.length == 10 ? '${rawPhone.substring(0, 5)} ${rawPhone.substring(5)}' : rawPhone}';

    // Dynamic tier / fulfillment rate
    final successRate =
        profile?.agent.successRate != null && profile!.agent.successRate > 0
        ? '${profile.agent.successRate.toStringAsFixed(1)}%'
        : '99.4%';

    final callsCompleted = profile?.agent.callsCompleted ?? 0;
    final level = callsCompleted >= 100
        ? 'Level 3'
        : (callsCompleted >= 50 ? 'Level 2' : 'Level 1');

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Sub-header Row: Back button & ID pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE8FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 13,
                                    color: Color(0xFF5B1FE2),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B1FE2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE8FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF5B1FE2),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedAgentId,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF5B1FE2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Profile Photo & Change Button
                      _buildPhotoSection(user?.avatar ?? profile?.avatar),

                      const SizedBox(height: 22),

                      // Agent Prime Partner / Level Card
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          final displayName = value.text.trim().isNotEmpty
                              ? value.text.trim()
                              : (user?.name?.isNotEmpty == true
                                    ? user!.name!
                                    : (profile?.name.isNotEmpty == true
                                          ? profile!.name
                                          : 'Agent'));
                          return _buildPartnerLevelCard(
                            name: displayName,
                            level: level,
                            fulfillment: successRate,
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                      // Section 1: Legal Identity
                      _buildLegalIdentityCard(),

                      const SizedBox(height: 20),

                      // Section 2: Contact & Fleet Info
                      _buildContactFleetCard(displayPhone),

                      const SizedBox(height: 26),

                      // Save Changes Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B1FE2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEDE8FF),
                            foregroundColor: const Color(0xFF5B1FE2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B1FE2),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFF5B1FE2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String? avatarUrl) {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEDE8FF), width: 3),
                ),
                child: ClipOval(
                  child: _pickedImagePath != null
                      ? Image.file(File(_pickedImagePath!), fit: BoxFit.cover)
                      : (avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar()),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _showImagePickerOptions,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B1FE2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showImagePickerOptions,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFF5B1FE2),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tap to Change Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B1FE2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'JPG or PNG up to 5 MB',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFEDE8FF),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Color(0xFF5B1FE2), size: 52),
      ),
    );
  }

  Widget _buildPartnerLevelCard({
    required String name,
    required String level,
    required String fulfillment,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF5B1FE2),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B1FE2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Nammal Prime Partner • $fulfillment Fulfillment',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF3EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF5B1FE2),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 18,
                  color: Color(0xFF5B1FE2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Legal Identity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Full Legal Name
          _buildFieldLabel('Full Legal Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              hint: '',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please enter full legal name'
                : null,
          ),

          const SizedBox(height: 16),

          // DOB & Age
          Row(
            children: [
              // Date of Birth
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Date of Birth'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7FD),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _dobController,
                                builder: (context, val, _) {
                                  return Text(
                                    val.text.isNotEmpty
                                        ? val.text
                                        : 'Select Date of Birth',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: val.text.isNotEmpty
                                          ? AppColors.textPrimary
                                          : AppColors.textPlaceholder,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Age Box
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Age',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF5B1FE2)
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _calculatedAge > 0 ? '$_calculatedAge yrs' : '-- yrs',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5B1FE2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Identity Document Type
          _buildFieldLabel('Identity Document Type'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedIdType,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items:
                    [
                      'Aadhaar Card (UIDAI Direct)',
                      'PAN Card',
                      'Voter ID Card',
                      'Driving License',
                      'Passport',
                    ].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(type)),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedIdType = val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Aadhaar / ID Number
          _buildFieldLabel('Aadhaar / ID Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _idNumberController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              hint: '•••• •••• 2345',
              prefixIcon: Icons.credit_card_outlined,
              suffixWidget: Container(
                margin: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFF5B1FE2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Verification notice box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: Color(0xFF5B1FE2),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Identity details verified via UIDAI. Contact ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A4E69),
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: 'Dispatch Desk',
                          style: TextStyle(
                            color: Color(0xFF5B1FE2),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' to change government ID.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFleetCard(String displayPhone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_phone_outlined,
                  size: 18,
                  color: Color(0xFF5B1FE2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Contact & Fleet Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Registered Mobile Number
          Row(
            children: const [
              Text(
                'Registered Mobile Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                'Primary OTP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B1FE2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF5B1FE2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bio / Fleet Operational Status
          Row(
            children: [
              const Text(
                'Bio / Fleet Operational Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _bioController,
                builder: (context, value, _) {
                  return Text(
                    '${value.text.length}/150',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bioController,
            maxLength: 150,
            maxLines: 3,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter bio or operational status...',
              hintStyle: const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F7FD),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF5B1FE2),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textPlaceholder,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F7FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
      suffixIcon: suffixWidget,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF5B1FE2), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
