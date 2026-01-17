import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../widgets/lottie_loader.dart';
import 'home_screen.dart';

class InfoScreen extends StatefulWidget {
  final String email;
  final String password;
  final String otpCode;

  const InfoScreen({
    super.key,
    required this.email,
    required this.password,
    required this.otpCode,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _submitInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await AuthService.register(
      email: widget.email,
      password: widget.password,
      code: widget.otpCode,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _selectedGender,
      location: _locationController.text.trim(),
      role: 'CITIZEN',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      _showSnackBar('Registration successful!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(
        response.message ?? 'Registration failed. Please try again.',
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Header Animation
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: size.height * 0.4,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 60),
              child: SafeArea(
                child: Center(
                  child: Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_M9p23l.json',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 100,
                      color: Color(0xFF1976D2),
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Form Container
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Tell us about yourself",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please complete your profile to continue",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v!.isEmpty ? "Name is required" : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _phoneController,
                          label: "Phone Number",
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v!.length < 10 ? "Invalid phone number" : null,
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _ageController,
                                label: "Age",
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: _inputDecoration(
                                  "Gender",
                                  Icons.wc_outlined,
                                ),
                                items: _genders
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedGender = v),
                                validator: (v) => v == null ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _locationController,
                          label: "City / Location",
                          icon: Icons.location_on_outlined,
                          validator: (v) =>
                              v!.isEmpty ? "Location is required" : null,
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitInfo,
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
                                    "Done",
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 22),
    );
  }
}
