import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  // Theme Constants
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _accentColor = const Color(0xFF00BCD4);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _textColor = const Color(0xFF2D3436);
  final Color _cardColor = Colors.white;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 300 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: _primaryColor,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Collapsible App Bar with gradient
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
                "Privacy Policy",
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
                    colors: [
                      _primaryColor,
                      _accentColor,
                    ],
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
                              Icons.shield_outlined,
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Last Updated & Version Badge ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.update, size: 14, color: _primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                "Last Updated: January 17, 2026",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                "Version 2.0",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Hero Intro Section ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor.withOpacity(0.05),
                            _accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primaryColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.privacy_tip_outlined,
                            size: 48,
                            color: _primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Your Privacy Matters to Us",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "At NagarSetu, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy outlines how we collect, use, store, and safeguard your data when you use our civic engagement platform.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQuickInfoChip(Icons.security, "Secure"),
                              const SizedBox(width: 8),
                              _buildQuickInfoChip(Icons.lock, "Encrypted"),
                              const SizedBox(width: 8),
                              _buildQuickInfoChip(Icons.verified_user, "Trusted"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Table of Contents ---
                    _buildTableOfContents(),
                    const SizedBox(height: 24),

                    // --- Policy Sections ---
                    _buildPolicySection(
                      icon: Icons.person_outline,
                      title: "1. Information We Collect",
                      content: "We collect information you provide directly to us when you create an account, update your profile, submit a civic report, or contact our support team.\n\n"
                          "Personal Information:\n"
                          "• Full Name and Display Name\n"
                          "• Phone Number (with country code)\n"
                          "• Email Address\n"
                          "• Age and Date of Birth\n"
                          "• Gender\n"
                          "• Residential Address (optional)\n\n"
                          "Technical Information:\n"
                          "• Device model and manufacturer\n"
                          "• Operating system and version\n"
                          "• Unique device identifiers (IMEI, UDID)\n"
                          "• IP address and network information\n"
                          "• App version and crash logs",
                    ),

                    _buildPolicySection(
                      icon: Icons.location_on_outlined,
                      title: "2. Location Data Collection",
                      content: "Our application requires access to your device's location services to provide accurate civic reporting functionality.\n\n"
                          "How we use location data:\n"
                          "• Geotagging your civic reports for precise issue identification\n"
                          "• Helping municipal authorities locate and address reported problems\n"
                          "• Providing location-based notifications about issues in your area\n"
                          "• Analyzing geographic patterns to improve city services\n\n"
                          "Your Control:\n"
                          "You can disable location services at any time through your device settings. However, this may limit the functionality of certain features like submitting new reports.",
                    ),

                    _buildPolicySection(
                      icon: Icons.camera_alt_outlined,
                      title: "3. Camera & Media Access",
                      content: "To document civic issues effectively, our app requests access to your device's camera and photo gallery.\n\n"
                          "Usage of Media Access:\n"
                          "• Capturing real-time photos of civic issues (potholes, garbage, etc.)\n"
                          "• Uploading existing photos as evidence\n"
                          "• Recording videos for complex issues (optional)\n"
                          "• Scanning QR codes for quick reporting (future feature)\n\n"
                          "Media Security:\n"
                          "• All images are encrypted during transmission\n"
                          "• Photos are stored on secure cloud servers\n"
                          "• Images are only shared with authorized municipal officials\n"
                          "• Metadata (EXIF data) may be collected for verification purposes",
                    ),

                    _buildPolicySection(
                      icon: Icons.analytics_outlined,
                      title: "4. How We Use Your Data",
                      content: "We process your personal data for legitimate purposes related to civic engagement and service improvement.\n\n"
                          "Primary Uses:\n"
                          "• Verifying your identity and preventing fraudulent reports\n"
                          "• Processing and routing your civic complaints to appropriate authorities\n"
                          "• Sending real-time status updates about your reports\n"
                          "• Notifying you when issues in your area are resolved\n\n"
                          "Secondary Uses:\n"
                          "• Analyzing usage patterns to improve app functionality\n"
                          "• Generating anonymized statistics for city planning\n"
                          "• Conducting research to enhance civic services\n"
                          "• Personalizing your app experience\n"
                          "• Preventing abuse and ensuring platform integrity",
                    ),

                    _buildPolicySection(
                      icon: Icons.share_outlined,
                      title: "5. Data Sharing & Third Parties",
                      content: "We are committed to protecting your data and do not sell your personal information to third parties.\n\n"
                          "We may share your information with:\n"
                          "• Municipal Corporations and Local Government Bodies\n"
                          "• Authorized field workers assigned to resolve reported issues\n"
                          "• Emergency services when public safety is at risk\n"
                          "• Law enforcement agencies when legally required\n\n"
                          "Third-Party Services:\n"
                          "• Cloud storage providers (for secure data storage)\n"
                          "• Analytics services (anonymized data only)\n"
                          "• Push notification services\n"
                          "• Map and location service providers\n\n"
                          "All third-party partners are bound by strict confidentiality agreements.",
                    ),

                    _buildPolicySection(
                      icon: Icons.lock_outline,
                      title: "6. Data Security Measures",
                      content: "We implement industry-standard security measures to protect your personal data.\n\n"
                          "Technical Safeguards:\n"
                          "• 256-bit AES encryption for data at rest\n"
                          "• TLS 1.3 encryption for data in transit\n"
                          "• Regular security audits and penetration testing\n"
                          "• Secure authentication with optional 2FA\n"
                          "• Automated threat detection and monitoring\n\n"
                          "Organizational Measures:\n"
                          "• Strict access controls and role-based permissions\n"
                          "• Employee training on data protection\n"
                          "• Incident response procedures\n"
                          "• Regular backup and disaster recovery testing",
                    ),

                    _buildPolicySection(
                      icon: Icons.timer_outlined,
                      title: "7. Data Retention Policy",
                      content: "We retain your personal data only for as long as necessary to fulfill the purposes outlined in this policy.\n\n"
                          "Retention Periods:\n"
                          "• Account information: Duration of account + 2 years\n"
                          "• Civic reports: 5 years from resolution date\n"
                          "• Images and media: 3 years from upload date\n"
                          "• Transaction logs: 7 years (legal requirement)\n"
                          "• Analytics data: 2 years (anonymized)\n\n"
                          "After these periods, data is securely deleted or anonymized.",
                    ),

                    _buildPolicySection(
                      icon: Icons.gavel_outlined,
                      title: "8. Your Rights",
                      content: "You have several rights regarding your personal data under applicable data protection laws.\n\n"
                          "Your Rights Include:\n"
                          "• Right to Access: Request a copy of your personal data\n"
                          "• Right to Rectification: Correct inaccurate information\n"
                          "• Right to Erasure: Request deletion of your data\n"
                          "• Right to Portability: Receive your data in a portable format\n"
                          "• Right to Object: Object to certain processing activities\n"
                          "• Right to Restrict: Limit how we use your data\n"
                          "• Right to Withdraw Consent: Withdraw consent at any time\n\n"
                          "To exercise any of these rights, please contact our Privacy Officer.",
                    ),

                    _buildPolicySection(
                      icon: Icons.child_care_outlined,
                      title: "9. Children's Privacy",
                      content: "NagarSetu is designed for users aged 13 and above. We do not knowingly collect personal information from children under 13.\n\n"
                          "Parental Guidance:\n"
                          "• Users between 13-18 should have parental consent\n"
                          "• Parents can review their child's information upon request\n"
                          "• We will delete any data collected from children under 13\n\n"
                          "If you believe we have inadvertently collected data from a child under 13, please contact us immediately.",
                    ),

                    _buildPolicySection(
                      icon: Icons.cookie_outlined,
                      title: "10. Cookies & Tracking",
                      content: "Our mobile application and related web services use cookies and similar technologies.\n\n"
                          "Types of Cookies Used:\n"
                          "• Essential Cookies: Required for app functionality\n"
                          "• Analytics Cookies: Help us understand app usage\n"
                          "• Preference Cookies: Remember your settings\n\n"
                          "You can manage cookie preferences through your device settings or browser options.",
                    ),

                    _buildPolicySection(
                      icon: Icons.update_outlined,
                      title: "11. Policy Updates",
                      content: "We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements.\n\n"
                          "How We Notify You:\n"
                          "• In-app notifications for significant changes\n"
                          "• Email notifications to registered users\n"
                          "• Updated 'Last Modified' date on this page\n"
                          "• 30-day notice period for material changes\n\n"
                          "Continued use of the app after changes constitutes acceptance of the updated policy.",
                    ),

                    _buildPolicySection(
                      icon: Icons.public_outlined,
                      title: "12. International Data Transfers",
                      content: "Your data may be transferred to and processed in countries outside your country of residence.\n\n"
                          "Transfer Safeguards:\n"
                          "• Standard Contractual Clauses (SCCs)\n"
                          "• Adequacy decisions where applicable\n"
                          "• Data processing agreements with all vendors\n"
                          "• Compliance with local data protection laws\n\n"
                          "We ensure that any international transfers comply with applicable data protection regulations.",
                    ),

                    const SizedBox(height: 20),

                    // --- Consent Acknowledgment ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[700], size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Consent Acknowledgment",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "By using NagarSetu, you acknowledge that you have read, understood, and agree to this Privacy Policy.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.amber[900],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Contact Section ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor,
                            _accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.support_agent,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Have Questions?",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Our Privacy Team is here to help you with any questions or concerns about your data.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildContactItem(Icons.email_outlined, "privacy@nagarsetu.com"),
                          const SizedBox(height: 12),
                          _buildContactItem(Icons.phone_outlined, "+91 1800-XXX-XXXX"),
                          const SizedBox(height: 12),
                          _buildContactItem(Icons.location_on_outlined, "Mumbai, Maharashtra, India"),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Response Time: Within 48 hours",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Legal Footer ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.balance, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                "Legal Compliance",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "This Privacy Policy complies with the Information Technology Act, 2000, Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011, and other applicable data protection regulations.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "© 2026 NagarSetu. All rights reserved.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildQuickInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContents() {
    final sections = [
      "Information We Collect",
      "Location Data Collection",
      "Camera & Media Access",
      "How We Use Your Data",
      "Data Sharing & Third Parties",
      "Data Security Measures",
      "Data Retention Policy",
      "Your Rights",
      "Children's Privacy",
      "Cookies & Tracking",
      "Policy Updates",
      "International Data Transfers",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                "Table of Contents",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sections.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        "${entry.key + 1}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}