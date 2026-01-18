import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../widgets/lottie_loader.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Duration kAnimDuration = Duration(milliseconds: 600);
  static const Curve kAnimCurve = Curves.fastLinearToSlowEaseIn;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email first')),
      );
      return;
    }

    setState(() => _otpSent = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
  }

  void _submitReset() {
    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify email first')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully! Login now.'),
            ),
          );

          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: size.height * 0.4,
              color: const Color(0xFFF5F7FA),
              padding: const EdgeInsets.only(bottom: 60),
              child: SafeArea(
                child: Center(
                  child: Lottie.network(
                    'https://assets3.lottiefiles.com/packages/lf20_gjmecwii.json',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: size.height * 0.65),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Reset Password",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your email to receive an OTP and set a new password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                label: "Email Address",
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v!.isEmpty || !v.contains('@'))
                                    ? "Invalid email"
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _otpSent ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE3F2FD),
                                  foregroundColor: const Color(0xFF1976D2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _otpSent ? "Sent" : "Send OTP",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
                          child: !_otpSent
                              ? const SizedBox.shrink()
                              : Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      controller: _otpController,
                                      label: "Enter 5-Digit OTP",
                                      icon: Icons.confirmation_number_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (v) => (v!.length < 4)
                                          ? "Invalid OTP"
                                          : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      controller: _passController,
                                      label: "New Password",
                                      icon: Icons.lock_outline,
                                      isObscure: _obscurePass,
                                      hasSuffix: true,
                                      onSuffixTap: () => setState(
                                        () => _obscurePass = !_obscurePass,
                                      ),
                                      validator: (v) => (v!.length < 6)
                                          ? "Min 6 chars"
                                          : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      controller: _confirmPassController,
                                      label: "Confirm Password",
                                      icon: Icons.verified_user_outlined,
                                      isObscure: _obscureConfirm,
                                      hasSuffix: true,
                                      onSuffixTap: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      validator: (v) {
                                        if (v!.isEmpty) return "Required";
                                        if (v != _passController.text)
                                          return "Passwords do not match";
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const ButtonLoader(size: 24)
                                : const Text(
                                    "Update Password",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
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
