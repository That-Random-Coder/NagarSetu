import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/worker_service.dart';
import '../services/supervisor_service.dart';
import '../widgets/lottie_loader.dart';
import 'home_screen.dart';
import 'home_page_worker.dart';
import 'home_page_supervisor.dart';

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

  /// Check if email contains 'worker' keyword (case-insensitive)
  bool get isWorkerEmail => email.toLowerCase().contains('worker');

  /// Check if email contains 'supervisor' keyword (case-insensitive)
  bool get isSupervisorEmail => email.toLowerCase().contains('supervisor');

  /// Get the actual email to send to backend (without 'worker' or 'supervisor' keyword)
  String get actualEmail {
    String result = email;
    if (isWorkerEmail) {
      result = result.replaceAll(RegExp(r'worker', caseSensitive: false), '');
    }
    if (isSupervisorEmail) {
      result = result.replaceAll(
        RegExp(r'supervisor', caseSensitive: false),
        '',
      );
    }
    return result;
  }

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  // Date of Birth
  DateTime? _selectedDateOfBirth;

  // Location data
  double? _latitude;
  double? _longitude;
  String? _cityName;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  /// Calculate age from date of birth
  int? get _calculatedAge {
    if (_selectedDateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDateOfBirth!.year;
    if (now.month < _selectedDateOfBirth!.month ||
        (now.month == _selectedDateOfBirth!.month &&
            now.day < _selectedDateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Pick date of birth using calendar
  Future<void> _pickDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _selectedDateOfBirth ?? DateTime(now.year - 18);
    final DateTime firstDate = DateTime(1920);
    final DateTime lastDate = DateTime(now.year - 10); // At least 10 years old

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  /// Pick location using GPS and reverse geocoding
  Future<void> _pickLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled. Please enable them.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied.');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permissions are permanently denied. Please enable in settings.',
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocoding to get city name
      final cityName = await _getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _cityName = cityName;
          _locationController.text = cityName ?? 'Unknown Location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        _showSnackBar('Failed to get location. Please try again.');
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Get city name from coordinates using Nominatim (OpenStreetMap)
  Future<String?> _getCityFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'NagarSetu/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Prioritize locality/suburb for neighborhood names like Mahim, Bhandup
          final locality =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['locality'] ??
              address['village'] ??
              address['town'] ??
              address['city_district'] ??
              address['city'] ??
              address['municipality'] ??
              address['county'] ??
              address['state_district'] ??
              address['state'];
          return locality?.toString();
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return null;
  }

  Future<void> _submitInfo() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date of birth
    if (_selectedDateOfBirth == null) {
      _showSnackBar('Please select your date of birth');
      return;
    }

    setState(() => _isLoading = true);

    // Check user type based on email
    final bool isWorker = widget.isWorkerEmail;
    final bool isSupervisor = widget.isSupervisorEmail;
    // Get the actual email without keywords
    final String actualEmail = widget.actualEmail;

    // Debug logging
    print('=== REGISTRATION DEBUG ===');
    print('Original Email: ${widget.email}');
    print('Is Worker: $isWorker');
    print('Is Supervisor: $isSupervisor');
    print('Actual Email (sent to API): $actualEmail');
    print('Location: $_cityName (lat: $_latitude, lng: $_longitude)');
    print('Age: $_calculatedAge');
    print(
      'Using Service: ${isSupervisor ? "SupervisorService" : (isWorker ? "WorkerService" : "AuthService")}',
    );

    bool success = false;
    String? errorMessage;

    if (isSupervisor) {
      // Use SupervisorService for supervisor registration
      print('Calling SupervisorService.register()...');
      final response = await SupervisorService.register(
        email: actualEmail,
        password: widget.password,
        code: widget.otpCode,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        age: _calculatedAge,
        gender: _selectedGender,
        location: _cityName ?? _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      success = response.success;
      errorMessage = response.message;
      print(
        'SupervisorService.register() result: success=$success, message=$errorMessage',
      );
    } else if (isWorker) {
      // Use WorkerService for worker registration
      print('Calling WorkerService.register()...');
      final response = await WorkerService.register(
        email: actualEmail,
        password: widget.password,
        code: widget.otpCode,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        age: _calculatedAge,
        gender: _selectedGender,
        location: _cityName ?? _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      success = response.success;
      errorMessage = response.message;
      print(
        'WorkerService.register() result: success=$success, message=$errorMessage',
      );
    } else {
      // Use AuthService for citizen registration
      print('Calling AuthService.register()...');
      final response = await AuthService.register(
        email: actualEmail,
        password: widget.password,
        code: widget.otpCode,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        age: _calculatedAge,
        gender: _selectedGender,
        location: _cityName ?? _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        role: 'CITIZEN',
        isWorker: false,
      );
      success = response.success;
      errorMessage = response.message;
      print(
        'AuthService.register() result: success=$success, message=$errorMessage',
      );
    }

    print('=== END REGISTRATION DEBUG ===');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Registration successful!');
      // Navigate to appropriate home screen based on user type
      Widget homeScreen;
      if (isSupervisor) {
        homeScreen = const AdminHomePage();
      } else if (isWorker) {
        homeScreen = const WorkerHomePage();
      } else {
        homeScreen = const HomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => homeScreen),
        (route) => false,
      );
    } else {
      _showSnackBar(errorMessage ?? 'Registration failed. Please try again.');
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

                        // Date of Birth and Gender Row
                        Row(
                          children: [
                            Expanded(flex: 3, child: _buildDateOfBirthPicker()),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
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

                        // Location picker with GPS button
                        _buildLocationPicker(),
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

  /// Date of Birth picker widget
  Widget _buildDateOfBirthPicker() {
    final String displayText = _selectedDateOfBirth != null
        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
        : 'DOB';

    return InkWell(
      onTap: _pickDateOfBirth,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedDateOfBirth == null
                ? Colors.grey.shade300
                : const Color(0xFF1976D2),
            width: _selectedDateOfBirth == null ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, color: const Color(0xFF1976D2), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: _selectedDateOfBirth != null
                      ? Colors.black87
                      : Colors.grey[400],
                  fontSize: 14,
                  fontWeight: _selectedDateOfBirth != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (_calculatedAge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_calculatedAge yrs',
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Location picker with GPS button
  Widget _buildLocationPicker() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _locationController,
            readOnly: true,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'City / Location',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1976D2),
                size: 22,
              ),
              suffixIcon: _latitude != null && _longitude != null
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  : null,
            ),
            validator: (v) => v!.isEmpty ? "Location is required" : null,
            onTap: _pickLocation,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoadingLocation ? null : _pickLocation,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
