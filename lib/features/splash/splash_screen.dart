/// Initial splash screen shown when the app launches, navigating to Home automatically.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/services/journey_service.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    debugPrint('[SplashScreen] App launched. Reloading SharedPreferences and checking active journey...');
    final restoredState = await JourneyService.instance.restoreActiveJourney();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final state = JourneyService.instance.currentJourney ?? restoredState;

    if (state != null) {
      debugPrint('[SplashScreen] Active journey found (${state.destinationPlace.name}). Navigating directly to ActiveJourneyScreen.');
      Navigator.of(context).pushReplacementNamed(
        AppRouter.activeJourney,
        arguments: {
          'destinationPlace': state.destinationPlace,
          'alarmThresholdMeters': state.alarmThresholdMeters,
          'isVibrationEnabled': state.isVibrationEnabled,
        },
      );
    } else {
      debugPrint('[SplashScreen] No active journey found. Navigating to HomeScreen.');
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF6FAFF),
                  Color(0xFFE7F2FF),
                  Color(0xFFDCEEFF),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 120,
                  left: 40,
                  child: _FloatingDot(
                    size: 18,
                    color: const Color(0xFFB9D9FF),
                    offset: math.sin(t * math.pi * 2) * 8,
                  ),
                ),
                Positioned(
                  top: 220,
                  right: 58,
                  child: _FloatingDot(
                    size: 24,
                    color: const Color(0xFFD7E8FF),
                    offset: math.cos(t * math.pi * 2) * 12,
                  ),
                ),
                Positioned(
                  bottom: 180,
                  left: 70,
                  child: _FloatingDot(
                    size: 14,
                    color: const Color(0xFF9FC6FF),
                    offset: math.sin(t * math.pi * 2 + 1.2) * 10,
                  ),
                ),
                Positioned(
                  bottom: 110,
                  right: 90,
                  child: _FloatingDot(
                    size: 28,
                    color: const Color(0xFFCFE5FF),
                    offset: math.cos(t * math.pi * 2 + 0.7) * 8,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A5B8DFF),
                                blurRadius: 40,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Norivo',
                                style: AppTextStyles.displayLarge(context)
                                    .copyWith(
                                      color: const Color(0xFF1D4ED8),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.2,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your calm journey starts here',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: const Color(0xFF5B6B86),
                                  fontSize: 15,
                                  letterSpacing: 0.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 170,
                                child: CustomPaint(
                                  painter: _CurvedLoadingPainter(progress: t),
                                  size: const Size(170, 28),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({
    required this.size,
    required this.color,
    required this.offset,
  });

  final double size;
  final Color color;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedLoadingPainter extends CustomPainter {
  const _CurvedLoadingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8CC2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.2,
        size.width * 0.5,
        size.height / 2,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.8,
        size.width,
        size.height / 2,
      );

    canvas.drawPath(path, paint);

    final metric = path.computeMetrics().first;
    final distance = metric.length * progress;
    final tangent = metric.getTangentForOffset(distance);
    if (tangent == null) {
      return;
    }

    final innerPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final offset = tangent.position;
    canvas.drawCircle(offset, 6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
