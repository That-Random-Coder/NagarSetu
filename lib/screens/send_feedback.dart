import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // State Variables
  String _selectedCategory = 'Suggestion';
  int _rating = 0;
  bool _isLoading = false;

  // Theme Colors
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _accentColor = const Color(0xFF00BCD4);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _textColor = const Color(0xFF2D3436);

  // Email Configuration
  final String _feedbackEmail = 'nagarsetu.care@gmail.com';

  final List<String> _categories = [
    'Suggestion',
    'Bug Report',
    'Feature Request',
    'Complaint',
    'Appreciation',
    'General Inquiry',
    'Other'
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Future<void> _sendEmail() async {
    final String subject = Uri.encodeComponent('[$_selectedCategory] Feedback from NagarSetu App');
    final String body = Uri.encodeComponent(
      '''
Hello NagarSetu Team,

I would like to share my feedback:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 FEEDBACK DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 Name: ${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Not provided'}

📧 Email: ${_emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'Not provided'}

📂 Category: $_selectedCategory

⭐ Rating: $_rating/5 (${_getRatingText()})

💬 Message:
${_messageController.text.trim()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sent via NagarSetu Mobile App
Date: ${DateTime.now().toString().split('.')[0]}
      '''
    );

    final Uri emailUri = Uri.parse('mailto:$_feedbackEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          _showErrorSnackbar('Could not open email app. Please send email manually to $_feedbackEmail');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Copy Email',
          textColor: Colors.white,
          onPressed: () {
            // User can manually copy the email
          },
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              "Email App Opened!",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your feedback email has been prepared. Please send it from your email app to complete the submission.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, color: _primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _feedbackEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Stay Here", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Go Back", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text("Please select a rating", style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Send email
      _sendEmail().then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Collapsible App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Send Feedback",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryColor, _accentColor],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.feedback_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Card ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor.withOpacity(0.05), _accentColor.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _primaryColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.mail_outline, size: 40, color: _primaryColor),
                          const SizedBox(height: 12),
                          Text(
                            "We Value Your Opinion",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your feedback helps us improve NagarSetu and serve you better. Share your thoughts, report issues, or suggest new features.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.email, size: 16, color: _primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  _feedbackEmail,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Rating Section (FIXED OVERFLOW) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rate_rounded, color: Colors.amber[400], size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Rate Your Experience",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _textColor, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            // CHANGED: Use spaceEvenly to distribute stars automatically
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () => setState(() => _rating = index + 1),
                                // REMOVED: Padding wrapper to prevent fixed width overflow
                                child: AnimatedScale(
                                  scale: index < _rating ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: index < _rating ? Colors.amber.withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: index < _rating ? Colors.amber[400] : Colors.grey[300],
                                      size: 36,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _getRatingText(),
                              key: ValueKey(_rating),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: _rating > 0 ? FontWeight.w600 : FontWeight.normal,
                                color: _rating > 0 ? _primaryColor : Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Personal Info Section ---
                    Text(
                      "Your Information (Optional)",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _textColor, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: "Your Name",
                              prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Your Email (for follow-up)",
                        prefixIcon: Icon(Icons.email_outlined, color: _primaryColor),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Category Dropdown ---
                    Text("Feedback Type", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _textColor, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
                          items: _categories.map((String category) {
                            IconData icon;
                            switch (category) {
                              case 'Suggestion':
                                icon = Icons.lightbulb_outline;
                                break;
                              case 'Bug Report':
                                icon = Icons.bug_report_outlined;
                                break;
                              case 'Feature Request':
                                icon = Icons.add_circle_outline;
                                break;
                              case 'Complaint':
                                icon = Icons.report_problem_outlined;
                                break;
                              case 'Appreciation':
                                icon = Icons.thumb_up_outlined;
                                break;
                              case 'General Inquiry':
                                icon = Icons.help_outline;
                                break;
                              default:
                                icon = Icons.more_horiz;
                            }
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(icon, size: 20, color: _primaryColor),
                                  const SizedBox(width: 12),
                                  Text(category, style: GoogleFonts.poppins()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Message Input ---
                    Text("Your Message", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _textColor, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: "Tell us more about your experience, issue, or suggestion...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your message';
                        if (value.length < 10) return 'Message is too short (min 10 characters)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Info Card ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Clicking submit will open your email app with the feedback pre-filled. Simply send the email to complete.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: _primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 22),
                                  const SizedBox(width: 10),
                                  Text("Submit Feedback", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Alternative Contact ---
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final Uri emailUri = Uri.parse('mailto:$_feedbackEmail');
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          }
                        },
                        icon: Icon(Icons.alternate_email, size: 18, color: Colors.grey[600]),
                        label: Text(
                          "Or email us directly",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}