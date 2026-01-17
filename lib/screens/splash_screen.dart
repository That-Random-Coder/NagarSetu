import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/auth_service.dart';
import '../services/app_state_service.dart';
import 'discover.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Listen to animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    if (_navigated) return;
    _navigated = true;

    // Check if user is logged in and if this is first launch
    final isLoggedIn = await AuthService.isLoggedIn();
    final isFirstLaunch = await AppStateService.isFirstLaunch();

    if (!mounted) return;

    Widget nextScreen;

    if (isLoggedIn) {
      // User is logged in, go to home
      nextScreen = const HomeScreen();
    } else if (isFirstLaunch) {
      // First time user, show discover page
      nextScreen = const DiscoverPage();
      // Mark app as launched so we don't show discover again
      await AppStateService.markAppLaunched();
    } else {
      // Returning user but not logged in, go directly to discover
      // (they've seen it before)
      nextScreen = const DiscoverPage();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          _animationController.stop();
          _navigateToNextScreen();
        },
        child: Center(
          child: Lottie.asset(
            'assets/NagarSetu_Logo.json',
            controller: _animationController,
            fit: BoxFit.contain,
            repeat: false,
            frameRate: FrameRate.max,
            onLoaded: (composition) {
              // Set the animation duration to 3 seconds
              _animationController.duration = const Duration(seconds: 3);
              // Reset to beginning and then play after a 1.5 second delay
              _animationController.reset();
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  _animationController.forward();
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
