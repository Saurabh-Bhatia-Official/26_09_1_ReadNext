import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'main_shell.dart';

/// Corporate Splash Screen displayed when opening the app/site.
/// Features a crisp white executive background, the ReadNext software logo,
/// animated progress bar, dynamic status updates, and a smooth fade transition to the workspace.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1400),
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.95, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceedToWorkspace();
      }
    });

    _controller.forward();
  }

  void _proceedToWorkspace() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToWorkspace,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              // Subtle Ambient Corporate Highlight
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 560,
                    height: 560,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.04),
                          const Color(0xFF0284C7).withValues(alpha: 0.01),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Skip Action in Top-Right
              Positioned(
                top: 24,
                right: 24,
                child: SafeArea(
                  child: TextButton.icon(
                    onPressed: _proceedToWorkspace,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text(
                      'Skip to App',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // Central Brand & Progress Area
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Software Logo Container
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppConstants.appLogo,
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.picture_as_pdf,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 28),

                            // App Name
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Tagline
                            const Text(
                              'Read. Manage. Move Forward.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Corporate Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF0284C7)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Enterprise Edition • 100% Client-Side Privacy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Progress Bar & Dynamic Status Indicator
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final progress = _progressAnimation.value;
                                String statusText;
                                if (progress < 0.35) {
                                  statusText = 'Initializing secure PDF engine...';
                                } else if (progress < 0.70) {
                                  statusText = 'Loading client-side toolchain & workspace...';
                                } else if (progress < 0.95) {
                                  statusText = 'Applying corporate security policies...';
                                } else {
                                  statusText = 'Ready';
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 240,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(99),
                                        child: SizedBox(
                                          height: 4,
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1D4ED8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      statusText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Footer
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${AppConstants.developerName} • v${AppConstants.appVersion}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
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
}
