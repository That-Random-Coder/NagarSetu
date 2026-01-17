import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
          _goToHome();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const HomeScreen(),
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
          _goToHome();
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
