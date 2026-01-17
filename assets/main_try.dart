import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'help.dart'; // CHANGED: Import your help file here

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        primaryColor: const Color(0xFF2196F3),
        useMaterial3: true,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

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
        // Navigate to Home page after animation completes
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/NagarSetu_Logo.json',
          controller: _animationController,
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
          repeat: false,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        // CHANGED: Added Help Button to AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help & FAQs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpFAQScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Home Page!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            // CHANGED: Added a prominent button to access Help
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpFAQScreen()),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text("Open Help & Support"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}