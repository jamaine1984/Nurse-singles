import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/auth_service.dart';
import 'package:nightingale_heart/core/services/storage_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _hospitalController;
  late TextEditingController _locationController;

  String? _selectedJobTitle;
  String? _selectedDepartment;
  String? _selectedLookingFor;
  ShiftType? _selectedShiftType;
  DatingWindow? _selectedDatingWindow;
  bool _availableAfterShift = false;
  String? _quietHoursStart;
  String? _quietHoursEnd;
  double _yearsExperience = 0;
  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = [];
  List<String> _gallery = [];
  String? _photoUrl;
  File? _newProfileImage;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _showProfessionBadge = true;
  bool _hideWorkplace = false;
  bool _avoidSameWorkplace = false;
  bool _avoidSameDepartment = false;

  static const List<String> _jobTitles = [
    'Registered Nurse',
    'Nurse Practitioner',
    'Physician',
    'Surgeon',
    'Pharmacist',
    'Physical Therapist',
    'Occupational Therapist',
    'Paramedic',
    'Radiologist',
    'Lab Technician',
    'Medical Assistant',
    'Dentist',
    'Psychologist',
    'Social Worker',
    'Respiratory Therapist',
    'Dietitian',
    'Speech Pathologist',
    'Midwife',
    'Anesthesiologist',
    'Other Healthcare Professional',
  ];

  static const List<String> _departments = [
    'Emergency',
    'ICU',
    'Pediatrics',
    'Cardiology',
    'Oncology',
    'Orthopedics',
    'Neurology',
    'Obstetrics',
    'Psychiatry',
    'Radiology',
    'Surgery',
    'Internal Medicine',
    'Family Medicine',
    'Geriatrics',
    'Dermatology',
    'Ophthalmology',
    'ENT',
    'Urology',
    'Pharmacy',
    'Other',
  ];

  static const List<String> _interestOptions = [
    'Hiking',
    'Cooking',
    'Reading',
    'Travel',
    'Yoga',
    'Fitness',
    'Music',
    'Photography',
    'Movies',
    'Gaming',
    'Dancing',
    'Art',
    'Volunteering',
    'Running',
    'Swimming',
    'Cycling',
    'Meditation',
    'Wine Tasting',
    'Board Games',
    'Gardening',
    'Camping',
    'Pets',
    'Coffee',
    'Food',
    'Fashion',
    'Technology',
    'Sports',
    'Writing',
    'Painting',
    'Singing',
  ];

  static const List<String> _languageOptions = [
    'English',
    'Spanish',
    'French',
    'Portuguese',
    'German',
    'Italian',
    'Japanese',
    'Korean',
    'Chinese',
    'Arabic',
    'Hindi',
    'Filipino',
    'Vietnamese',
    'Thai',
    'Indonesian',
    'Russian',
    'Turkish',
    'Polish',
    'Dutch',
    'Swahili',
  ];

  static const List<String> _quietHourOptions = [
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
    '00:00',
    '01:00',
    '02:00',
    '03:00',
    '04:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _hospitalController = TextEditingController();
    _locationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';
      _hospitalController.text = user.hospital ?? '';
      _locationController.text = user.location ?? '';
      _selectedJobTitle = user.jobTitle;
      _selectedDepartment = user.department;
      _selectedLookingFor = user.lookingFor?.value;
      _selectedShiftType = user.shiftType;
      _selectedDatingWindow = user.preferredDatingWindow;
      _availableAfterShift = user.availableAfterShift;
      _quietHoursStart = user.quietHoursStart;
      _quietHoursEnd = user.quietHoursEnd;
      _yearsExperience = (user.yearsExperience ?? 0).toDouble();
      _selectedInterests = List<String>.from(user.interests);
      _selectedLanguages = List<String>.from(user.languages);
      _gallery = List<String>.from(user.gallery);
      _photoUrl = user.photoUrl;
      _showProfessionBadge = user.showProfessionBadge;
      _hideWorkplace = user.hideWorkplace;
      _avoidSameWorkplace = user.avoidSameWorkplace;
      _avoidSameDepartment = user.avoidSameDepartment;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hospitalController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(localeProvider);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _t('edit_profile'),
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePhoto(theme).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                _buildGallerySection(
                  theme,
                ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  label: _t('name'),
                  icon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? _t('name_required')
                      : null,
                ),
                const SizedBox(height: 16),
                _buildBioField(theme),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: _t('job_title'),
                  icon: Icons.work_outline,
                  value: _selectedJobTitle,
                  items: _jobTitles,
                  onChanged: (val) {
                    setState(() => _selectedJobTitle = val);
                    _markChanged();
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hospitalController,
                  label: _t('hospital_workplace'),
                  icon: Icons.local_hospital_outlined,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: _t('department'),
                  icon: Icons.business_outlined,
                  value: _selectedDepartment,
                  items: _departments,
                  onChanged: (val) {
                    setState(() => _selectedDepartment = val);
                    _markChanged();
                  },
                ),
                const SizedBox(height: 16),
                _buildWorkplacePrivacySection(theme),
                const SizedBox(height: 16),
                _buildProfessionBadgeSection(theme),
                const SizedBox(height: 16),
                _buildExperienceSlider(theme),
                const SizedBox(height: 16),
                _buildShiftTypeSelector(theme),
                const SizedBox(height: 16),
                _buildShiftAvailabilitySection(theme),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: _t('location'),
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 20),
                _buildInterestsSection(theme),
                const SizedBox(height: 20),
                _buildLanguagesSection(theme),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: _t('looking_for'),
                  icon: Icons.favorite_outline,
                  value: _selectedLookingFor,
                  items: LookingFor.values.map((l) => l.value).toList(),
                  displayItems: LookingFor.values
                      .map((l) => l.displayName)
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedLookingFor = val);
                    _markChanged();
                  },
                ),
                const SizedBox(height: 32),
                _buildSaveButton(theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(ThemeData theme) {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: AppTheme.softLavender,
              backgroundImage: _newProfileImage != null
                  ? FileImage(_newProfileImage!)
                  : (_photoUrl != null
                            ? CachedNetworkImageProvider(_photoUrl!)
                            : null)
                        as ImageProvider?,
              child: _newProfileImage == null && _photoUrl == null
                  ? const Icon(Icons.person, size: 48, color: AppTheme.deepPlum)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallerySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gallery',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_gallery.length}/${AppConstants.maxGalleryImages}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._gallery.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: entry.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 100,
                            height: 100,
                            color: AppTheme.softLavender,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: AppTheme.softLavender,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _gallery.removeAt(entry.key);
                            });
                            _markChanged();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_gallery.length < AppConstants.maxGalleryImages)
                GestureDetector(
                  onTap: _pickGalleryImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.deepPlum.withValues(alpha: 0.3),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      color: AppTheme.softLavender.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: AppTheme.deepPlum,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildBioField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: AppConstants.maxBioLength,
          onChanged: (_) => _markChanged(),
          decoration: const InputDecoration(
            labelText: 'Bio',
            prefixIcon: Icon(Icons.edit_note),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    List<String>? displayItems,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items.asMap().entries.map((entry) {
        return DropdownMenuItem(
          value: entry.value,
          child: Text(
            displayItems != null ? displayItems[entry.key] : entry.value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildWorkplacePrivacySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.deepPlum.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppTheme.deepPlum,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('workplace_privacy'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Control how hospital information appears and affects matching.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPrivacyToggle(
            theme: theme,
            value: _hideWorkplace,
            icon: Icons.visibility_off_outlined,
            title: _t('hide_hospital_name'),
            subtitle: _t('hide_hospital_name_subtitle'),
            onChanged: (value) {
              setState(() => _hideWorkplace = value);
              _markChanged();
            },
          ),
          _buildPrivacyToggle(
            theme: theme,
            value: _avoidSameWorkplace,
            icon: Icons.domain_disabled_outlined,
            title: _t('avoid_same_workplace'),
            subtitle: _t('avoid_same_workplace_subtitle'),
            onChanged: (value) {
              setState(() => _avoidSameWorkplace = value);
              _markChanged();
            },
          ),
          _buildPrivacyToggle(
            theme: theme,
            value: _avoidSameDepartment,
            icon: Icons.medical_services_outlined,
            title: _t('avoid_same_department'),
            subtitle: _t('avoid_same_department_subtitle'),
            onChanged: (value) {
              setState(() => _avoidSameDepartment = value);
              _markChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionBadgeSection(ThemeData theme) {
    final preview = _selectedJobTitle?.trim().isNotEmpty == true
        ? _selectedJobTitle!.trim()
        : 'Healthcare Professional';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _showProfessionBadge,
            onChanged: (value) {
              setState(() => _showProfessionBadge = value);
              _markChanged();
            },
            activeColor: AppTheme.emerald,
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.badge_outlined,
              color: AppTheme.emerald,
            ),
            title: Text(
              'Show profession badge',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'When enabled, your swipe card and profile show "$preview" as a public healthcare role badge.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.3,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: (_showProfessionBadge ? AppTheme.emerald : Colors.grey)
                  .withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_showProfessionBadge ? AppTheme.emerald : Colors.grey)
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showProfessionBadge
                      ? Icons.badge_rounded
                      : Icons.visibility_off_outlined,
                  color: _showProfessionBadge
                      ? AppTheme.emerald
                      : theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _showProfessionBadge ? preview : 'Profession badge hidden',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _showProfessionBadge
                          ? AppTheme.emerald
                          : theme.colorScheme.onSurfaceVariant,
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

  Widget _buildPrivacyToggle({
    required ThemeData theme,
    required bool value,
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.deepPlum,
      contentPadding: EdgeInsets.zero,
      dense: true,
      secondary: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          height: 1.25,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildShiftAvailabilitySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  color: AppTheme.emerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('shift_availability'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t('shift_availability_help'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<DatingWindow>(
            value: _selectedDatingWindow,
            decoration: InputDecoration(
              labelText: _t('preferred_dating_window'),
              prefixIcon: const Icon(Icons.event_available_outlined),
            ),
            items: DatingWindow.values
                .map(
                  (window) => DropdownMenuItem(
                    value: window,
                    child: Text(
                      AppLocalizations.datingWindowLabel(
                        window.value,
                        ref.read(localeProvider),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedDatingWindow = value);
              _markChanged();
            },
          ),
          SwitchListTile.adaptive(
            value: _availableAfterShift,
            onChanged: (value) {
              setState(() => _availableAfterShift = value);
              _markChanged();
            },
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.emerald,
            title: Text(
              _t('available_after_shift'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              _t('available_after_shift_subtitle'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _quietHourOptions.contains(_quietHoursStart)
                      ? _quietHoursStart
                      : null,
                  decoration: InputDecoration(
                    labelText: _t('quiet_start'),
                    prefixIcon: const Icon(Icons.do_not_disturb_on_outlined),
                  ),
                  items: _quietHourOptions
                      .map(
                        (hour) =>
                            DropdownMenuItem(value: hour, child: Text(hour)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _quietHoursStart = value);
                    _markChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _quietHourOptions.contains(_quietHoursEnd)
                      ? _quietHoursEnd
                      : null,
                  decoration: InputDecoration(
                    labelText: _t('quiet_end'),
                    prefixIcon: const Icon(Icons.notifications_paused_outlined),
                  ),
                  items: _quietHourOptions
                      .map(
                        (hour) =>
                            DropdownMenuItem(value: hour, child: Text(hour)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _quietHoursEnd = value);
                    _markChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Years of Experience',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.deepPlum.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_yearsExperience.toInt()} years',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepPlum,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _yearsExperience,
          min: 0,
          max: 40,
          divisions: 40,
          label: '${_yearsExperience.toInt()} years',
          activeColor: AppTheme.deepPlum,
          onChanged: (val) {
            setState(() => _yearsExperience = val);
            _markChanged();
          },
        ),
      ],
    );
  }

  Widget _buildShiftTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('shift_type'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ShiftType.values.map((shift) {
            final isSelected = _selectedShiftType == shift;
            return ChoiceChip(
              label: Text(
                AppLocalizations.shiftTypeLabel(
                  shift.value,
                  ref.read(localeProvider),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedShiftType = selected ? shift : null);
                _markChanged();
              },
              selectedColor: AppTheme.deepPlum,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Interests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedInterests.length}/${AppConstants.maxInterests}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected &&
                      _selectedInterests.length < AppConstants.maxInterests) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
                _markChanged();
              },
              selectedColor: AppTheme.deepPlum,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages I Speak',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageOptions.map((lang) {
            final isSelected = _selectedLanguages.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(lang);
                  } else {
                    _selectedLanguages.remove(lang);
                  }
                });
                _markChanged();
              },
              selectedColor: AppTheme.deepPlum,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepPlum.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _t('save_changes'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _newProfileImage = File(picked.path);
      });
      _markChanged();
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_gallery.length >= AppConstants.maxGalleryImages) return;

    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked != null) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      setState(() => _isSaving = true);
      try {
        final storageService = ref.read(storageServiceProvider);
        final url = await storageService.uploadGalleryImage(
          userId: user.id,
          file: File(picked.path),
        );
        if (!mounted) return;
        setState(() {
          _gallery = [..._gallery, url];
          _isSaving = false;
        });
        _markChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('gallery_selected_save'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tf('failed_to_save', {'error': error}),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('choose_photo'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.deepPlum.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.deepPlum),
                ),
                title: Text(
                  _t('camera'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warmRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppTheme.warmRose,
                  ),
                ),
                title: Text(
                  _t('gallery'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(authServiceProvider);
      String? uploadedPhotoUrl = _photoUrl;

      // Upload new profile image if selected
      if (_newProfileImage != null) {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null) {
          final storageService = ref.read(storageServiceProvider);
          final url = await storageService.uploadProfileImage(
            userId: user.id,
            file: _newProfileImage!,
          );
          uploadedPhotoUrl = url;
        }
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'location': _locationController.text.trim(),
        'jobTitle': _selectedJobTitle,
        'department': _selectedDepartment,
        'showProfessionBadge': _showProfessionBadge,
        'hideWorkplace': _hideWorkplace,
        'avoidSameWorkplace': _avoidSameWorkplace,
        'avoidSameDepartment': _avoidSameDepartment,
        'lookingFor': _selectedLookingFor,
        'shiftType': _selectedShiftType?.value,
        'preferredDatingWindow': _selectedDatingWindow?.value,
        'availableAfterShift': _availableAfterShift,
        'quietHoursStart': _quietHoursStart,
        'quietHoursEnd': _quietHoursEnd,
        'yearsExperience': _yearsExperience.toInt(),
        'interests': _selectedInterests,
        'languages': _selectedLanguages,
        'gallery': _gallery,
        if (uploadedPhotoUrl != null) 'photoUrl': uploadedPhotoUrl,
      };

      await authService.updateUserProfile(data);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      // Refresh user data
      ref.invalidate(currentUserProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('profile_updated'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.deepPlum,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tf('failed_to_save', {'error': e}),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t('discard_changes'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _t('unsaved_discard_prompt'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('keep_editing')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmRose,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('discard')),
          ),
        ],
      ),
    );
  }
}
