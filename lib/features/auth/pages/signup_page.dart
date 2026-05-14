import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/auth_service.dart';
import 'package:nightingale_heart/core/widgets/animated_gradient_bg.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// Registration page with password strength indicator, terms checkbox,
/// and full validation.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  _PasswordStrength _passwordStrength = _PasswordStrength.none;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = _PasswordStrength.none);
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(
      r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?]',
    ).hasMatch(password)) {
      score++;
    }

    setState(() {
      if (score <= 2) {
        _passwordStrength = _PasswordStrength.weak;
      } else if (score <= 4) {
        _passwordStrength = _PasswordStrength.medium;
      } else {
        _passwordStrength = _PasswordStrength.strong;
      }
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final locale = ref.read(localeProvider);
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate('error_terms_required', locale),
          ),
          backgroundColor: AppTheme.warmRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go('/onboarding');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.warmRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _getErrorMessage(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in.';
    } else if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (msg.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters.';
    } else if (msg.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return 'Sign up failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.translate(key, locale);

    return Scaffold(
      body: AnimatedGradientBg(
        colors: const [Color(0xFF0F766E), Color(0xFF075985), Color(0xFF0F0B15)],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // ── Title ──
                  Text(
                        t('create_account'),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    t('tagline'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                  const SizedBox(height: 28),

                  // ── Glass card form ──
                  GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: _inputDecoration(
                                  label: t('name'),
                                  icon: Icons.person_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('error_name_required');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: _inputDecoration(
                                  label: t('email'),
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('error_email_required');
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return t('error_email_invalid');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                onChanged: _evaluatePasswordStrength,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration:
                                    _inputDecoration(
                                      label: t('password'),
                                      icon: Icons.lock_outlined,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          );
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return t('error_password_required');
                                  }
                                  if (value.length < 8) {
                                    return t('error_password_short');
                                  }
                                  return null;
                                },
                              ),

                              // Password strength indicator
                              if (_passwordStrength !=
                                  _PasswordStrength.none) ...[
                                const SizedBox(height: 8),
                                _PasswordStrengthBar(
                                  strength: _passwordStrength,
                                  locale: locale,
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Confirm password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration:
                                    _inputDecoration(
                                      label: t('confirm_password'),
                                      icon: Icons.lock_outlined,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm,
                                          );
                                        },
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return t('error_password_required');
                                  }
                                  if (value != _passwordController.text) {
                                    return t('error_passwords_mismatch');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Terms checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (val) {
                                        setState(
                                          () => _agreedToTerms = val ?? false,
                                        );
                                      },
                                      activeColor: AppTheme.deepPlum,
                                      checkColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _agreedToTerms = !_agreedToTerms,
                                      ),
                                      child: Text(
                                        t('terms_agree'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sign Up button
                              SizedBox(
                                height: 56,
                                child: _isLoading
                                    ? Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          onTap: _handleSignup,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF0F766E),
                                                  Color(0xFFDC2626),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.warmRose
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                t('signup'),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
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
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 300.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 600.ms,
                        delay: 300.ms,
                      ),
                  const SizedBox(height: 24),

                  // Login link
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: t('has_account').split('?').first,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        children: [
                          if (t('has_account').contains('?'))
                            const TextSpan(text: '? '),
                          TextSpan(
                            text: t('has_account').contains('?')
                                ? t('has_account').split('? ').last
                                : '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.softAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.6),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.warmRose),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.warmRose, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: AppTheme.warmRose.withValues(alpha: 0.9),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}

// ── Password Strength ──────────────────────────────────────────────────────

enum _PasswordStrength { none, weak, medium, strong }

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength, required this.locale});

  final _PasswordStrength strength;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final int filledBars;
    final Color color;
    final String label;

    switch (strength) {
      case _PasswordStrength.weak:
        filledBars = 1;
        color = const Color(0xFFDC2626); // Red
        label = AppLocalizations.translate('password_weak', locale);
        break;
      case _PasswordStrength.medium:
        filledBars = 2;
        color = const Color(0xFFF59E0B); // Amber
        label = AppLocalizations.translate('password_medium', locale);
        break;
      case _PasswordStrength.strong:
        filledBars = 3;
        color = const Color(0xFF16A34A); // Green
        label = AppLocalizations.translate('password_strong', locale);
        break;
      default:
        filledBars = 0;
        color = Colors.transparent;
        label = '';
    }

    return Row(
      children: [
        // Bars
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: i < filledBars
                    ? color
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: 12),
        // Label
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
