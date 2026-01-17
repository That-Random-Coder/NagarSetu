import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../widgets/lottie_loader.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'home_page_worker.dart';
import 'info.dart';
import 'reset.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Animation Constants ---
  static const Duration kAnimDuration = Duration(milliseconds: 600);
  static const Curve kAnimCurve = Curves.fastLinearToSlowEaseIn;

  // State variables
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isSendingOtp = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleMode(bool isLogin) {
    if (_isLogin != isLogin) {
      setState(() {
        _isLogin = isLogin;
        _formKey.currentState?.reset();
        _otpSent = false;
        _otpController.clear();
        _obscurePassword = true;
      });
    }
  }

  /// Check if email contains 'worker' keyword (case-insensitive)
  bool _isWorkerEmail(String email) => email.toLowerCase().contains('worker');

  /// Get the actual email to send to backend (without 'worker' keyword)
  String _getActualEmail(String email) {
    if (!_isWorkerEmail(email)) return email;
    // Remove 'worker' from email (case-insensitive)
    return email.replaceAll(RegExp(r'worker', caseSensitive: false), '');
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email first');
      return;
    }

    setState(() => _isSendingOtp = true);
    // Send OTP to actual email (without 'worker' keyword)
    final actualEmail = _getActualEmail(email);
    final response = await AuthService.getCode(email: actualEmail);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (response.success) {
      setState(() => _otpSent = true);
      _showSnackBar(response.message ?? 'OTP sent to your email!');
    } else {
      _showSnackBar(response.message ?? 'Failed to send OTP');
    }
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_isLogin && !_otpSent) {
      _showSnackBar('Please verify your email by sending an OTP first.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final isWorker = _isWorkerEmail(email);
    final actualEmail = _getActualEmail(email);

    if (_isLogin) {
      // Login with AuthService using actual email (without 'worker')
      final response = await AuthService.login(
        email: actualEmail,
        password: _passwordController.text,
        isWorker: isWorker,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        // Navigate to appropriate home screen based on worker status
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isWorker ? const WorkerHomePage() : const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        _showSnackBar(response.message ?? 'Login failed. Please try again.');
      }
    } else {
      // Sign up - go to info screen with original email (keeps 'worker' for detection)
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InfoScreen(
            email: email, // Pass original email so InfoScreen can detect worker
            password: _passwordController.text,
            otpCode: _otpController.text.trim(),
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // --- Top Section: Animation ---
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: Container(
                height: size.height * 0.5,
                color: const Color(0xFFF5F7FA),
                padding: const EdgeInsets.only(bottom: 60),
                child: SafeArea(
                  child: Center(
                    child: Lottie.asset(
                      'assets/animation.json', // Updated to use your local asset
                      renderCache: RenderCache.drawingCommands,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_city_rounded,
                              size: 80,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "NagarSetu",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Bottom Section: Form Card ---
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: RepaintBoundary(
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height * 0.6),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 30,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: kAnimDuration,
                    curve: kAnimCurve,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Custom Toggle
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(27),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  alignment: _isLogin
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  duration: kAnimDuration,
                                  curve: kAnimCurve,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildToggleText(
                                      "Log In",
                                      _isLogin,
                                      () => _toggleMode(true),
                                    ),
                                    _buildToggleText(
                                      "Sign Up",
                                      !_isLogin,
                                      () => _toggleMode(false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildAuthForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleText(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: kAnimDuration,
            curve: kAnimCurve,
            style: TextStyle(
              color: isActive ? const Color(0xFF1976D2) : Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
              ),
              AnimatedContainer(
                duration: kAnimDuration,
                curve: kAnimCurve,
                width: _isLogin ? 0 : 116,
                height: 56,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 0,
                    maxWidth: 116,
                    maxHeight: 56,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 104,
                        height: 56,
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: ElevatedButton(
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE3F2FD),
                              foregroundColor: const Color(0xFF1976D2),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSendingOtp
                                ? const ButtonLoader(size: 18)
                                : Text(
                                    _otpSent ? "Resend" : "Send OTP",
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          AnimatedSize(
            duration: kAnimDuration,
            curve: kAnimCurve,
            alignment: Alignment.topCenter,
            child: (_isLogin || !_otpSent)
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _otpController,
                        label: "Enter 5-Digit OTP",
                        icon: Icons.confirmation_number_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (value == null || value.length < 4)
                            ? 'Invalid OTP'
                            : null,
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _passwordController,
            label: _isLogin ? "Password" : "Enter Password",
            icon: Icons.lock_outline,
            isObscure: _obscurePassword,
            hasSuffix: true,
            onSuffixTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) =>
                (value == null || value.length < 6) ? 'Min 6 characters' : null,
          ),

          AnimatedSize(
            duration: kAnimDuration,
            curve: kAnimCurve,
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: _isLogin ? null : 0,
              child: AnimatedOpacity(
                duration: kAnimDuration,
                curve: Curves.easeOut,
                opacity: _isLogin ? 1.0 : 0.0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResetPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF1976D2),
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF1976D2).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const ButtonLoader(size: 24)
                  : AnimatedSwitcher(
                      duration: kAnimDuration,
                      child: Text(
                        _isLogin ? "Login" : "Sign Up",
                        key: ValueKey<String>(_isLogin ? "Login" : "Sign Up"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    bool hasSuffix = false,
    VoidCallback? onSuffixTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 22),
        suffixIcon: hasSuffix
            ? IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                  size: 22,
                ),
                onPressed: onSuffixTap,
              )
            : null,
      ),
    );
  }
}
