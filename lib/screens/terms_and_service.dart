import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen>
    with SingleTickerProviderStateMixin {
  // Theme Constants
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _accentColor = const Color(0xFF00D9FF);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _textColor = const Color(0xFF2D3436);
  final Color _cardColor = Colors.white;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  bool _hasAcceptedTerms = false;

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
                "Terms of Service",
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
                              Icons.description_outlined,
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
                                "Effective: January 17, 2026",
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
                            Icons.handshake_outlined,
                            size: 48,
                            color: _primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome to NagarSetu",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "These Terms of Service ('Terms') govern your access to and use of the NagarSetu mobile application and related services. By using our platform, you enter into a binding legal agreement with NagarSetu Technologies Pvt. Ltd. Please read these terms carefully before proceeding.",
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
                              _buildQuickInfoChip(Icons.gavel, "Binding"),
                              const SizedBox(width: 8),
                              _buildQuickInfoChip(Icons.verified_user, "Fair"),
                              const SizedBox(width: 8),
                              _buildQuickInfoChip(Icons.balance, "Legal"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Key Points Summary ---
                    _buildKeyPointsSummary(),
                    const SizedBox(height: 24),

                    // --- Table of Contents ---
                    _buildTableOfContents(),
                    const SizedBox(height: 24),

                    // --- Terms Sections ---
                    _buildTermSection(
                      icon: Icons.check_circle_outline,
                      title: "1. Acceptance of Terms",
                      content: "By downloading, installing, accessing, or using the NagarSetu application, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.\n\n"
                          "Agreement Conditions:\n"
                          "• You must be at least 13 years old to use this service\n"
                          "• Users between 13-18 must have parental/guardian consent\n"
                          "• You must provide accurate registration information\n"
                          "• You accept our Privacy Policy as part of these terms\n"
                          "• These terms apply to all users including citizens, workers, and administrators\n\n"
                          "If you do not agree with any part of these terms, you must immediately discontinue use of the application.",
                    ),

                    _buildTermSection(
                      icon: Icons.assignment_outlined,
                      title: "2. Description of Services",
                      content: "NagarSetu is a civic engagement platform designed to connect citizens with municipal authorities for efficient resolution of civic issues.\n\n"
                          "Our Services Include:\n"
                          "• Civic Issue Reporting: Submit complaints about potholes, garbage, streetlights, water supply, etc.\n"
                          "• Real-time Tracking: Monitor the status of your submitted reports\n"
                          "• Photo Documentation: Upload evidence of civic issues\n"
                          "• Location Tagging: Precise geolocation of reported problems\n"
                          "• Communication: Receive updates and notifications about your reports\n"
                          "• Feedback System: Rate and review issue resolution\n\n"
                          "Service Availability:\n"
                          "• Services are available in participating municipal areas only\n"
                          "• Some features may vary by region\n"
                          "• We reserve the right to modify or discontinue services",
                    ),

                    _buildTermSection(
                      icon: Icons.person_outline,
                      title: "3. User Account & Registration",
                      content: "To access full features of NagarSetu, you must create a user account.\n\n"
                          "Registration Requirements:\n"
                          "• Valid mobile phone number (verified via OTP)\n"
                          "• Accurate personal information (name, email, address)\n"
                          "• Unique username and strong password\n"
                          "• Profile photo (optional but recommended)\n\n"
                          "Account Responsibilities:\n"
                          "• Maintain confidentiality of login credentials\n"
                          "• Notify us immediately of any unauthorized access\n"
                          "• Keep your contact information updated\n"
                          "• One account per person (no duplicate accounts)\n"
                          "• You are liable for all activities under your account\n\n"
                          "Account Verification:\n"
                          "We may require additional verification (Aadhaar/ID) for certain features.",
                    ),

                    _buildTermSection(
                      icon: Icons.gavel_outlined,
                      title: "4. User Conduct & Prohibited Activities",
                      content: "You agree to use NagarSetu responsibly and ethically.\n\n"
                          "Prohibited Activities:\n"
                          "• Submitting false, misleading, or fraudulent reports\n"
                          "• Uploading inappropriate, offensive, obscene, or illegal content\n"
                          "• Harassing, threatening, or abusing municipal workers or other users\n"
                          "• Impersonating any person or entity\n"
                          "• Spamming or submitting duplicate reports\n"
                          "• Attempting to hack, reverse engineer, or exploit the application\n"
                          "• Using automated bots or scripts\n"
                          "• Violating any local, state, or national laws\n"
                          "• Interfering with the proper functioning of the platform\n\n"
                          "Consequences:\n"
                          "Violation of these rules may result in warning, suspension, or permanent termination of your account, and potential legal action.",
                    ),

                    _buildTermSection(
                      icon: Icons.report_outlined,
                      title: "5. Report Submission Guidelines",
                      content: "To ensure efficient issue resolution, please follow these guidelines when submitting reports.\n\n"
                          "Report Requirements:\n"
                          "• Clear, focused photographs of the issue\n"
                          "• Accurate location information (GPS preferred)\n"
                          "• Detailed description of the problem\n"
                          "• Appropriate category selection\n"
                          "• No personal information of third parties without consent\n\n"
                          "Photo Guidelines:\n"
                          "• Images must be recent (within 48 hours)\n"
                          "• No faces of identifiable individuals without consent\n"
                          "• Clear visibility of the issue\n"
                          "• Maximum 5 photos per report\n"
                          "• Supported formats: JPG, PNG (max 10MB each)\n\n"
                          "We reserve the right to reject or remove reports that violate these guidelines.",
                    ),

                    _buildTermSection(
                      icon: Icons.copyright_outlined,
                      title: "6. Intellectual Property Rights",
                      content: "NagarSetu respects intellectual property rights and expects users to do the same.\n\n"
                          "Our Intellectual Property:\n"
                          "• The NagarSetu name, logo, and branding are our trademarks\n"
                          "• App design, code, and functionality are protected by copyright\n"
                          "• Unauthorized use or reproduction is strictly prohibited\n\n"
                          "Your Content:\n"
                          "• You retain ownership of photos and content you submit\n"
                          "• By uploading, you grant NagarSetu a non-exclusive, royalty-free, worldwide license to:\n"
                          "  - Use, reproduce, and display your content\n"
                          "  - Share with municipal authorities for issue resolution\n"
                          "  - Use anonymized data for analytics and improvements\n"
                          "• This license continues even after account deletion for archival purposes\n\n"
                          "Third-Party Content:\n"
                          "Do not submit content that infringes on others' intellectual property rights.",
                    ),

                    _buildTermSection(
                      icon: Icons.security_outlined,
                      title: "7. Privacy & Data Protection",
                      content: "Your privacy is important to us. Please review our Privacy Policy for detailed information.\n\n"
                          "Data Collection Summary:\n"
                          "• Personal information (name, contact details)\n"
                          "• Location data (for report geotagging)\n"
                          "• Photos and media files\n"
                          "• Device information and usage analytics\n\n"
                          "Data Usage:\n"
                          "• Processing and routing your civic complaints\n"
                          "• Communicating status updates\n"
                          "• Improving our services\n"
                          "• Sharing with authorized municipal authorities only\n\n"
                          "Your Rights:\n"
                          "• Access, correct, or delete your personal data\n"
                          "• Opt-out of non-essential communications\n"
                          "• Request data portability",
                    ),

                    _buildTermSection(
                      icon: Icons.warning_amber_rounded,
                      title: "8. Disclaimers & Limitations",
                      content: "Please understand the following limitations of our service.\n\n"
                          "Service Disclaimers:\n"
                          "• NagarSetu is a platform connecting citizens with authorities\n"
                          "• We do not directly perform repair or maintenance work\n"
                          "• Resolution times depend on municipal authorities\n"
                          "• We do not guarantee resolution of all reported issues\n"
                          "• Service availability may be interrupted for maintenance\n\n"
                          "Limitation of Liability:\n"
                          "• We are not liable for delays in issue resolution\n"
                          "• We are not responsible for actions of municipal workers\n"
                          "• Maximum liability limited to fees paid (if any) in past 12 months\n"
                          "• We are not liable for indirect, consequential, or punitive damages\n\n"
                          "'AS IS' Basis:\n"
                          "The service is provided 'as is' without warranties of any kind.",
                    ),

                    _buildTermSection(
                      icon: Icons.phonelink_erase_outlined,
                      title: "9. Account Suspension & Termination",
                      content: "We may suspend or terminate accounts under certain circumstances.\n\n"
                          "Grounds for Action:\n"
                          "• Violation of these Terms of Service\n"
                          "• Submission of false or fraudulent reports\n"
                          "• Abusive behavior towards staff or other users\n"
                          "• Suspected illegal activity\n"
                          "• Extended period of inactivity (over 2 years)\n"
                          "• At our sole discretion for any reason\n\n"
                          "Process:\n"
                          "• Warning may be issued for minor violations\n"
                          "• Temporary suspension for repeated violations\n"
                          "• Permanent ban for severe violations\n"
                          "• You will be notified via registered email\n\n"
                          "Appeal:\n"
                          "You may appeal suspension decisions by contacting legal@nagarsetu.com within 30 days.",
                    ),

                    _buildTermSection(
                      icon: Icons.balance_outlined,
                      title: "10. Indemnification",
                      content: "You agree to indemnify and hold harmless NagarSetu and its affiliates.\n\n"
                          "You Agree to Indemnify Us Against:\n"
                          "• Claims arising from your use of the service\n"
                          "• Violation of these terms by you\n"
                          "• Infringement of third-party rights\n"
                          "• Any content you submit to the platform\n"
                          "• Your violation of any applicable laws\n\n"
                          "This indemnification includes reasonable legal fees and costs incurred in defending such claims.",
                    ),

                    _buildTermSection(
                      icon: Icons.public_outlined,
                      title: "11. Governing Law & Jurisdiction",
                      content: "These terms are governed by the laws of India.\n\n"
                          "Legal Framework:\n"
                          "• Information Technology Act, 2000\n"
                          "• Consumer Protection Act, 2019\n"
                          "• Indian Contract Act, 1872\n"
                          "• Other applicable Indian laws and regulations\n\n"
                          "Dispute Resolution:\n"
                          "• Disputes shall first be addressed through good-faith negotiation\n"
                          "• Unresolved disputes may be submitted to mediation\n"
                          "• Final resolution through arbitration in Mumbai, Maharashtra\n"
                          "• Language of arbitration: English\n\n"
                          "Jurisdiction:\n"
                          "Courts in Mumbai, Maharashtra shall have exclusive jurisdiction.",
                    ),

                    _buildTermSection(
                      icon: Icons.update_outlined,
                      title: "12. Changes to Terms",
                      content: "We may update these Terms of Service from time to time.\n\n"
                          "Notification of Changes:\n"
                          "• Material changes will be notified via in-app notification\n"
                          "• Email notification to registered users\n"
                          "• Updated 'Effective Date' at the top of this document\n"
                          "• 30-day notice period for significant changes\n\n"
                          "Your Acceptance:\n"
                          "• Continued use after changes constitutes acceptance\n"
                          "• If you disagree with changes, you must stop using the service\n"
                          "• Previous versions available upon request\n\n"
                          "We encourage you to review these terms periodically.",
                    ),

                    _buildTermSection(
                      icon: Icons.contact_support_outlined,
                      title: "13. Contact Information",
                      content: "For questions, concerns, or feedback about these Terms of Service:\n\n"
                          "NagarSetu Technologies Pvt. Ltd.\n\n"
                          "Registered Office:\n"
                          "123 Civic Center, Bandra Kurla Complex\n"
                          "Mumbai, Maharashtra 400051, India\n\n"
                          "Contact Channels:\n"
                          "• Legal Inquiries: legal@nagarsetu.com\n"
                          "• General Support: support@nagarsetu.com\n"
                          "• Phone: +91 1800-XXX-XXXX (Toll-free)\n"
                          "• Response Time: Within 5 business days\n\n"
                          "Grievance Officer:\n"
                          "Name: [Grievance Officer Name]\n"
                          "Email: grievance@nagarsetu.com",
                    ),

                    _buildTermSection(
                      icon: Icons.miscellaneous_services_outlined,
                      title: "14. Miscellaneous Provisions",
                      content: "Additional legal provisions that apply to these terms.\n\n"
                          "Severability:\n"
                          "If any provision is found unenforceable, remaining provisions continue in effect.\n\n"
                          "Waiver:\n"
                          "Failure to enforce any right does not constitute a waiver of that right.\n\n"
                          "Assignment:\n"
                          "You may not assign your rights under these terms. We may assign our rights to affiliates or successors.\n\n"
                          "Entire Agreement:\n"
                          "These terms, along with our Privacy Policy, constitute the entire agreement between you and NagarSetu.\n\n"
                          "Headings:\n"
                          "Section headings are for convenience only and have no legal effect.\n\n"
                          "Survival:\n"
                          "Provisions relating to intellectual property, indemnification, and limitations of liability survive termination.",
                    ),

                    const SizedBox(height: 20),

                    // --- Acceptance Checkbox ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _hasAcceptedTerms 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasAcceptedTerms 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _hasAcceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _hasAcceptedTerms = value ?? false;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hasAcceptedTerms = !_hasAcceptedTerms;
                                });
                              },
                              child: Text(
                                "I have read, understood, and agree to be bound by these Terms of Service and the Privacy Policy.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _hasAcceptedTerms 
                                      ? Colors.green[800]
                                      : Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
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
                            "Need Legal Assistance?",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Our legal team is available to help you understand these terms and address any concerns.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildContactItem(Icons.email_outlined, "legal@nagarsetu.com"),
                          const SizedBox(height: 12),
                          _buildContactItem(Icons.phone_outlined, "+91 1800-XXX-XXXX"),
                          const SizedBox(height: 12),
                          _buildContactItem(Icons.schedule_outlined, "Mon-Fri: 9AM - 6PM IST"),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Response Time: 5 Business Days",
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
                              Icon(Icons.gavel, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                "Legal Notice",
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
                            "This Terms of Service agreement is a legally binding contract between you and NagarSetu Technologies Pvt. Ltd. By using our services, you acknowledge that you have the legal capacity to enter into this agreement.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "CIN: U72900MH2024PTC123456",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "© 2026 NagarSetu Technologies Pvt. Ltd. All rights reserved.",
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

  Widget _buildKeyPointsSummary() {
    final keyPoints = [
      {"icon": Icons.check, "text": "You must be 13+ to use NagarSetu"},
      {"icon": Icons.check, "text": "Submit accurate and truthful reports only"},
      {"icon": Icons.check, "text": "Respect municipal workers and other users"},
      {"icon": Icons.check, "text": "Your content may be shared with authorities"},
      {"icon": Icons.check, "text": "We may suspend accounts for violations"},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              Text(
                "Key Points Summary",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...keyPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(point["icon"] as IconData, size: 18, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point["text"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTableOfContents() {
    final sections = [
      "Acceptance of Terms",
      "Description of Services",
      "User Account & Registration",
      "User Conduct & Prohibited Activities",
      "Report Submission Guidelines",
      "Intellectual Property Rights",
      "Privacy & Data Protection",
      "Disclaimers & Limitations",
      "Account Suspension & Termination",
      "Indemnification",
      "Governing Law & Jurisdiction",
      "Changes to Terms",
      "Contact Information",
      "Miscellaneous Provisions",
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

  Widget _buildTermSection({
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