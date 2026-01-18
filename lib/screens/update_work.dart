import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/worker_service.dart';
import 'in_app_camera.dart';

class UpdateWorkPage extends StatefulWidget {
  final String taskTitle;
  final String taskAddress;
  final String currentStatus;
  final String? issueId;

  const UpdateWorkPage({
    super.key,
    required this.taskTitle,
    required this.taskAddress,
    required this.currentStatus,
    this.issueId,
  });

  @override
  State<UpdateWorkPage> createState() => _UpdateWorkPageState();
}

class _UpdateWorkPageState extends State<UpdateWorkPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedStatus;
  File? _selectedImage;

  // Theme Color
  final Color _primaryColor = const Color(0xFF1976D2);

  final List<String> _statusOptions = [
    "Pending",
    "In Progress",
    "Resolved",
    "On Hold",
  ];

  @override
  void initState() {
    super.initState();
    // Set initial status based on passed data, or default to first option
    _selectedStatus = _statusOptions.contains(widget.currentStatus)
        ? widget.currentStatus
        : _statusOptions[0];
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // --- Updated Logic: Open Camera Directly ---
  Future<void> _pickImage() async {
    // Request Camera Permission directly
    final status = await Permission.camera.request();

    if (status.isGranted) {
      // Navigate directly to InAppCameraScreen
      // (Your custom camera screen already has a gallery picker button inside it)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InAppCameraScreen()),
      );

      if (result != null && result is File) {
        setState(() {
          _selectedImage = result;
        });
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        'Camera Permission Required',
        'Please enable camera permission to capture proof of work.',
      );
    }
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

  bool _isSubmitting = false;

  /// Convert display status to API stage enum
  String _getApiStage(String displayStatus) {
    switch (displayStatus) {
      case 'Pending':
        return 'PENDING';
      case 'In Progress':
        return 'IN_PROGRESS';
      case 'Resolved':
        return 'RESOLVED';
      case 'On Hold':
        return 'RECONSIDERED';
      default:
        return 'PENDING';
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (widget.issueId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Issue ID is missing. Cannot update status."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Validation: Proof is required if Status is "Resolved"
      if (_selectedStatus == 'Resolved' && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please upload proof of work to resolve this issue."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      final stage = _getApiStage(_selectedStatus!);
      final remarks = _remarksController.text.trim();

      final result = await WorkerService.updateStage(
        issueId: widget.issueId!,
        stage: stage,
        description: remarks.isNotEmpty ? remarks : null,
        proofImage: _selectedImage,
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedStatus == 'Resolved'
                  ? "Issue marked as resolved successfully!"
                  : "Status updated to $_selectedStatus successfully!",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? "Failed to update status. Please try again.",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if proof is technically required for UI hint (optional)
    bool isProofRequired = _selectedStatus == 'Resolved';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Update Status",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Task Summary Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.taskAddress,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Work Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),

              // --- Status Dropdown ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
                    items: _statusOptions.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Remarks Text Field ---
              TextFormField(
                controller: _remarksController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Add remarks about the work done...",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter some remarks';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    "Proof of Work",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (isProofRequired)
                    const Text(
                      " *",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Photo Upload Section ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200, // Taller to fit image
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              // Remove Button
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
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: _primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to upload photo",
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (!isProofRequired)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "(Optional for Pending)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryColor.withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit Update",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }
}
