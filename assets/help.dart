import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFAQScreen extends StatefulWidget {
  const HelpFAQScreen({super.key});

  @override
  State<HelpFAQScreen> createState() => _HelpFAQScreenState();
}

class _HelpFAQScreenState extends State<HelpFAQScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _queryFocusNode = FocusNode();
  
  // Theme Color
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Hardcoded FAQs Data
  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I report a civic issue?",
      "answer": "To report an issue, navigate to the Home screen and tap the '+' button. Select the category (e.g., Pothole, Garbage), upload a photo, add a description, and submit."
    },
    {
      "question": "Is NagarSetu free to use?",
      "answer": "Yes! The app is completely free for all citizens to help improve our city together."
    },
    {
      "question": "How can I track my complaint status?",
      "answer": "Go to the 'My Activity' tab. There you will see a list of your submitted reports along with their current status (Pending, In Progress, Resolved)."
    },
    {
      "question": "Can I edit a report after submitting?",
      "answer": "Currently, you cannot edit a report once submitted to ensure data integrity. However, you can delete it and submit a new one if the status is still 'Pending'."
    },
     {
      "question": "Who sees my reports?",
      "answer": "Your reports are directly forwarded to the relevant municipal department based on the location and category you selected."
    },
  ];

  @override
  void initState() {
    super.initState();
    _queryFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_queryFocusNode.hasFocus) {
      // Scroll to the bottom when the text field is focused
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _queryFocusNode.removeListener(_onFocusChange);
    _queryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    if (_formKey.currentState!.validate()) {
      final String query = _queryController.text;
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'nagarsetu.care@gmail.com',
        query: _encodeQueryParameters({
          'subject': 'NagarSetu Support Query',
          'body': query,
        }),
      );

      try {
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening email client...'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _queryController.clear();
            FocusScope.of(context).unfocus();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open email client. Please email us at nagarsetu.care@gmail.com'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Help & FAQs",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: FAQs ---
              Text(
                "Frequently Asked Questions",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // FAQ List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return _buildFAQTile(_faqs[index]);
                },
              ),

              const SizedBox(height: 32),
              
              // --- Section 2: Contact Form ---
              Text(
                "Still need help?",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Type your query below and our support team will get back to you.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              Container(
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
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _queryController,
                        focusNode: _queryFocusNode,
                        maxLines: 5,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Describe your issue or question...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          fillColor: _backgroundColor,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your query';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitQuery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Submit Query",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Extra space at bottom
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _primaryColor,
          collapsedIconColor: Colors.grey[600],
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            faq['question']!,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          children: [
            Text(
              faq['answer']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}