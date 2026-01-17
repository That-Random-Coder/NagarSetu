import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  // Dummy user data
  final Map<String, dynamic> user = {
    'name': 'Rajesh Kumar',
    'role': 'Citizen',
    'city': 'New Delhi',
    'ward': 'Ward 15 - Connaught Place',
    'isVerified': true,
    'mobile': '+91 98765 43210',
    'email': 'rajesh.kumar@email.com',
    'language': 'English',
    'issuesReported': 24,
    'issuesResolved': 18,
    'issuesInProgress': 4,
    'leaderboardRank': 12,
    'totalPoints': 1450,
    'badges': ['Top Reporter', 'Quick Responder', 'Verified Citizen'],
    'memberSince': 'March 2024',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildPersonalDetailsCard(),
                  const SizedBox(height: 16),
                  _buildActivitySummaryCard(),
                  const SizedBox(height: 16),
                  _buildContributionStatsCard(),
                  const SizedBox(height: 16),
                  _buildBadgesCard(),
                  const SizedBox(height: 16),
                  _buildSettingsCard(),
                  const SizedBox(height: 16),
                  _buildSupportCard(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.blue[600],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.qr_code, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[700]!, Colors.blue[500]!],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Profile Avatar
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[200],
                        child: Text(
                          user['name'].split(' ').map((n) => n[0]).join(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (user['isVerified'])
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue[600],
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // User Name
                Text(
                  user['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(user['role']),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user['role'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user['city']} • ${user['ward']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return _buildCard(
      title: 'Personal Details',
      icon: Icons.person_outline,
      children: [
        _buildDetailRow(Icons.phone_outlined, 'Mobile', user['mobile']),
        _buildDivider(),
        _buildDetailRow(Icons.email_outlined, 'Email', user['email']),
        _buildDivider(),
        _buildDetailRow(Icons.location_city_outlined, 'Ward', user['ward']),
        _buildDivider(),
        _buildDetailRow(Icons.language, 'Language', user['language']),
        _buildDivider(),
        _buildDetailRow(
          Icons.calendar_today_outlined,
          'Member Since',
          user['memberSince'],
        ),
      ],
    );
  }

  Widget _buildActivitySummaryCard() {
    return _buildCard(
      title: 'Activity Summary',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Reported',
                user['issuesReported'].toString(),
                Colors.blue,
                Icons.report_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Resolved',
                user['issuesResolved'].toString(),
                Colors.green,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'In Progress',
                user['issuesInProgress'].toString(),
                Colors.orange,
                Icons.pending_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContributionStatsCard() {
    return _buildCard(
      title: 'Contribution Stats',
      icon: Icons.emoji_events_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[100]!, Colors.amber[50]!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[400],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard Rank',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${user['leaderboardRank']}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Points',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${user['totalPoints']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat('Response Rate', '92%', Colors.green),
            _buildMiniStat('Avg. Resolution', '3.2 days', Colors.blue),
            _buildMiniStat('This Month', '+5', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgesCard() {
    return _buildCard(
      title: 'Badges & Achievements',
      icon: Icons.military_tech_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: Text(
          'View All',
          style: TextStyle(
            color: Colors.blue[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildBadge('Top Reporter', Icons.star, Colors.amber),
            _buildBadge('Quick Responder', Icons.flash_on, Colors.orange),
            _buildBadge('Verified Citizen', Icons.verified_user, Colors.blue),
            _buildBadge('Community Hero', Icons.people, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return _buildCard(
      title: 'Settings',
      icon: Icons.settings_outlined,
      children: [
        _buildSettingRow(
          Icons.notifications_outlined,
          'Notifications',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            activeColor: Colors.blue[600],
          ),
        ),
        _buildDivider(),
        _buildSettingRow(
          Icons.translate,
          'Language',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              items: ['English', 'हिंदी', 'मराठी', 'தமிழ்', 'తెలుగు']
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(
                        lang,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedLanguage = val!),
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingRow(
          Icons.accessibility_new,
          'Accessibility',
          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          onTap: () {},
        ),
        _buildDivider(),
        _buildSettingRow(
          Icons.dark_mode_outlined,
          'Dark Mode',
          trailing: Switch(
            value: false,
            onChanged: (val) {},
            activeColor: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return _buildCard(
      title: 'Support & Info',
      icon: Icons.help_outline,
      children: [
        _buildSupportRow(
          Icons.help_center_outlined,
          'Help & FAQs',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSupportRow(Icons.info_outline, 'About NagarSetu', onTap: () {}),
        _buildDivider(),
        _buildSupportRow(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSupportRow(
          Icons.description_outlined,
          'Terms of Service',
          onTap: () {},
        ),
        _buildDivider(),
        _buildSupportRow(
          Icons.feedback_outlined,
          'Send Feedback',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutDialog();
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    String label, {
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSupportRow(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: Colors.grey[800]),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Worker':
        return Icons.engineering;
      case 'Supervisor':
        return Icons.supervisor_account;
      case 'Admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[400]),
            const SizedBox(width: 10),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from NagarSetu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
