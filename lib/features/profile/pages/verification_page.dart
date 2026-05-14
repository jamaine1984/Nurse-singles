import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  File? _selfieFile;
  File? _credentialFile;
  bool _isSubmitting = false;
  String? _currentStatus; // null, 'pending', 'verified', 'rejected'
  HealthcareCredentialType _selectedCredentialType =
      HealthcareCredentialType.healthcareWorker;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection(AppConstants.verificationRequestsCollection)
          .doc(user.id)
          .get();
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .get();
      if (mounted) {
        final requestData = requestDoc.data();
        final userData = userDoc.data();
        final credentialType =
            requestData?['credentialType'] as String? ??
            userData?['healthcareCredentialType'] as String?;
        setState(() {
          _currentStatus =
              requestData?['status'] as String? ??
              userData?['verificationStatus'] as String?;
          if (credentialType != null && credentialType.isNotEmpty) {
            _selectedCredentialType = HealthcareCredentialType.fromString(
              credentialType,
            );
          }
        });
      }
    } catch (_) {}
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _credentialLabel(HealthcareCredentialType type, {String? fallback}) {
    return AppLocalizations.healthcareCredentialLabel(
      type.value,
      ref.read(localeProvider),
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    ref.watch(localeProvider);
    final isVerified = user?.isVerified ?? false;
    final verifiedBadge = _credentialLabel(
      user?.healthcareCredentialType ?? _selectedCredentialType,
      fallback: user?.healthcareVerificationBadge,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('profile_verification'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Banner ──────────────────────────────────────────
            if (isVerified)
              _buildStatusBanner(
                icon: Icons.verified_rounded,
                title: verifiedBadge,
                subtitle: _t('verified_badge_subtitle'),
                color: AppTheme.emerald,
              )
            else if (_currentStatus == 'pending')
              _buildStatusBanner(
                icon: Icons.hourglass_top_rounded,
                title: _t('verification_pending'),
                subtitle: _t('verification_pending_subtitle'),
                color: AppTheme.softAmber,
              )
            else if (_currentStatus == 'rejected')
              _buildStatusBanner(
                icon: Icons.cancel_rounded,
                title: _t('verification_rejected'),
                subtitle: _t('verification_rejected_subtitle'),
                color: AppTheme.warmRose,
              )
            else
              _buildStatusBanner(
                icon: Icons.verified_outlined,
                title: _t('get_healthcare_verified'),
                subtitle: _t('get_healthcare_verified_subtitle'),
                color: AppTheme.deepPlum,
              ),

            const SizedBox(height: 24),

            // ── How It Works ───────────────────────────────────────────
            Text(
              _t('how_it_works'),
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StepRow(
                    step: '1',
                    title: _t('choose_credential_track'),
                    description: _t('choose_credential_track_desc'),
                  ),
                  const SizedBox(height: 14),
                  _StepRow(
                    step: '2',
                    title: _t('submit_private_evidence'),
                    description: _t('submit_private_evidence_desc'),
                  ),
                  const SizedBox(height: 14),
                  _StepRow(
                    step: '3',
                    title: _t('get_right_badge'),
                    description: _t('get_right_badge_desc'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),

            if (!isVerified && _currentStatus != 'pending') ...[
              _buildCredentialTypeSection(theme),
              const SizedBox(height: 16),
              _buildCredentialEvidenceSection(theme),
              const SizedBox(height: 24),
            ],

            // ── Selfie Section ─────────────────────────────────────────
            if (!isVerified && _currentStatus != 'pending') ...[
              Text(
                _t('your_verification_selfie'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _takeSelfie,
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: _selfieFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _selfieFile!,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.deepPlum.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 40,
                                color: AppTheme.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _t('tap_to_take_selfie'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepPlum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t('front_camera_best'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 8),

              // Tips
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('tips_for_approval'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TipRow(text: _t('tip_face_camera')),
                    _TipRow(text: _t('tip_good_lighting')),
                    _TipRow(text: _t('tip_no_sunglasses')),
                    _TipRow(text: _t('tip_match_profile')),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _selfieFile != null &&
                          _credentialFile != null &&
                          !_isSubmitting
                      ? _submit
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded, size: 22),
                  label: Text(
                    _isSubmitting
                        ? _t('submitting')
                        : _t('submit_healthcare_verification'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepPlum,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.deepPlum.withValues(
                      alpha: 0.4,
                    ),
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCredentialTypeSection(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('healthcare_badge_type'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('healthcare_badge_type_subtitle'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<HealthcareCredentialType>(
            value: _selectedCredentialType,
            decoration: InputDecoration(
              labelText: _t('credential_track'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            items: HealthcareCredentialType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      _credentialLabel(type),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedCredentialType = value);
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 140.ms);
  }

  Widget _buildCredentialEvidenceSection(ThemeData theme) {
    return GestureDetector(
      onTap: _pickCredentialEvidence,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _credentialFile == null
                    ? Icons.upload_file_outlined
                    : Icons.check_circle_rounded,
                color: AppTheme.emerald,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _credentialFile == null
                        ? _t('add_credential_evidence')
                        : _t('credential_evidence_added'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _t('credential_evidence_body'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.35,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_credentialFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _credentialFile!.path.split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 180.ms);
  }

  Future<void> _takeSelfie() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('choose_photo_source'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.deepPlum.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.deepPlum,
                  ),
                ),
                title: Text(
                  _t('take_selfie'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _t('use_front_camera'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.emerald,
                  ),
                ),
                title: Text(
                  _t('choose_from_gallery'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _t('select_existing_photo'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked != null && mounted) {
      setState(() => _selfieFile = File(picked.path));
    }
  }

  Future<void> _pickCredentialEvidence() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('credential_evidence'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.deepPlum.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.deepPlum,
                  ),
                ),
                title: Text(
                  _t('take_photo'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _t('credential_photo_subtitle'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.emerald,
                  ),
                ),
                title: Text(
                  _t('choose_from_gallery'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _t('select_credential_image'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked != null && mounted) {
      setState(() => _credentialFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_selfieFile == null || _credentialFile == null || _isSubmitting) {
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final selfieFileName = 'selfie_$nowMs.jpg';
      final credentialFileName = 'credential_$nowMs.jpg';
      final selfieRef = FirebaseStorage.instance.ref().child(
        'verification/${user.id}/$selfieFileName',
      );
      final credentialRef = FirebaseStorage.instance.ref().child(
        'credential_verification/${user.id}/$credentialFileName',
      );

      await selfieRef.putFile(_selfieFile!);
      await credentialRef.putFile(_credentialFile!);
      final selfieUrl = await selfieRef.getDownloadURL();
      final credentialUrl = await credentialRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(AppConstants.verificationRequestsCollection)
          .doc(user.id)
          .set({
            'userId': user.id,
            'userName': user.name,
            'userEmail': user.email,
            'userPhotoUrl': user.photoUrl,
            'credentialType': _selectedCredentialType.value,
            'credentialTypeLabel': _selectedCredentialType.displayName,
            'selfieUrl': selfieUrl,
            'credentialEvidenceUrl': credentialUrl,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          _currentStatus = 'pending';
          _isSubmitting = false;
          _selfieFile = null;
          _credentialFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('verification_submitted'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      debugPrint('[VerificationPage] Submit error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('submit_failed_try_again'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.warmRose,
          ),
        );
      }
    }
  }
}

// ─── Step Row ──────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.deepPlum.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepPlum,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tip Row ───────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppTheme.emerald,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
