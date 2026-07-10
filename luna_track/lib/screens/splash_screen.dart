import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Text animations
  late AnimationController _textController;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineOpacity;

  // Background animation
  late AnimationController _bgController;
  late Animation<double> _bgOpacity;

  // Loading dots
  late AnimationController _dotsController;

  // Glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Background
    _bgController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _bgOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeIn));

    // Logo
    _logoController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    // Glow
    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _glowRadius = Tween<double>(begin: 0, end: 30).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    // Text
    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _titleSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));

    // Loading dots
    _dotsController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();
  }

  Future<void> _startSequence() async {
    // 1. Background
    await Future.delayed(const Duration(milliseconds: 100));
    _bgController.forward();

    // 2. Logo
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // 3. Glow pulse
    await Future.delayed(const Duration(milliseconds: 700));
    _glowController.forward().then((_) => _glowController.reverse());

    // 4. Text
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // 5. Navigate after total 2500ms
    await Future.delayed(const Duration(milliseconds: 1400));
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final loggedIn = await ApiService.isLoggedIn();

    if (!mounted) return;
    Widget destination;
    if (!onboardingDone || !loggedIn) {
      destination = loggedIn ? const OnboardingScreen() : const LoginScreen();
    } else {
      destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _dotsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController, _logoController, _textController,
          _dotsController, _glowController,
        ]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(Colors.white, const Color(0xFFE05D6F),
                      _bgOpacity.value)!,
                  Color.lerp(Colors.white, const Color(0xFFD4497A),
                      _bgOpacity.value)!,
                  Color.lerp(Colors.white, const Color(0xFF9B3A6B),
                      _bgOpacity.value)!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value.clamp(0.0, 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow
                          if (_glowRadius.value > 0)
                            Container(
                              width: 100 + _glowRadius.value,
                              height: 100 + _glowRadius.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                                    .withOpacity(0.15 * (1 - _glowController.value)),
                              ),
                            ),
                          // Logo circle
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text('🌙',
                                  style: TextStyle(fontSize: 48)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App name
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleOpacity.value.clamp(0.0, 1.0),
                      child: const Text(
                        'Luna Track',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Opacity(
                    opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                    child: const Text(
                      'Theo dõi chu kỳ thông minh',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bouncing dots
                  Opacity(
                    opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final delay = i * 0.33;
                        final t = (_dotsController.value - delay).clamp(0.0, 1.0);
                        final bounce = (t < 0.5
                            ? 2 * t * t
                            : -1 + (4 - 2 * t) * t);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Transform.translate(
                            offset: Offset(0, -8 * bounce),
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
