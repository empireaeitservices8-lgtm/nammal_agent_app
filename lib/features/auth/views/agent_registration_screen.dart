import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../models/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';

class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  ConsumerState<AgentRegistrationScreen> createState() =>
      _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState
    extends ConsumerState<AgentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(
    text: 'Rahul Sharma',
  );
  final TextEditingController _ageController = TextEditingController(
    text: '28 yrs',
  );
  final TextEditingController _dobController = TextEditingController(text: '');
  final TextEditingController _idNumberController = TextEditingController(
    text: '5432 8901 2345',
  );
  final TextEditingController _jurisdictionController = TextEditingController(
    text: 'Koramangala, Bengaluru',
  );

  String _selectedGender = 'Male';
  String _selectedIdType = 'Aadhaar Card (UIDAI Direct)';
  bool _isTermsAccepted = true;
  String? _selectedDocumentPath;
  String _documentSizeLabel = '2.4 MB';
  bool _isDocumentSelected = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authViewModelProvider);
    final existingUser = authState.user;
    if (existingUser?.name != null && existingUser!.name!.isNotEmpty) {
      _nameController.text = existingUser.name!;
    }
    if (existingUser?.gender != null && existingUser!.gender!.isNotEmpty) {
      final g = existingUser.gender!.toLowerCase();
      if (g == 'male') _selectedGender = 'Male';
      if (g == 'female') _selectedGender = 'Female';
    }
    if (existingUser?.age != null) {
      _ageController.text = '${existingUser!.age} yrs';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _jurisdictionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate = DateTime(1996, 8, 14);
    if (_dobController.text.isNotEmpty) {
      try {
        final parts = _dobController.text
            .split('/')
            .map((e) => int.parse(e.trim()))
            .toList();
        if (parts.length == 3) {
          initialDate = DateTime(parts[2], parts[1], parts[0]);
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

      final now = DateTime.now();
      int age = now.year - picked.year;
      if (now.month < picked.month ||
          (now.month == picked.month && now.day < picked.day)) {
        age--;
      }
      _ageController.text = '$age yrs';
      setState(() {});
    }
  }

  Future<void> _pickDocumentImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) {
        final length = await file.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _selectedDocumentPath = file.path;
          _documentSizeLabel = '$sizeMb MB';
          _isDocumentSelected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the KYC declaration terms to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authState = ref.read(authViewModelProvider);
    final phone = authState.phoneNumber ?? '9876543210';

    final success = await ref
        .read(authViewModelProvider.notifier)
        .registerAgent(
          name: _nameController.text.trim(),
          gender: _selectedGender,
          phoneNumber: phone,
          age: _ageController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          idType: _selectedIdType,
          idNumber: _idNumberController.text.trim(),
          jurisdiction: _jurisdictionController.text.trim(),
          idPhotoPath: _selectedDocumentPath,
        );

    if (mounted) {
      if (success) {
        final serverMessage = ref
            .read(authViewModelProvider)
            .registerResponse
            ?.message;
        final message = (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : 'Agent registration submitted! You can stay on the home page; calling will be enabled once admin approves your account.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go(AppRoutes.home);
      } else {
        final error =
            ref.read(authViewModelProvider).errorMessage ??
            'Registration failed. Please check your details.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final displayPhone = authState.phoneNumber?.isNotEmpty == true
        ? authState.phoneNumber!
        : '98765 43210';

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(),

            // Progress Bar
            const LinearProgressIndicator(
              value: 0.5,
              minHeight: 4,
              backgroundColor: Color(0xFFEDE8FF),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Personal Information Card
                      _buildPersonalInfoCard(displayPhone),

                      const SizedBox(height: 20),

                      // Section 2: Government Identity Proof Card
                      _buildGovernmentIdentityCard(),

                      const SizedBox(height: 20),

                      // Terms & Conditions Checkbox
                      _buildTermsCheckbox(),

                      const SizedBox(height: 24),

                      // Submit Registration Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Submit Registration',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Security Badge Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Secured with 256-bit government KYC compliance & UIDAI standards',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: const [
                Text(
                  'Agent Registration',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'STEP 1 OF 2: PERSONAL & KYC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Need assistance? Contact support@nammal.in'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Full Legal Name
          _buildFieldLabel('Full Legal Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              hint: 'Full legal name',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your full legal name';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'Must match exactly as printed on your government identity card.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 18),

          // Gender
          _buildFieldLabel('Gender'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  label: 'Male',
                  isSelected: _selectedGender.toLowerCase() == 'male',
                  onTap: () => setState(() => _selectedGender = 'Male'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(
                  label: 'Female',
                  isSelected: _selectedGender.toLowerCase() == 'female',
                  onTap: () => setState(() => _selectedGender = 'Female'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Registered Mobile Number
          Row(
            children: [
              _buildFieldLabel('Registered Mobile Number'),
              const Spacer(),
              Row(
                children: const [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Verified via OTP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Text(
                  '🇮🇳 +91',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    phone.startsWith('+91')
                        ? phone.substring(3).trim()
                        : (phone.length == 10
                              ? '${phone.substring(0, 5)} ${phone.substring(5)}'
                              : phone),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Age & Date of Birth
          Row(
            children: [
              // Age
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Age'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ageController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      decoration: _buildInputDecoration(hint: '28 yrs'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

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
                          color: Colors.white,
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
                              child: Text(
                                _dobController.text.isNotEmpty
                                    ? _dobController.text
                                    : 'DD/MM/YYYY',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dobController.text.isNotEmpty
                                      ? AppColors.textPrimary
                                      : AppColors.textPlaceholder,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.event_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGovernmentIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Government Identity Proof',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0ECFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 18,
                  color: Color(0xFF6B42FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Identity Document Type Dropdown
          _buildFieldLabel('Identity Document Type'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  fontSize: 15,
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
                              Icons.credit_card_outlined,
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

          const SizedBox(height: 18),

          // Aadhaar Number / ID Number
          _buildFieldLabel(
            _selectedIdType.contains('Aadhaar')
                ? 'Aadhaar Number'
                : 'Document Number',
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _idNumberController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
            decoration: _buildInputDecoration(
              hint: '5432 8901 2345',
              prefixIcon: Icons.payment_outlined,
              suffixWidget: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter document number';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Place of Issue / Jurisdiction
          _buildFieldLabel('Place of Issue / Jurisdiction'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _jurisdictionController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _buildInputDecoration(
              hint: 'Koramangala, Bengaluru',
              prefixIcon: Icons.location_on_outlined,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter place of issue';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Upload ID Photo / Document Copy
          Row(
            children: [
              _buildFieldLabel('Upload ID Photo / Document Copy'),
              const Spacer(),
              if (_isDocumentSelected)
                Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'File Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Document Upload Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9E3FF)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDocumentPath != null
                              ? _selectedDocumentPath!
                                    .split(Platform.pathSeparator)
                                    .last
                              : 'ID_Document_Front.jpg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _documentSizeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDocumentImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Retake Front'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE0D8FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickDocumentImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 16,
                        ),
                        label: const Text('Change File'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE0D8FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accepted: JPEG, PNG or PDF up to 5MB. Ensure corners and text are sharp.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

  Widget _buildGenderOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF9F8FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isTermsAccepted,
            onChanged: (val) {
              setState(() => _isTermsAccepted = val ?? false);
            },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _isTermsAccepted = !_isTermsAccepted);
            },
            child: const Text.rich(
              TextSpan(
                text: 'I declare that the personal details and identity documents submitted are valid, accurate, and authentic under the ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Nammal Partner Fleet Terms of Service',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and KYC regulatory mandate.'),
                ],
              ),
            ),
          ),
        ),
      ],
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
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
