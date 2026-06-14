import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/auth_service.dart';
import 'package:nightingale_heart/core/services/storage_service.dart';
import 'package:nightingale_heart/core/widgets/animated_gradient_bg.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// Five-step profile builder with PageView and progress bar.
///
/// Step 1: Personal info (photo, name, age, gender, looking for)
/// Step 2: Healthcare career (job, workplace, department, years)
/// Step 3: Schedule (shift type, location, timezone)
/// Step 4: Interests (selectable chips, 3-10)
/// Step 5: Languages + bio
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 1 fields ──
  File? _profileImage;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedLookingFor;

  // ── Step 2 fields ──
  String? _selectedJobTitle;
  bool _showProfessionBadge = true;
  final _workplaceController = TextEditingController();
  String? _selectedDepartment;
  double _yearsExperience = 0;

  // ── Step 3 fields ──
  String? _selectedShiftType;
  final _locationController = TextEditingController();
  String _selectedTimezone = _guessTimezone();

  // ── Step 4 fields ──
  final Set<String> _selectedInterests = {};

  // ── Step 5 fields ──
  final Set<String> _selectedLanguages = {};
  final _bioController = TextEditingController();

  // ── Constants ──
  static const List<String> _jobTitles = [
    // ── Nursing ──
    'Registered Nurse (RN)',
    'Nurse Practitioner (NP)',
    'Licensed Practical Nurse (LPN)',
    'Licensed Vocational Nurse (LVN)',
    'Certified Nursing Assistant (CNA)',
    'Nurse Anesthetist (CRNA)',
    'Clinical Nurse Specialist',
    'Charge Nurse',
    'Nurse Manager',
    'Travel Nurse',
    'Home Health Nurse',
    'School Nurse',
    'Midwife / Nurse-Midwife',
    // ── Physicians / Doctors ──
    'Physician / Doctor (MD/DO)',
    'Surgeon',
    'Anesthesiologist',
    'Cardiologist',
    'Dermatologist',
    'Emergency Medicine Physician',
    'Endocrinologist',
    'Family Medicine Physician',
    'Gastroenterologist',
    'Hospitalist',
    'Internal Medicine Physician',
    'Nephrologist',
    'Neurologist',
    'Obstetrician / Gynecologist',
    'Oncologist',
    'Ophthalmologist',
    'Orthopedic Surgeon',
    'Pathologist',
    'Pediatrician',
    'Psychiatrist',
    'Pulmonologist',
    'Radiologist',
    'Urologist',
    // ── Mid-Level Providers ──
    'Physician Assistant (PA)',
    'Dentist',
    // ── Therapists ──
    'Physical Therapist',
    'Occupational Therapist',
    'Respiratory Therapist',
    'Speech-Language Pathologist',
    'Recreational Therapist',
    // ── Pharmacy ──
    'Pharmacist',
    'Pharmacy Technician',
    // ── Technicians & Technologists ──
    'Lab Technician / Technologist',
    'Surgical Technician',
    'Radiology Technician',
    'MRI Technologist',
    'Ultrasound Technician',
    'Phlebotomist',
    'EKG / ECG Technician',
    'Sterile Processing Technician',
    'Dialysis Technician',
    // ── Emergency Services ──
    'Paramedic',
    'EMT',
    // ── Allied Health & Support ──
    'Medical Assistant',
    'Dietitian / Nutritionist',
    'Social Worker',
    'Patient Care Coordinator',
    'Health Information Technician',
    'Medical Records Clerk',
    'Unit Secretary / Ward Clerk',
    'Patient Transporter',
    'Hospital Administrator',
    'Biomedical Engineer',
    'Environmental Services',
    'Other',
  ];

  static const List<String> _departments = [
    'Emergency / ER',
    'ICU / Critical Care',
    'NICU (Neonatal)',
    'PICU (Pediatric ICU)',
    'Surgery / Operating Room',
    'Post-Anesthesia Care (PACU)',
    'Pediatrics',
    'Oncology / Cancer Center',
    'Cardiology / Heart Center',
    'Cardiac Catheterization Lab',
    'Mental Health / Psychiatry',
    'General Ward / Med-Surg',
    'Outpatient / Ambulatory',
    'Labor & Delivery / OB',
    'Postpartum / Mother-Baby',
    'Neurology / Neuro ICU',
    'Orthopedics',
    'Dermatology',
    'Radiology / Imaging',
    'Pharmacy',
    'Rehabilitation / Physical Therapy',
    'Respiratory Care',
    'Dialysis / Nephrology',
    'Endoscopy / GI Lab',
    'Burn Unit',
    'Transplant Unit',
    'Infectious Disease',
    'Palliative Care / Hospice',
    'Home Health',
    'Telemetry',
    'Step-Down Unit',
    'Pain Management',
    'Administration',
    'Laboratory',
    'Blood Bank',
    'Central Supply',
    'Environmental Services',
    'Other',
  ];

  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<String> _lookingForOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<Map<String, dynamic>> _shiftTypes = [
    {'value': 'dayShift', 'label': 'Day Shift', 'icon': Icons.wb_sunny_rounded},
    {
      'value': 'nightShift',
      'label': 'Night Shift',
      'icon': Icons.nightlight_round,
    },
    {'value': 'rotatingShift', 'label': 'Rotating', 'icon': Icons.sync_rounded},
    {'value': 'flexible', 'label': 'Flexible', 'icon': Icons.schedule_rounded},
  ];

  static const List<String> _interests = [
    'Reading',
    'Fitness',
    'Cooking',
    'Travel',
    'Music',
    'Movies',
    'Gaming',
    'Photography',
    'Yoga',
    'Dancing',
    'Hiking',
    'Art',
    'Sports',
    'Animals',
    'Coffee',
    'Wine',
    'Meditation',
    'Volunteering',
    'Fashion',
    'Technology',
  ];

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'vi', 'name': 'Vietnamese'},
    {'code': 'tl', 'name': 'Filipino'},
    {'code': 'id', 'name': 'Indonesian'},
    {'code': 'ms', 'name': 'Malay'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'nl', 'name': 'Dutch'},
  ];

  static const List<String> _timezones = [
    'UTC-12:00',
    'UTC-11:00',
    'UTC-10:00',
    'UTC-09:00',
    'UTC-08:00 (PST)',
    'UTC-07:00 (MST)',
    'UTC-06:00 (CST)',
    'UTC-05:00 (EST)',
    'UTC-04:00',
    'UTC-03:00',
    'UTC-02:00',
    'UTC-01:00',
    'UTC+00:00 (GMT)',
    'UTC+01:00 (CET)',
    'UTC+02:00 (EET)',
    'UTC+03:00',
    'UTC+04:00',
    'UTC+05:00',
    'UTC+05:30 (IST)',
    'UTC+06:00',
    'UTC+07:00',
    'UTC+08:00 (CST)',
    'UTC+09:00 (JST)',
    'UTC+10:00 (AEST)',
    'UTC+11:00',
    'UTC+12:00 (NZST)',
  ];

  static String _guessTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final sign = hours >= 0 ? '+' : '-';
    final absHours = hours.abs().toString().padLeft(2, '0');
    final mins = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final formatted = 'UTC$sign$absHours:$mins';
    // Try to find a match in our list
    for (final tz in _timezones) {
      if (tz.startsWith(formatted)) return tz;
    }
    return formatted;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill name from signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(currentUserProvider);
      userAsync.whenData((user) {
        if (user != null && user.name.isNotEmpty && mounted) {
          _nameController.text = user.name;
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _workplaceController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Navigation ──

  void _goToStep(int step) {
    if (step > 0 && !_hasRequiredProfileImage(showError: true)) {
      return;
    }

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    final locale = ref.read(localeProvider);
    String t(String key) => AppLocalizations.translate(key, locale);

    switch (_currentStep) {
      case 0: // Personal info
        if (!_hasRequiredProfileImage(showError: true)) {
          return false;
        }
        if (_nameController.text.trim().isEmpty) {
          _showError(t('error_name_required'));
          return false;
        }
        final age = int.tryParse(_ageController.text.trim());
        if (age == null) {
          _showError(t('error_age_required'));
          return false;
        }
        if (age < 18 || age > 99) {
          _showError(t('error_age_invalid'));
          return false;
        }
        if (_selectedGender == null) {
          _showError(t('error_gender_required'));
          return false;
        }
        if (_selectedLookingFor == null) {
          _showError(t('error_looking_for_required'));
          return false;
        }
        return true;

      case 1: // Career
        if (_selectedJobTitle == null) {
          _showError(t('error_job_required'));
          return false;
        }
        if (_selectedDepartment == null) {
          _showError(t('error_department_required'));
          return false;
        }
        return true;

      case 2: // Schedule
        if (_selectedShiftType == null) {
          _showError(t('error_shift_required'));
          return false;
        }
        if (_locationController.text.trim().isEmpty) {
          _showError(t('error_location_required'));
          return false;
        }
        return true;

      case 3: // Interests
        if (_selectedInterests.length < 3) {
          _showError(t('error_interests_min'));
          return false;
        }
        return true;

      case 4: // Languages + bio
        return true;

      default:
        return true;
    }
  }

  void _handleNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) {
      _goToStep(_currentStep + 1);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  bool _hasRequiredProfileImage({bool showError = false}) {
    if (_profileImage != null) return true;
    if (showError) {
      _showError(
        AppLocalizations.translate(
          'error_photo_required',
          ref.read(localeProvider),
        ),
      );
    }
    return false;
  }

  Future<void> _handleExitSetup({String destination = '/welcome'}) async {
    final locale = ref.read(localeProvider);
    String t(String key) => AppLocalizations.translate(key, locale);

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('exit_setup_title')),
        content: Text(t('exit_setup_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmRose,
              foregroundColor: Colors.white,
            ),
            child: Text(t('exit_setup')),
          ),
        ],
      ),
    );
    if (shouldExit != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).signOut();
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      context.go(destination);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(t('error_generic'));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warmRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Image Picker ──

  Future<void> _pickProfileImage() async {
    final locale = ref.read(localeProvider);
    String t(String key) => AppLocalizations.translate(key, locale);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF082F3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.deepPlum.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.deepPlum,
                    ),
                  ),
                  title: Text(
                    t('select_from_gallery'),
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warmRose.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.warmRose,
                    ),
                  ),
                  title: Text(
                    t('take_photo'),
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    t('cancel'),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      // Silently handle permission denial
    }
  }

  // ── Save Profile ──

  Future<void> _handleCompleteProfile() async {
    if (!_validateCurrentStep()) return;

    if (!_hasRequiredProfileImage(showError: true)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final storageService = ref.read(storageServiceProvider);
      final photoUrl = await storageService.uploadProfileImage(
        userId: uid,
        file: _profileImage!,
      );
      if (photoUrl.trim().isEmpty) {
        throw StateError('Profile image upload returned an empty URL.');
      }

      // Build profile data map
      final profileData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _genderToValue(_selectedGender),
        'lookingFor': _lookingForToValue(_selectedLookingFor),
        'jobTitle': _selectedJobTitle,
        'showProfessionBadge': _showProfessionBadge,
        'hospital': _workplaceController.text.trim().isEmpty
            ? null
            : _workplaceController.text.trim(),
        'department': _selectedDepartment,
        'yearsExperience': _yearsExperience.round(),
        'shiftType': _selectedShiftType,
        'location': _locationController.text.trim(),
        'timezone': _selectedTimezone,
        'interests': _selectedInterests.toList(),
        'languages': _selectedLanguages.toList(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      };

      profileData['photoUrl'] = photoUrl;
      profileData['hasProfilePhoto'] = true;

      await authService.updateUserProfile(profileData);

      if (!mounted) return;
      // Invalidate user cache and navigate
      ref.invalidate(currentUserProvider);
      context.go('/discover');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(
        AppLocalizations.translate('error_generic', ref.read(localeProvider)),
      );
    }
  }

  String? _genderToValue(String? display) {
    switch (display) {
      case 'Male':
        return 'male';
      case 'Female':
        return 'female';
      case 'Non-binary':
        return 'nonBinary';
      case 'Prefer not to say':
        return 'preferNotToSay';
      default:
        return null;
    }
  }

  String? _lookingForToValue(String? display) {
    switch (display) {
      case 'Male':
        return 'relationship';
      case 'Female':
        return 'relationship';
      case 'Non-binary':
        return 'relationship';
      case 'Prefer not to say':
        return 'notSure';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.translate(key, locale);

    return Scaffold(
      body: AnimatedGradientBg(
        colors: const [Color(0xFF0F766E), Color(0xFF075985), Color(0xFF0F0B15)],
        child: SafeArea(
          child: Column(
            children: [
              // ── Progress Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _currentStep > 0
                                ? GestureDetector(
                                    onTap: _isSaving ? null : _handleBack,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 36, height: 36),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_currentStep + 1} / 5',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSaving ? null : _handleExitSetup,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withValues(
                                  alpha: 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                t('exit_setup'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.deepPlum,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Page Content ──
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentStep = page),
                  children: [
                    _buildStep1(t),
                    _buildStep2(t),
                    _buildStep3(t),
                    _buildStep4(t),
                    _buildStep5(t),
                  ],
                ),
              ),

              // ── Bottom button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isSaving
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                t('saving'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _currentStep == 4
                                ? _handleCompleteProfile
                                : _handleNext,
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F766E),
                                    Color(0xFFDC2626),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warmRose.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _currentStep == 4
                                      ? t('complete_profile')
                                      : t('next'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: Personal Info
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep1(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(t('step_know_you'))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 24),

          // Profile photo
          Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: _profileImage != null
                                ? AppTheme.deepPlum
                                : Colors.white.withValues(alpha: 0.3),
                            width: 3,
                          ),
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t('profile_photo'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.deepPlum,
                            border: Border.all(
                              color: const Color(0xFF0F0B15),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                delay: 100.ms,
              ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              t('profile_photo_required_hint'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Name
          _fieldLabel(t('name')),
          const SizedBox(height: 6),
          _styledTextField(
            controller: _nameController,
            hint: 'e.g. Sarah Johnson',
            icon: Icons.person_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Age
          _fieldLabel(t('age')),
          const SizedBox(height: 6),
          _styledTextField(
            controller: _ageController,
            hint: 'e.g. 28',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          const SizedBox(height: 16),

          // Gender
          _fieldLabel(t('gender')),
          const SizedBox(height: 6),
          _styledDropdown(
            value: _selectedGender,
            items: _genderOptions,
            hint: 'Select gender',
            icon: Icons.wc_outlined,
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          const SizedBox(height: 16),

          // Looking for
          _fieldLabel(t('looking_for')),
          const SizedBox(height: 6),
          _styledDropdown(
            value: _selectedLookingFor,
            items: _lookingForOptions,
            hint: 'Select preference',
            icon: Icons.favorite_border_rounded,
            onChanged: (val) => setState(() => _selectedLookingFor = val),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: Healthcare Career
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep2(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(t('step_career'))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 24),

          // Job title
          _fieldLabel(t('job_title')),
          const SizedBox(height: 6),
          _styledDropdown(
            value: _selectedJobTitle,
            items: _jobTitles,
            hint: 'Select your role',
            icon: Icons.medical_services_outlined,
            onChanged: (val) => setState(() => _selectedJobTitle = val),
          ),
          const SizedBox(height: 12),
          _buildProfessionBadgeOptIn(),
          const SizedBox(height: 16),

          // Workplace
          _fieldLabel(t('workplace')),
          const SizedBox(height: 6),
          _styledTextField(
            controller: _workplaceController,
            hint: 'e.g. Tokyo General Hospital',
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 16),

          // Department
          _fieldLabel(t('department')),
          const SizedBox(height: 6),
          _styledDropdown(
            value: _selectedDepartment,
            items: _departments,
            hint: 'Select department',
            icon: Icons.domain_outlined,
            onChanged: (val) => setState(() => _selectedDepartment = val),
          ),
          const SizedBox(height: 24),

          // Years of experience slider
          _fieldLabel('${t('years_experience')}: ${_yearsExperience.round()}'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.deepPlum,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: AppTheme.deepPlum,
              overlayColor: AppTheme.deepPlum.withValues(alpha: 0.2),
              valueIndicatorColor: AppTheme.deepPlum,
              valueIndicatorTextStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _yearsExperience,
              min: 0,
              max: 40,
              divisions: 40,
              label: '${_yearsExperience.round()} years',
              onChanged: (val) => setState(() => _yearsExperience = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: _sliderLabel),
              Text('10', style: _sliderLabel),
              Text('20', style: _sliderLabel),
              Text('30', style: _sliderLabel),
              Text('40', style: _sliderLabel),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  TextStyle get _sliderLabel => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    color: Colors.white.withValues(alpha: 0.4),
  );

  Widget _buildProfessionBadgeOptIn() {
    final preview = _selectedJobTitle ?? 'Your profession';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _showProfessionBadge,
            onChanged: (value) => setState(() => _showProfessionBadge = value),
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.deepPlum,
            secondary: const Icon(
              Icons.badge_outlined,
              color: Color(0xFF67E8F9),
            ),
            title: Text(
              'Show profession badge',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Display a public badge like "$preview" on your swipe card and profile.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _showProfessionBadge ? 1 : 0.55,
            duration: const Duration(milliseconds: 180),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF155E75).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF67E8F9).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.badge_rounded,
                    color: Color(0xFF67E8F9),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _showProfessionBadge ? preview : 'Badge hidden',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: Schedule
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep3(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(t('step_schedule'))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 24),

          // Shift type visual cards
          _fieldLabel(t('shift_type')),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: _shiftTypes.length,
            itemBuilder: (context, index) {
              final shift = _shiftTypes[index];
              final isSelected = _selectedShiftType == shift['value'] as String;
              return GestureDetector(
                    onTap: () => setState(
                      () => _selectedShiftType = shift['value'] as String,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.deepPlum.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.deepPlum
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            shift['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shift['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(delay: (index * 80).ms)
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                  );
            },
          ),
          const SizedBox(height: 24),

          // Location
          _fieldLabel(t('location')),
          const SizedBox(height: 6),
          _styledTextField(
            controller: _locationController,
            hint: 'e.g. Tokyo, Japan',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          // Timezone
          _fieldLabel(t('timezone')),
          const SizedBox(height: 6),
          _styledDropdown(
            value: _timezones.contains(_selectedTimezone)
                ? _selectedTimezone
                : null,
            items: _timezones,
            hint: 'Select timezone',
            icon: Icons.access_time_rounded,
            onChanged: (val) {
              if (val != null) setState(() => _selectedTimezone = val);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 4: Interests
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep4(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(t('step_interests'))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 8),
          Text(
            t('select_interests'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedInterests.length} / 10 selected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _selectedInterests.length >= 3
                  ? const Color(0xFF16A34A)
                  : Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interests.asMap().entries.map((entry) {
              final index = entry.key;
              final interest = entry.value;
              final isSelected = _selectedInterests.contains(interest);

              return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest);
                        } else if (_selectedInterests.length < 10) {
                          _selectedInterests.add(interest);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.deepPlum
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.deepPlum
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                  .animate(delay: (index * 40).ms)
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                  );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 5: Languages + Bio
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep5(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(t('step_languages'))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 8),
          Text(
            t('select_languages'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Language chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _languages.asMap().entries.map((entry) {
              final index = entry.key;
              final lang = entry.value;
              final isSelected = _selectedLanguages.contains(lang['code']);

              return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedLanguages.remove(lang['code']!);
                        } else {
                          _selectedLanguages.add(lang['code']!);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.deepPlum
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.deepPlum
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        lang['name']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                  .animate(delay: (index * 40).ms)
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                  );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Bio
          _fieldLabel(t('bio')),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: _bioController,
              maxLines: 5,
              maxLength: AppConstants.maxBioLength,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: t('bio_hint'),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _stepTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.deepPlum, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _styledDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Text(
                hint,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF082F3A),
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
