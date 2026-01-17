import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/localization_service.dart';
import '../widgets/lottie_loader.dart';
import 'discover.dart';
import 'help.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variables
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  UserModel? _user;

  // Settings state
  bool _notificationsEnabled = true;
  String _selectedLanguage = LocalizationService().currentLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocalizationService().currentLanguage;
    _loadUserProfile();
  }

  /// Load user profile from API
  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final response = await UserService.getCurrentUser();

    if (!mounted) return;

    if (response.success && response.user != null) {
      setState(() {
        _user = response.user;
        _isLoading = false;
      });
    } else if (response.isUnauthorized) {
      // Session expired, redirect to login
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DiscoverPage()),
        (_) => false,
      );
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = response.message ?? 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.grey[50], body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LottieLoader(size: 120, message: 'Loading profile...');
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_user == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final user = _user!;
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
                          user.initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (user.isVerified)
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
                  user.displayName,
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
                        _getRoleIcon(user.displayRole),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.displayRole,
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
                      user.displayLocation,
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
    final user = _user!;
    return _ProfileCard(
      title: 'Personal Details',
      icon: Icons.person_outline,
      children: [
        _DetailRow(
          icon: Icons.phone_outlined,
          label: 'Mobile',
          value: user.displayPhone,
        ),
        const _CardDivider(),
        _DetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user.displayEmail,
        ),
        const _CardDivider(),
        _DetailRow(
          icon: Icons.location_city_outlined,
          label: 'Location',
          value: user.displayLocation,
        ),
        if (user.gender != null) ...[
          const _CardDivider(),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Gender',
            value: user.gender!,
          ),
        ],
        if (user.age != null) ...[
          const _CardDivider(),
          _DetailRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: '${user.age} years',
          ),
        ],
        if (user.memberSince != null) ...[
          const _CardDivider(),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: user.memberSince!,
          ),
        ],
      ],
    );
  }

  Widget _buildActivitySummaryCard() {
    final user = _user!;
    return _ProfileCard(
      title: 'Activity Summary',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Reported',
                value: user.issuesReported.toString(),
                color: Colors.blue,
                icon: Icons.report_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                label: 'Resolved',
                value: user.issuesResolved.toString(),
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                label: 'In Progress',
                value: user.issuesInProgress.toString(),
                color: Colors.orange,
                icon: Icons.pending_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContributionStatsCard() {
    final user = _user!;
    return _ProfileCard(
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
                      user.leaderboardRank > 0
                          ? '#${user.leaderboardRank}'
                          : '--',
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
                        '${user.totalPoints}',
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
      ],
    );
  }

  Widget _buildBadgesCard() {
    final user = _user!;
    final badges = user.badges.isNotEmpty
        ? user.badges
        : ['New Member']; // Default badge

    return _ProfileCard(
      title: 'Badges & Achievements',
      icon: Icons.military_tech_outlined,
      trailing: user.badges.length > 4
          ? TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges.take(4).map((badge) {
            return _BadgeChip(
              label: badge,
              icon: _getBadgeIcon(badge),
              color: _getBadgeColor(badge),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    final l10n = LocalizationService();
    return _ProfileCard(
      title: l10n.translate('settings'),
      icon: Icons.settings_outlined,
      children: [
        _SettingRow(
          icon: Icons.notifications_outlined,
          label: l10n.translate('notifications'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            activeThumbColor: Colors.blue[600],
            activeTrackColor: Colors.blue[200],
          ),
        ),
        const _CardDivider(),
        _SettingRow(
          icon: Icons.translate,
          label: l10n.translate('language'),
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
              items: ['English', 'मराठी', 'हिंदी', 'தமிழ்', 'తెలుగు']
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
              onChanged: (val) async {
                if (val != null) {
                  await LocalizationService().setLanguage(val);
                  setState(() => _selectedLanguage = val);
                }
              },
            ),
          ),
        ),
        const _CardDivider(),
        _SettingRow(
          icon: Icons.dark_mode_outlined,
          label: l10n.translate('dark_mode'),
          trailing: Switch(
            value: false,
            onChanged: (val) {},
            activeThumbColor: Colors.blue[600],
            activeTrackColor: Colors.blue[200],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    final l10n = LocalizationService();
    return _ProfileCard(
      title: l10n.translate('support_info'),
      icon: Icons.help_outline,
      children: [
        _SupportRow(
          icon: Icons.help_center_outlined,
          label: l10n.translate('help_center'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpFAQScreen()),
            );
          },
        ),
        const _CardDivider(),
        _SupportRow(icon: Icons.info_outline, label: l10n.translate('about')),
        const _CardDivider(),
        _SupportRow(
          icon: Icons.privacy_tip_outlined,
          label: l10n.translate('privacy_policy'),
        ),
        const _CardDivider(),
        _SupportRow(
          icon: Icons.description_outlined,
          label: l10n.translate('terms_of_service'),
        ),
        const _CardDivider(),
        _SupportRow(icon: Icons.feedback_outlined, label: 'Send Feedback'),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final l10n = LocalizationService();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          l10n.translate('logout'),
          style: const TextStyle(
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

  // Helper methods
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'worker':
        return Icons.engineering;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'department head':
        return Icons.business;
      case 'ward head':
        return Icons.location_city;
      case 'mayor':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }

  IconData _getBadgeIcon(String badge) {
    final lowerBadge = badge.toLowerCase();
    if (lowerBadge.contains('top') || lowerBadge.contains('reporter')) {
      return Icons.star;
    } else if (lowerBadge.contains('quick') || lowerBadge.contains('fast')) {
      return Icons.flash_on;
    } else if (lowerBadge.contains('verified')) {
      return Icons.verified_user;
    } else if (lowerBadge.contains('hero') ||
        lowerBadge.contains('community')) {
      return Icons.people;
    } else if (lowerBadge.contains('new')) {
      return Icons.fiber_new;
    }
    return Icons.emoji_events;
  }

  Color _getBadgeColor(String badge) {
    final lowerBadge = badge.toLowerCase();
    if (lowerBadge.contains('top') || lowerBadge.contains('star')) {
      return Colors.amber;
    } else if (lowerBadge.contains('quick') || lowerBadge.contains('fast')) {
      return Colors.orange;
    } else if (lowerBadge.contains('verified')) {
      return Colors.blue;
    } else if (lowerBadge.contains('hero')) {
      return Colors.purple;
    } else if (lowerBadge.contains('new')) {
      return Colors.green;
    }
    return Colors.teal;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);

              // Show loading
              if (mounted) {
                setState(() => _isLoading = true);
              }

              // Clear auth data
              await AuthService.logout();

              // Navigate to Discover
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoverPage()),
                  (_) => false,
                );
              }
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

// ============================================================================
// Optimized Stateless Helper Widgets (for better performance)
// ============================================================================

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
                if (trailing != null) trailing!,
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey[200]);
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SupportRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
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
}
