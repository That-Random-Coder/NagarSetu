import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Hide system bars during splash to avoid any bottom divider
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _goToHome() {
    if (_navigated) return;
    _navigated = true;

    // Restore system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Small delay for subtle transition
    Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    // Restore UI when disposing
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _goToHome, // tap to skip
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth * 0.96;
                    final maxHeight = constraints.maxHeight * 0.9;

                    // Play the Lottie once at a larger size and navigate after it completes
                    return SizedBox(
                      width: maxWidth,
                      height: maxHeight,
                      child: Lottie.asset(
                        'assets/NagarSetu_Logo.json',
                        fit: BoxFit.contain,
                        repeat: false,
                        alignment: Alignment.center,
                        width: maxWidth,
                        height: maxHeight,
                        onLoaded: (composition) {
                          Future.delayed(composition.duration, _goToHome);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom white overlay to be extra safe
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Builder(
                builder: (context) {
                  final bottomInset = MediaQuery.of(context).padding.bottom;
                  final overlayHeight = (bottomInset > 0) ? bottomInset : 8.0;
                  return Container(height: overlayHeight, color: Colors.white);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
