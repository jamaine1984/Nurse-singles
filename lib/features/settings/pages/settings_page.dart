import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/auth_service.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/features/settings/pages/language_page.dart';
import 'package:nightingale_heart/features/settings/pages/edit_profile_page.dart';
import 'package:nightingale_heart/features/settings/pages/blocked_users_page.dart';
import 'package:nightingale_heart/features/subscription/pages/manage_sub_page.dart';
import 'package:nightingale_heart/features/settings/pages/help_faq_page.dart';
import 'package:nightingale_heart/features/settings/pages/terms_of_service_page.dart';
import 'package:nightingale_heart/features/settings/pages/privacy_policy_page.dart';
import 'package:nightingale_heart/features/settings/pages/about_page.dart';
import 'package:nightingale_heart/features/profile/pages/verification_page.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _nightShiftAutoMode = false;
  bool _notificationsEnabled = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _incognitoMode = false;
  bool _showDistance = true;
  bool _useKilometers = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nightShiftAutoMode = prefs.getBool('night_shift_auto') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _showOnlineStatus = prefs.getBool('show_online_status') ?? true;
      _showLastSeen = prefs.getBool('show_last_seen') ?? true;
      _incognitoMode = prefs.getBool('incognito_mode') ?? false;
      _showDistance = prefs.getBool('show_distance') ?? true;
      _useKilometers = prefs.getBool('use_kilometers') ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  String _planLabel(SubscriptionPlan plan) => _t('plan_${plan.value}');

  String _verificationBadge(UserModel user) {
    return AppLocalizations.healthcareCredentialLabel(
      user.healthcareCredentialType?.value,
      ref.read(localeProvider),
      fallback: _t('verified'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final userAsync = ref.watch(currentUserProvider);
    ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('settings'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(_t('please_sign_in')));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(
                  user,
                  theme,
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),
                _sectionTitle(_t('account'), theme),
                const SizedBox(height: 8),
                _buildAccountSection(user, theme),
                const SizedBox(height: 24),
                _sectionTitle(_t('preferences'), theme),
                const SizedBox(height: 8),
                _buildPreferencesSection(theme, isDark),
                const SizedBox(height: 24),
                _sectionTitle(_t('privacy'), theme),
                const SizedBox(height: 8),
                _buildPrivacySection(user, theme),
                const SizedBox(height: 24),
                _sectionTitle(_t('support'), theme),
                const SizedBox(height: 8),
                _buildSupportSection(theme),
                const SizedBox(height: 24),
                _sectionTitle(_t('danger_zone'), theme),
                const SizedBox(height: 8),
                _buildDangerZone(theme),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(_t('something_went_wrong'))),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    Color planColor;
    switch (user.plan) {
      case SubscriptionPlan.tech:
        planColor = const Color(0xFF3B82F6);
        break;
      case SubscriptionPlan.college:
        planColor = AppTheme.warmRose;
        break;
      case SubscriptionPlan.nurse:
        planColor = AppTheme.softAmber;
        break;
      case SubscriptionPlan.doctor:
        planColor = AppTheme.deepPlum;
        break;
      default:
        planColor = AppTheme.warmGray;
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.softLavender,
            backgroundImage: user.displayPhoto != null
                ? CachedNetworkImageProvider(user.displayPhoto!)
                : null,
            child: user.displayPhoto == null
                ? Icon(Icons.person, size: 32, color: AppTheme.deepPlum)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _planLabel(user.plan),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: planColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _t('edit_profile'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAccountSection(UserModel user, ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            title: _t('edit_profile'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.verified_outlined,
            title: _t('verification_status'),
            trailing: user.isVerified
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: AppTheme.emerald,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            _verificationBadge(user),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t('verify_now'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.softAmber,
                      ),
                    ),
                  ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VerificationPage()),
              );
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.workspace_premium,
            title: _t('subscription'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ManageSubPage()));
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.block,
            title: _t('blocked_users'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${user.blocked.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeData theme, bool isDark) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.language,
            title: _t('language'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LanguagePage()));
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: _t('dark_mode'),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.nightlight_outlined,
            title: _t('night_shift_auto_mode'),
            subtitle: _t('night_shift_auto_mode_subtitle'),
            trailing: Switch(
              value: _nightShiftAutoMode,
              onChanged: (val) {
                setState(() => _nightShiftAutoMode = val);
                _savePref('night_shift_auto', val);
                if (val) {
                  final hour = DateTime.now().hour;
                  final shouldBeDark = hour >= 19 || hour < 7;
                  ref
                      .read(themeProvider.notifier)
                      .setTheme(
                        shouldBeDark ? ThemeMode.dark : ThemeMode.light,
                      );
                }
              },
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: _t('notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                _savePref('notifications_enabled', val);
              },
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.straighten,
            title: _t('distance_unit'),
            trailing: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('km')),
                ButtonSegment(value: false, label: Text('mi')),
              ],
              selected: {_useKilometers},
              onSelectionChanged: (val) {
                setState(() => _useKilometers = val.first);
                _savePref('use_kilometers', val.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.deepPlum,
                selectedForegroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(UserModel user, ThemeData theme) {
    final isPremium =
        user.plan == SubscriptionPlan.nurse ||
        user.plan == SubscriptionPlan.doctor;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.circle,
            title: _t('show_online_status'),
            trailing: Switch(
              value: _showOnlineStatus,
              onChanged: (val) {
                setState(() => _showOnlineStatus = val);
                _savePref('show_online_status', val);
                ref.read(authServiceProvider).updateUserProfile({
                  'isOnline': val,
                });
              },
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.access_time,
            title: _t('show_last_seen'),
            trailing: Switch(
              value: _showLastSeen,
              onChanged: (val) {
                setState(() => _showLastSeen = val);
                _savePref('show_last_seen', val);
              },
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.visibility_off_outlined,
            title: _t('incognito_mode'),
            subtitle: isPremium ? null : _t('premium_only'),
            trailing: Switch(
              value: _incognitoMode,
              onChanged: isPremium
                  ? (val) {
                      setState(() => _incognitoMode = val);
                      _savePref('incognito_mode', val);
                    }
                  : null,
            ),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.location_off_outlined,
            title: _t('show_distance'),
            trailing: Switch(
              value: _showDistance,
              onChanged: (val) {
                setState(() => _showDistance = val);
                _savePref('show_distance', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.help_outline,
            title: _t('help_faq'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HelpFaqPage()));
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: _t('contact_us'),
            trailing: Text(
              AppConstants.supportEmail,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: _t('terms_of_service'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: _t('privacy_policy'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.info_outline,
            title: _tf('about_app', {'app': AppConstants.appName}),
            trailing: Text(
              'v${AppConstants.appVersion}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: Colors.red.withValues(alpha: 0.2),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.logout,
            title: _t('log_out'),
            iconColor: Colors.red,
            titleColor: Colors.red,
            trailing: const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.red,
            ),
            onTap: () => _showLogoutDialog(),
          ),
          _divider(theme),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: _t('delete_account'),
            iconColor: Colors.red,
            titleColor: Colors.red,
            trailing: const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.red,
            ),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 52,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t('log_out'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _t('log_out_confirm'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authServiceProvider).signOut();
              ref.invalidate(authStateProvider);
              ref.invalidate(currentUserProvider);
              if (!mounted) return;
              context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('log_out')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t('delete_account'),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          _t('delete_account_warning'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showFinalDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('continue')),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t('final_confirmation'),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          _t('type_delete_confirm'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('[Settings] Account deletion confirmed');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _t('account_deletion_pending'),
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('delete_forever')),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
