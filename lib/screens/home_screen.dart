import 'package:flutter/material.dart';
import 'report_issue_screen.dart';
import 'my_issues_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import '../services/user_service.dart';
import '../models/leaderboard_entry.dart';
import '../navigation/route_observer.dart';
import '../services/secure_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _currentIndex = 0;
  String _firstName = 'User';
  bool _isLoadingLeaderboard = true;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  final List<Map<String, dynamic>> topContributors = [
    {'name': 'Ethan Carter', 'points': 1250, 'rank': 1, 'avatar': 'EC'},
    {'name': 'Olivia Bennett', 'points': 1150, 'rank': 2, 'avatar': 'OB'},
    {'name': 'Noah Thompson', 'points': 1100, 'rank': 3, 'avatar': 'NT'},
  ];

  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await SecureStorageService.getUserName();
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      setState(() {
        _firstName = parts.first;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });
    final entries = await UserService.getLeaderboard();
    if (!mounted) return;
    setState(() {
      _leaderboard = entries;
      _isLoadingLeaderboard = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) {
      routeObserver.subscribe(this, modal);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Screen was pushed onto navigation stack
    _loadLeaderboard();
  }

  @override
  void didPopNext() {
    // Returned to this screen (another route popped)
    _loadLeaderboard();
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  final List<Map<String, dynamic>> recentIssues = [
    {
      'title': 'Pothole on Main St',
      'time': '2h ago',
      'status': 'In Progress',
      'type': 'Road',
      'color': Colors.orange,
    },
    {
      'title': 'Streetlight Out',
      'time': '4h ago',
      'status': 'Reported',
      'type': 'Electricity',
      'color': Colors.red,
    },
    {
      'title': 'Water Leak',
      'time': '6h ago',
      'status': 'Resolved',
      'type': 'Water',
      'color': Colors.green,
    },
    {
      'title': 'Garbage Overflow',
      'time': '8h ago',
      'status': 'In Progress',
      'type': 'Waste',
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> howItWorks = [
    {
      'icon': Icons.report_problem_outlined,
      'title': 'Report',
      'desc': 'Spot an issue',
    },
    {'icon': Icons.track_changes, 'title': 'Track', 'desc': 'Monitor progress'},
    {
      'icon': Icons.check_circle_outline,
      'title': 'Resolve',
      'desc': 'Issue fixed',
    },
    {
      'icon': Icons.emoji_events_outlined,
      'title': 'Earn',
      'desc': 'Get points',
    },
  ];

  // Mock data for daily stats
  final List<Map<String, dynamic>> dailyStats = [
    {
      'label': 'Reported',
      'count': '15',
      'color': Colors.red,
      'icon': Icons.report_gmailerrorred,
    },
    {
      'label': 'Assigned',
      'count': '08',
      'color': Colors.blue,
      'icon': Icons.assignment_ind,
    },
    {
      'label': 'In Progress',
      'count': '05',
      'color': Colors.orange,
      'icon': Icons.handyman,
    },
    {
      'label': 'Completed',
      'count': '12',
      'color': Colors.green,
      'icon': Icons.check_circle,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildLeaderboard(),
                const SizedBox(height: 24),
                _buildRecentIssues(),
                const SizedBox(height: 24),
                // --- NEW SECTION ADDED HERE ---
                _buildDailyStats(),
                const SizedBox(height: 24),
                _buildHowItWorks(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ... (Previous methods: _buildHeader, _buildLeaderboard remain unchanged) ...

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Nagar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Setu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hello, $_firstName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.blue[700],
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Top Contributors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              if (_isLoadingLeaderboard) {
                return Column(
                  children: List.generate(
                    3,
                    (_) => _buildContributorPlaceholder(),
                  ),
                );
              }

              if (_leaderboard.isNotEmpty) {
                final uiContributors = _leaderboard.asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return {
                    'name': entry.fullName,
                    'points': entry.score,
                    'rank': idx + 1,
                    'avatar': _initials(entry.fullName),
                  };
                }).toList();

                return Column(
                  children: uiContributors
                      .map((contributor) => _buildContributorItem(contributor))
                      .toList(),
                );
              }

              // No leaderboard entries
              return Column(
                children: topContributors
                    .map((contributor) => _buildContributorItem(contributor))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContributorItem(Map<String, dynamic> contributor) {
    Color rankColor;
    IconData? rankIcon;

    switch (contributor['rank']) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = Colors.grey[300]!;
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = Colors.orange[300]!;
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = Colors.white;
        rankIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(rankIcon, color: rankColor, size: 28),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Text(
              contributor['avatar'],
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              contributor['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${contributor['points']} pts',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 40,
              height: 12,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIssues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(color: Colors.blue[600], fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentIssues.length,
            itemBuilder: (context, index) {
              return _buildIssueCard(recentIssues[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                _getIssueIcon(issue['type']),
                size: 32,
                color: Colors.grey[500],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: issue['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      issue['time'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Daily Stats Section ---
  Widget _buildDailyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Stats (Last 24h)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100, // Fixed height for the stats row
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dailyStats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final stat = dailyStats[index];
              return _buildStatCard(stat);
            },
          ),
        ),
      ],
    );
  }

  // --- NEW: Individual Stat Card ---
  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      width: 160, // Width for each card
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat['count'],
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: stat['color'],
                ),
              ),
              Icon(
                stat['icon'],
                color: stat['color'].withOpacity(0.6),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            stat['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIssueIcon(String type) {
    switch (type) {
      case 'Road':
        return Icons.add_road;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Water':
        return Icons.water_drop;
      case 'Waste':
        return Icons.delete_outline;
      default:
        return Icons.report_problem;
    }
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: howItWorks
                .map((step) => _buildHowItWorksStep(step))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksStep(Map<String, dynamic> step) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(step['icon'], color: Colors.blue[600], size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          step['title'],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          step['desc'],
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.assignment_outlined, 'My Issues', 1),
              _buildReportButton(),
              _buildNavItem(Icons.map_outlined, 'Map', 3),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyIssuesScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue[600] : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
