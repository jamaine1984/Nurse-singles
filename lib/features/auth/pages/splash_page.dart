import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';

/// Heartbeat ECG animation splash screen.
///
/// Displays an animated ECG line drawing, the app logo, and tagline.
/// After 3 seconds it auto-navigates based on authentication state.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _ecgController;
  late final AnimationController _pulseController;
  bool _showLogo = false;
  bool _showTagline = false;

  @override
  void initState() {
    super.initState();

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Start ECG line drawing
    _ecgController.forward();

    // Show logo after ECG reaches midpoint
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _showLogo = true);

    // Start heart pulse
    _pulseController.repeat(reverse: true);

    // Show tagline
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showTagline = true);

    // Wait and then navigate
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _navigateBasedOnAuth();
  }

  void _navigateBasedOnAuth() {
    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (!mounted) return;
        if (user != null) {
          context.go('/discover');
        } else {
          context.go('/welcome');
        }
      },
      loading: () {
        // Still loading auth state; wait a moment and retry
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _navigateBasedOnAuth();
        });
      },
      error: (_, __) {
        if (mounted) context.go('/welcome');
      },
    );
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F766E), // Deep Plum
              Color(0xFF075985),
              Color(0xFF0F0B15), // Midnight
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── ECG Line Animation ──
            Positioned(
              left: 0,
              right: 0,
              top: size.height * 0.38,
              child: AnimatedBuilder(
                animation: _ecgController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(size.width, 120),
                    painter: _EcgPainter(
                      progress: _ecgController.value,
                      color: AppTheme.warmRose.withValues(alpha: 0.8),
                      glowColor: AppTheme.warmRose.withValues(alpha: 0.3),
                    ),
                  );
                },
              ),
            ),

            // ── Center Content ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Heart icon with pulse
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.15);
                      return Transform.scale(
                        scale: _showLogo ? scale : 0.0,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.warmRose.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.warmRose.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppTheme.warmRose,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Name
                  if (_showLogo)
                    Text(
                      'Nurse Singles',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut),

                  const SizedBox(height: 12),

                  // Tagline
                  if (_showTagline)
                    Text(
                      'Where Night Shifts Meet Heart Shifts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut),
                ],
              ),
            ),

            // ── Bottom loading indicator ──
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: _showTagline
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws an ECG/heartbeat line from left to right.
class _EcgPainter extends CustomPainter {
  _EcgPainter({
    required this.progress,
    required this.color,
    required this.glowColor,
  });

  final double progress;
  final Color color;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = _buildEcgPath(size);
    final metrics = path.computeMetrics().first;
    final visibleLength = metrics.length * progress;
    final extractedPath = metrics.extractPath(0, visibleLength);

    // Draw glow
    final glowPaint = Paint()
      ..color = glowColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(extractedPath, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(extractedPath, linePaint);

    // Draw bright dot at the tip
    if (progress < 1.0) {
      final tangent = metrics.getTangentForOffset(visibleLength);
      if (tangent != null) {
        final dotPaint = Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(tangent.position, 4, dotPaint);

        final corePaint = Paint()..color = Colors.white;
        canvas.drawCircle(tangent.position, 2, corePaint);
      }
    }
  }

  Path _buildEcgPath(Size size) {
    final path = Path();
    final midY = size.height / 2;
    final w = size.width;

    // Flat line -> small bump -> MAJOR SPIKE -> small dip -> flat
    path.moveTo(0, midY);

    // Flat start
    path.lineTo(w * 0.15, midY);

    // Small P-wave bump
    path.quadraticBezierTo(w * 0.18, midY - 8, w * 0.21, midY);

    // Flat to QRS
    path.lineTo(w * 0.30, midY);

    // Q dip
    path.lineTo(w * 0.33, midY + 10);

    // R spike (tall)
    path.lineTo(w * 0.38, midY - 50);

    // S dip
    path.lineTo(w * 0.42, midY + 15);

    // Return to baseline
    path.lineTo(w * 0.45, midY);

    // Flat
    path.lineTo(w * 0.52, midY);

    // T wave
    path.quadraticBezierTo(w * 0.57, midY - 18, w * 0.62, midY);

    // Flat middle
    path.lineTo(w * 0.68, midY);

    // Second heartbeat (smaller)
    // P wave
    path.quadraticBezierTo(w * 0.70, midY - 6, w * 0.72, midY);

    // Flat
    path.lineTo(w * 0.76, midY);

    // QRS
    path.lineTo(w * 0.78, midY + 8);
    path.lineTo(w * 0.82, midY - 35);
    path.lineTo(w * 0.85, midY + 12);
    path.lineTo(w * 0.87, midY);

    // Flat
    path.lineTo(w * 0.90, midY);

    // T wave
    path.quadraticBezierTo(w * 0.93, midY - 12, w * 0.96, midY);

    // Flat end
    path.lineTo(w, midY);

    return path;
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
