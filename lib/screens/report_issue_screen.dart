import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'in_app_camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/lottie_loader.dart';
import '../services/ai_service.dart';
import '../services/issue_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  int _selectedIssueType = 0;
  int _selectedCriticality = 1;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final MapController _mapController = MapController();
  bool _isSubmitting = false;
  String _locationAddress = '';
  LatLng _currentLocation = const LatLng(28.6139, 77.2090);
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090);
  bool _isLoadingLocation = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Title generation state
  bool _autoGenerateTitle = true;
  bool _isGeneratingTitle = false;

  late SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;

  final List<Map<String, dynamic>> issueTypes = [
    {'icon': Icons.add_road, 'label': 'ROAD'},
    {'icon': Icons.water_drop_outlined, 'label': 'WATER'},
    {'icon': Icons.delete_outline, 'label': 'GARBAGE'},
    {'icon': Icons.directions_car, 'label': 'VEHICLE'},
    {'icon': Icons.lightbulb_outline, 'label': 'STREETLIGHT'},
    {'icon': Icons.more_horiz, 'label': 'OTHER'},
  ];

  final List<String> criticalityLevels = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _descriptionController.dispose();
    _titleController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _descriptionController.clear();
      _titleController.clear();
      _selectedImage = null;
      _selectedIssueType = 0;
      _selectedCriticality = 1;
      _autoGenerateTitle = true;
    });
  }

  Future<void> _initSpeech() async {
    _speech = SpeechToText();
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (val) {},
        onError: (val) {},
      );
    } catch (e) {
      _speechAvailable = false;
    }
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        if (!_speechAvailable) {
          await _initSpeech();
        }
        if (_speechAvailable) {
          setState(() {
            _isListening = true;
          });
          _speech.listen(
            onResult: (result) {
              setState(() {
                _descriptionController.text = result.recognizedWords;
                _descriptionController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _descriptionController.text.length),
                );
              });
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(
          'Microphone Permission Required',
          'Please enable microphone permission to use speech-to-text.',
        );
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _generateTitle() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingTitle = true;
    });

    try {
      final title = await AIService.instance.generateIssueTitle(
        description: _descriptionController.text,
        issueType: issueTypes[_selectedIssueType]['label'],
        criticality: criticalityLevels[_selectedCriticality],
      );

      if (title != null && mounted) {
        setState(() {
          _titleController.text = title;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingTitle = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final status = await Permission.location.request();

    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(_currentLocation, 15.0);
        await _getAddressFromCoordinates(_currentLocation);
      } catch (e) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationError();
      }
    } else {
      setState(() {
        _isLoadingLocation = false;
      });
      _showPermissionDeniedDialog(
        'Location Permission Required',
        'Please enable location permission to access your location.',
      );
    }
  }

  /// Get locality/suburb name from coordinates using Nominatim (OpenStreetMap)
  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
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
          setState(() {
            _locationAddress = locality?.toString() ?? 'Unknown location';
          });
          return;
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    setState(() {
      _locationAddress =
          'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
    });
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to get current location'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPermissionDeniedDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue[600]),
                ),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InAppCameraScreen(),
                      ),
                    );
                    if (result != null && result is File) {
                      setState(() {
                        _selectedImage = result;
                      });
                    }
                  } else if (status.isPermanentlyDenied) {
                    _showPermissionDeniedDialog(
                      'Camera Permission Required',
                      'Please enable camera permission to take photos.',
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue[600]),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  PermissionStatus galleryStatus;
                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                    galleryStatus = await Permission.photos.request();
                  } else {
                    galleryStatus = await Permission.storage.request();
                  }

                  if (galleryStatus.isGranted) {
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1600,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open gallery'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else if (galleryStatus.isPermanentlyDenied) {
                    _showPermissionDeniedDialog(
                      'Storage Permission Required',
                      'Please enable storage permission to pick photos.',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitReport() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo of the issue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _autoGenerateTitle
                ? 'Please generate a title using AI'
                : 'Please enter a title for your issue',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _submitToApi();
  }

  Future<void> _submitToApi() async {
    setState(() {
      _isSubmitting = true;
    });

    final result = await IssueService.createIssue(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: issueTypes[_selectedIssueType]['label'],
      criticality: criticalityLevels[_selectedCriticality],
      location: _locationAddress.isNotEmpty
          ? _locationAddress
          : 'Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}',
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      image: _selectedImage!,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (result.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(
          title: 'Issue Reported!',
          message:
              'Your issue has been reported successfully. You will be notified once it is acknowledged.',
          onDismiss: () {
            Navigator.pop(context); // Close only the dialog
            _resetForm(); // Reset form to allow new submission
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to report issue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report an Issue',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIssueTypeSection(),
              const SizedBox(height: 24),
              _buildAddMediaSection(),
              const SizedBox(height: 24),
              _buildDescriptionSection(),
              const SizedBox(height: 24),
              _buildTitleSection(),
              const SizedBox(height: 24),
              _buildCriticalitySection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issue Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: issueTypes.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedIssueType == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIssueType = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      issueTypes[index]['icon'],
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issueTypes[index]['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final status = await Permission.camera.request();
            if (status.isGranted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InAppCameraScreen(),
                ),
              );
              if (result != null && result is File) {
                setState(() {
                  _selectedImage = result;
                });
              }
            } else if (status.isDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Camera permission is required to take photos.',
                  ),
                ),
              );
            } else if (status.isPermanentlyDenied) {
              _showPermissionDeniedDialog(
                'Camera Permission Required',
                'Please enable camera permission to take photos.',
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          _selectedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Photo/Video',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a photo or video to help us understand\nthe issue better.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Upload',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 8),
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.blue[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Issue Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                Text(
                  'Auto-generate',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _autoGenerateTitle,
                  onChanged: (value) {
                    setState(() {
                      _autoGenerateTitle = value;
                      if (value) {
                        _titleController.clear();
                      }
                    });
                  },
                  activeColor: Colors.blue[600],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_autoGenerateTitle) ...[
          // AI Generate Button
          GestureDetector(
            onTap: _isGeneratingTitle ? null : _generateTitle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: _isGeneratingTitle
                  ? const Center(child: ButtonLoader(size: 24))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generate Title from Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_titleController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _titleController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _titleController.clear();
                      });
                    },
                    child: Icon(
                      Icons.refresh,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // Manual Title Entry
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _titleController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Enter a title for your issue...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(Icons.title, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCriticalitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Criticality',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(criticalityLevels.length, (index) {
            final isSelected = _selectedCriticality == index;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCriticality = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[600] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    criticalityLevels[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            GestureDetector(
              onTap: _getCurrentLocation,
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 18, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      // Get locality name for the dropped pin location
                      _getAddressFromCoordinates(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nagarsetu.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.blue[600],
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoadingLocation)
                  Container(
                    color: Colors.white.withValues(alpha: 0.7),
                    child: const Center(child: LottieLoader(size: 80)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap on the map to select a different location',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const ButtonLoader(size: 24)
            : const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
