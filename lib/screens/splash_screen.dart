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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _playCount = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Create controller to control playback and manage repeat count
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _playCount++;
        if (_playCount < 2) {
          // Play second time
          _controller.forward(from: 0);
        } else {
          _navigateToNextScreen();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;
    final maxHeight = size.height * 0.7;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          _controller.stop();
          _navigateToNextScreen();
        }, // allow tap to skip
        child: Center(
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: Lottie.asset(
              'assets/NagarSetu_Logo.json',
              controller: _controller,
              fit: BoxFit.contain,
              repeat: false,
              frameRate: FrameRate.max,
              onLoaded: (composition) {
                // Use composition duration and start controller; controller will manage repeats
                _controller.duration = composition.duration;
                _playCount = 0;
                _controller.forward(from: 0);
              },
            ),
          ),
        ),
      ),
    );
  }
}
