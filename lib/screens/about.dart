import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Theme Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _accentColor = Color(0xFF64B5F6);
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Beautiful gradient app bar with logo
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Logo Container with glow effect
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Image.asset(
                              'assets/Icon_Setu.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.location_city_rounded,
                                  size: 50,
                                  color: _primaryColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "NagarSetu",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "🌆 Commute Smarter. Live Better.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard("10K+", "Active Users", Icons.people_alt_rounded, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard("500+", "Issues Resolved", Icons.check_circle_rounded, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard("50+", "Wards Covered", Icons.map_rounded, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // What is NagarSetu Section
                  _buildGradientSectionHeader("What is NagarSetu?", Icons.info_rounded),
                  const SizedBox(height: 12),
                  _buildElevatedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Voice, Your City, Our Responsibility",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "NagarSetu (meaning 'City Bridge' in Hindi) is a revolutionary citizen-centric mobile application designed to transform the way you interact with your local municipal corporation. We believe every citizen deserves a clean, safe, and well-maintained city.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Gone are the days of endless phone calls, long queues, and unheard complaints. With NagarSetu, report civic issues instantly from your smartphone — whether it's a pothole damaging vehicles, a broken streetlight compromising safety, garbage overflow creating health hazards, or water supply disruptions affecting daily life.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Our Mission Section
                  _buildGradientSectionHeader("Our Mission", Icons.flag_rounded),
                  const SizedBox(height: 12),
                  _buildElevatedCard(
                    child: Column(
                      children: [
                        _buildMissionPoint(
                          "🌉",
                          "Bridge the Gap",
                          "Connect citizens directly with municipal authorities, eliminating bureaucratic delays and ensuring your voice reaches the right department instantly.",
                        ),
                        const SizedBox(height: 16),
                        _buildMissionPoint(
                          "⚡",
                          "Swift Resolution",
                          "Reduce response times from weeks to days. Our intelligent routing system ensures issues reach the correct department immediately for faster action.",
                        ),
                        const SizedBox(height: 16),
                        _buildMissionPoint(
                          "🤝",
                          "Empower Citizens",
                          "Give every resident the power to contribute to city development. Your reports help authorities identify problem areas and allocate resources efficiently.",
                        ),
                        const SizedBox(height: 16),
                        _buildMissionPoint(
                          "📊",
                          "Transparent Governance",
                          "Track your complaint status in real-time. Know exactly when your issue was assigned, who's working on it, and when it will be resolved.",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Why Choose NagarSetu
                  _buildGradientSectionHeader("Why Choose NagarSetu?", Icons.star_rounded),
                  const SizedBox(height: 12),
                  _buildFeatureGrid(),
                  const SizedBox(height: 28),

                  // How It Works Section
                  _buildGradientSectionHeader("How It Works", Icons.route_rounded),
                  const SizedBox(height: 12),
                  _buildStepCard(1, "📸 Capture", "Spot an issue? Simply take a photo. Our app automatically tags your GPS location for precise reporting.", Colors.blue),
                  const SizedBox(height: 12),
                  _buildStepCard(2, "📝 Describe", "Add details about the problem. Choose from categories like Roads, Sanitation, Water, Electricity, and more.", Colors.purple),
                  const SizedBox(height: 12),
                  _buildStepCard(3, "🚀 Submit", "One tap submission! Your report is instantly routed to the concerned municipal department based on location and category.", Colors.orange),
                  const SizedBox(height: 12),
                  _buildStepCard(4, "📍 Track", "Monitor real-time status updates. Get notified when your issue moves from 'Submitted' to 'In Progress' to 'Resolved'.", Colors.green),
                  const SizedBox(height: 28),

                  // For Everyone Section
                  _buildGradientSectionHeader("Built For Everyone", Icons.groups_rounded),
                  const SizedBox(height: 12),
                  _buildUserTypeCard(
                    "👨‍👩‍👧‍👦",
                    "For Citizens",
                    "Report issues effortlessly, track progress, view history, and contribute to making your neighborhood better. Available in multiple languages for accessibility.",
                    Colors.blue.shade50,
                    Colors.blue.shade700,
                  ),
                  const SizedBox(height: 12),
                  _buildUserTypeCard(
                    "🏛️",
                    "For Municipal Authorities",
                    "Centralized dashboard for issue management, map-based visualization, priority handling, performance analytics, and direct citizen communication.",
                    Colors.orange.shade50,
                    Colors.orange.shade700,
                  ),
                  const SizedBox(height: 12),
                  _buildUserTypeCard(
                    "👨‍💼",
                    "For City Administrators",
                    "Bird's eye view of city-wide issues, identify hotspots, generate detailed reports, monitor department performance, and make data-driven decisions.",
                    Colors.green.shade50,
                    Colors.green.shade700,
                  ),
                  const SizedBox(height: 32),

                  // Footer Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "Together, Let's Build a Better City! 🏙️",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Version 1.0.0",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "© 2026 NagarSetu. All rights reserved.",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Made with ❤️ for our cities",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildElevatedCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMissionPoint(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {"icon": Icons.flash_on_rounded, "title": "Instant Reporting", "color": Colors.amber},
      {"icon": Icons.gps_fixed_rounded, "title": "GPS Auto-Tagging", "color": Colors.blue},
      {"icon": Icons.notifications_active_rounded, "title": "Push Alerts", "color": Colors.red},
      {"icon": Icons.history_rounded, "title": "Issue History", "color": Colors.purple},
      {"icon": Icons.category_rounded, "title": "Smart Categories", "color": Colors.teal},
      {"icon": Icons.security_rounded, "title": "Secure & Private", "color": Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (feature["color"] as Color).withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (feature["color"] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature["icon"] as IconData,
                  color: feature["color"] as Color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feature["title"] as String,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepCard(int step, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "$step",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(String emoji, String title, String description, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}