import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_service.dart';
import '../services/secure_storage_service.dart';
import '../services/user_service.dart';
import '../services/issue_service.dart';
import '../services/hotspot_service.dart';
import '../models/admin_models.dart';
import '../models/leaderboard_entry.dart';
import '../models/weekly_stats_model.dart';
import '../models/issue_map_model.dart';
import '../models/hotspot_model.dart';
import '../models/daily_stats_model.dart';
import 'login.dart';
import 'admin_map_screen.dart';
import 'admin_hotspots_screen.dart';

class AdminPanelHomePage extends StatefulWidget {
  const AdminPanelHomePage({super.key});

  @override
  State<AdminPanelHomePage> createState() => _AdminPanelHomePageState();
}

class _AdminPanelHomePageState extends State<AdminPanelHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    _AdminDashboardTab(),
    _AdminWorkersTab(),
    _AdminSupervisorsTab(),
    AdminMapScreen(),
    _AdminProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color _primaryColor = const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.engineering_rounded),
              label: 'Workers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.supervisor_account_rounded),
              label: 'Supervisors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB A: DASHBOARD
// ---------------------------------------------------------------------------

class _AdminDashboardTab extends StatefulWidget {
  const _AdminDashboardTab();

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  bool _isLoading = true;
  int _totalWorkers = 0;
  int _pendingWorkers = 0;
  int _totalSupervisors = 0;
  int _pendingSupervisors = 0;

  // Leaderboard data
  bool _isLoadingLeaderboard = true;
  List<LeaderboardEntry> _leaderboard = [];

  // Weekly stats data
  bool _isLoadingWeeklyStats = true;
  List<WeeklyStageCount> _weeklyStats = [];

  // Hotspot data
  bool _isLoadingHotspots = true;
  List<HotspotModel> _hotspots = [];
  Map<String, dynamic> _hotspotSummary = {};

  // 30 Days Chart data
  bool _isLoadingChartData = true;
  List<DailyStats> _dailyStats = [];
  MonthlyStatsSummary? _monthSummary;
  int _selectedChartType = 0; // 0 = Line, 1 = Bar, 2 = Area

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadLeaderboard();
    _loadWeeklyStats();
    _loadHotspots();
    _load30DaysStats();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final workersResult = await AdminService.getAllWorkers();
    final pendingWorkersResult = await AdminService.getWorkersNotStarted();
    final supervisorsResult = await AdminService.getAllSupervisors();
    final pendingSupervisorsResult =
        await AdminService.getSupervisorsNotStarted();

    if (mounted) {
      setState(() {
        _totalWorkers = workersResult.data?.length ?? 0;
        _pendingWorkers = pendingWorkersResult.data?.length ?? 0;
        _totalSupervisors = supervisorsResult.data?.length ?? 0;
        _pendingSupervisors = pendingSupervisorsResult.data?.length ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoadingLeaderboard = true);
    final entries = await UserService.getLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboard = entries;
        _isLoadingLeaderboard = false;
      });
    }
  }

  Future<void> _loadWeeklyStats() async {
    setState(() => _isLoadingWeeklyStats = true);
    final result = await IssueService.getWeeklyStats();
    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          _weeklyStats = result.data!;
        }
        _isLoadingWeeklyStats = false;
      });
    }
  }

  Future<void> _loadHotspots() async {
    setState(() => _isLoadingHotspots = true);
    final result = await IssueService.getIssueMapForAdmin();
    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          _hotspots = HotspotService.detectHotspots(result.data!);
          _hotspotSummary = HotspotService.getHotspotSummary(_hotspots);
        }
        _isLoadingHotspots = false;
      });
    }
  }

  Future<void> _load30DaysStats() async {
    setState(() => _isLoadingChartData = true);
    final result = await AdminService.get30DaysStats();
    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          _dailyStats = result.data!;
          _monthSummary = MonthlyStatsSummary.fromDailyStats(_dailyStats);
        }
        _isLoadingChartData = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadDashboardData(),
      _loadLeaderboard(),
      _loadWeeklyStats(),
      _loadHotspots(),
      _load30DaysStats(),
    ]);
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Manage your city operations',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF1976D2),
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Workers',
                    _totalWorkers.toString(),
                    Icons.engineering_rounded,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Pending Workers',
                    _pendingWorkers.toString(),
                    Icons.pending_actions_rounded,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Total Supervisors',
                    _totalSupervisors.toString(),
                    Icons.supervisor_account_rounded,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Pending Supervisors',
                    _pendingSupervisors.toString(),
                    Icons.hourglass_empty_rounded,
                    Colors.purple,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Leaderboard Section
            _buildLeaderboardSection(),

            const SizedBox(height: 24),

            // Weekly Stats Section
            _buildWeeklyStatsSection(),

            const SizedBox(height: 24),

            // 30 Days Analytics Chart
            _build30DaysChartSection(),

            const SizedBox(height: 24),

            // Hotspot Summary Section
            _buildHotspotSummarySection(),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildQuickActionCard(
              'Approve Pending Workers',
              'Review and approve new worker registrations',
              Icons.person_add_alt_1_rounded,
              Colors.blue,
              () {
                // Navigate to workers tab
                final homeState = context
                    .findAncestorStateOfType<_AdminPanelHomePageState>();
                homeState?._onItemTapped(1);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              'Approve Pending Supervisors',
              'Review and approve new supervisor registrations',
              Icons.group_add_rounded,
              Colors.green,
              () {
                // Navigate to supervisors tab
                final homeState = context
                    .findAncestorStateOfType<_AdminPanelHomePageState>();
                homeState?._onItemTapped(2);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              'View All Hotspots',
              'Identify and analyze high-issue areas',
              Icons.location_on_rounded,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminHotspotsScreen(hotspots: _hotspots),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Leaderboard Section
  Widget _buildLeaderboardSection() {
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
            color: Colors.blue.withOpacity(0.3),
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
              Text(
                'Top Contributors',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLeaderboard)
            ...List.generate(3, (_) => _buildContributorPlaceholder())
          else if (_leaderboard.isNotEmpty)
            ..._leaderboard.take(5).toList().asMap().entries.map((e) {
              return _buildContributorItem(e.key + 1, e.value);
            })
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No leaderboard data available',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContributorItem(int rank, LeaderboardEntry entry) {
    Color rankColor;
    IconData? rankIcon;

    switch (rank) {
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (rankIcon != null)
            Icon(rankIcon, color: rankColor, size: 26)
          else
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              _initials(entry.fullName),
              style: GoogleFonts.poppins(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.fullName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${entry.score} pts',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 14, color: Colors.white.withOpacity(0.15)),
          ),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  // Weekly Stats Section
  Widget _buildWeeklyStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_rounded, color: Colors.blue[600], size: 24),
            const SizedBox(width: 8),
            Text(
              'Weekly Issue Stats',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: _isLoadingWeeklyStats
              ? const Center(child: CircularProgressIndicator())
              : _weeklyStats.isEmpty
              ? Center(
                  child: Text(
                    'No stats available',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weeklyStats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final stat = _weeklyStats[index];
                    return _buildWeeklyStatCard(stat);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStatCard(WeeklyStageCount stat) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: stat.stageColor,
                ),
              ),
              Icon(
                stat.stageIcon,
                color: stat.stageColor.withOpacity(0.6),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.displayLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
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

  // Hotspot Summary Section
  Widget _buildHotspotSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.orange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
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
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Hotspot Areas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_isLoadingHotspots && _hotspots.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminHotspotsScreen(hotspots: _hotspots),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingHotspots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_hotspots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hotspots detected',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Summary stats row
                Row(
                  children: [
                    _buildHotspotStat(
                      'Total',
                      _hotspotSummary['total'] ?? 0,
                      Colors.white,
                    ),
                    _buildHotspotStat(
                      'Critical',
                      _hotspotSummary['critical'] ?? 0,
                      Colors.red[900]!,
                    ),
                    _buildHotspotStat(
                      'High',
                      _hotspotSummary['high'] ?? 0,
                      Colors.red[400]!,
                    ),
                    _buildHotspotStat(
                      'Moderate',
                      _hotspotSummary['moderate'] ?? 0,
                      Colors.orange[400]!,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Top 3 hotspots
                ..._hotspots
                    .take(3)
                    .map((hotspot) => _buildHotspotItem(hotspot)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHotspotStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotItem(HotspotModel hotspot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hotspot.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(hotspot.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotspot.locality,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${hotspot.issueCount} issues • ${hotspot.severityLabel}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hotspot.color.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${hotspot.hotspotScore.toInt()}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 30 Days Analytics Chart Section
  Widget _build30DaysChartSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '30 Days Analytics',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Issue workflow overview',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chart Type Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartTypeButton(0, Icons.show_chart_rounded, 'Line'),
                    _buildChartTypeButton(1, Icons.bar_chart_rounded, 'Bar'),
                    _buildChartTypeButton(2, Icons.area_chart_rounded, 'Area'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Stats Row
          if (_monthSummary != null && !_isLoadingChartData)
            _buildChartSummaryRow(),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 220,
            child: _isLoadingChartData
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  )
                : _dailyStats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No data available',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildChart(),
          ),

          const SizedBox(height: 16),

          // Legend
          if (!_isLoadingChartData && _dailyStats.isNotEmpty)
            _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(int index, IconData icon, String label) {
    final isSelected = _selectedChartType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildChartSummaryRow() {
    return Row(
      children: [
        _buildSummaryItem(
          'Created',
          _monthSummary!.totalCreated.toString(),
          const Color(0xFF1976D2),
          Icons.assignment_rounded,
        ),
        _buildSummaryItem(
          'Resolved',
          _monthSummary!.totalResolved.toString(),
          const Color(0xFF43A047),
          Icons.check_circle_rounded,
        ),
        _buildSummaryItem(
          'Pending',
          _monthSummary!.pendingIssues.toString(),
          const Color(0xFFE53935),
          Icons.pending_rounded,
        ),
        _buildSummaryItem(
          'Resolution',
          '${_monthSummary!.resolutionRate.toStringAsFixed(0)}%',
          const Color(0xFFFF9800),
          Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (_selectedChartType) {
      case 0:
        return _buildLineChart();
      case 1:
        return _buildBarChart();
      case 2:
        return _buildAreaChart();
      default:
        return _buildLineChart();
    }
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_dailyStats.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dayIndex = spot.x.toInt();
                if (dayIndex < 0 || dayIndex >= _dailyStats.length) return null;
                final day = _dailyStats[dayIndex];
                final stageName = _getStageNameFromLineIndex(spot.barIndex);
                return LineTooltipItem(
                  '${day.formattedDate}\n$stageName: ${spot.y.toInt()}',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _buildLineChartBarData('created', const Color(0xFF1976D2)),
          _buildLineChartBarData('resolved', const Color(0xFF43A047)),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(String stage, Color color) {
    return LineChartBarData(
      spots: _dailyStats.asMap().entries.map((e) {
        final value = _getStageValue(e.value, stage);
        return FlSpot(e.key.toDouble(), value.toDouble());
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= _dailyStats.length)
                return null;
              final day = _dailyStats[groupIndex];
              return BarTooltipItem(
                '${day.formattedDate}\nCreated: ${day.created}',
                GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        barGroups: _dailyStats.asMap().entries.map((e) {
          final stats = e.value;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: stats.created.toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _dailyStats.length > 15 ? 6 : 10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_dailyStats.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dayIndex = spot.x.toInt();
                if (dayIndex < 0 || dayIndex >= _dailyStats.length) return null;
                final day = _dailyStats[dayIndex];
                return LineTooltipItem(
                  '${day.formattedDate}\nCreated: ${day.created}',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _dailyStats.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.created.toDouble());
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2).withOpacity(0.3),
                  const Color(0xFF42A5F5).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: _dailyStats.length > 15 ? 7 : 5,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= _dailyStats.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dailyStats[index].formattedDate,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 9,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          interval: _getMaxY() / 5,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    final legends = [
      {'name': 'Created', 'color': const Color(0xFF1976D2)},
      {'name': 'Resolved', 'color': const Color(0xFF43A047)},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: legends.map((legend) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: legend['color'] as Color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              legend['name'] as String,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        );
      }).toList(),
    );
  }

  double _getMaxY() {
    if (_dailyStats.isEmpty) return 10;
    int max = 1;
    for (final day in _dailyStats) {
      if (day.created > max) max = day.created;
      if (day.resolved > max) max = day.resolved;
    }
    return (max * 1.2).ceilToDouble();
  }

  int _getStageValue(DailyStats stats, String stage) {
    switch (stage) {
      case 'created':
        return stats.created;
      case 'resolved':
        return stats.resolved;
      default:
        return 0;
    }
  }

  String _getStageNameFromLineIndex(int index) {
    switch (index) {
      case 0:
        return 'Created';
      case 1:
        return 'Resolved';
      default:
        return '';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
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
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB B: WORKERS MANAGEMENT
// ---------------------------------------------------------------------------

class _AdminWorkersTab extends StatefulWidget {
  const _AdminWorkersTab();

  @override
  State<_AdminWorkersTab> createState() => _AdminWorkersTabState();
}

class _AdminWorkersTabState extends State<_AdminWorkersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<AdminUserDto> _allWorkers = [];
  List<AdminUserDto> _pendingWorkers = [];
  List<AdminWorkerDto> _supervisors = []; // For assigning workers

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final allResult = await AdminService.getAllWorkers();
    final pendingResult = await AdminService.getWorkersNotStarted();
    final supervisorsResult = await AdminService.getAllSupervisors();

    if (mounted) {
      setState(() {
        _allWorkers = allResult.data ?? [];
        _pendingWorkers = pendingResult.data ?? [];
        _supervisors = (supervisorsResult.data ?? [])
            .where((s) => s.started)
            .toList(); // Only approved supervisors
        _isLoading = false;
      });
    }
  }

  Future<void> _approveWorker(AdminUserDto worker) async {
    if (_supervisors.isEmpty) {
      _showSnackBar(
        'No supervisors available. Please approve a supervisor first.',
      );
      return;
    }

    // Show dialog to select supervisor
    final selectedSupervisor = await showDialog<AdminWorkerDto>(
      context: context,
      builder: (context) => _SelectSupervisorDialog(supervisors: _supervisors),
    );

    if (selectedSupervisor == null) return;

    // Show loading
    _showSnackBar('Approving worker...');

    final result = await AdminService.acceptWorker(
      workerId: worker.id,
      supervisorId: selectedSupervisor.id,
    );

    if (mounted) {
      _showSnackBar(result.message ?? 'Operation completed');
      if (result.success) {
        _loadData(); // Refresh data
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text(
                'Workers',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF1976D2),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Pending (${_pendingWorkers.length})'),
              Tab(text: 'All (${_allWorkers.length})'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkersList(_pendingWorkers, isPending: true),
                    _buildWorkersList(_allWorkers, isPending: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWorkersList(
    List<AdminUserDto> workers, {
    required bool isPending,
  }) {
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending
                  ? Icons.check_circle_outline_rounded
                  : Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending workers' : 'No workers found',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return _buildWorkerCard(worker, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildWorkerCard(AdminUserDto worker, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
            child: Text(
              worker.username.isNotEmpty
                  ? worker.username[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.username,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.location ?? 'Unknown location',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  worker.timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            ElevatedButton(
              onPressed: () => _approveWorker(worker),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Approve',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: worker.started
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                worker.started ? 'Active' : 'Pending',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: worker.started ? Colors.green : Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB C: SUPERVISORS MANAGEMENT
// ---------------------------------------------------------------------------

class _AdminSupervisorsTab extends StatefulWidget {
  const _AdminSupervisorsTab();

  @override
  State<_AdminSupervisorsTab> createState() => _AdminSupervisorsTabState();
}

class _AdminSupervisorsTabState extends State<_AdminSupervisorsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<AdminWorkerDto> _allSupervisors = [];
  List<AdminWorkerDto> _pendingSupervisors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final allResult = await AdminService.getAllSupervisors();
    final pendingResult = await AdminService.getSupervisorsNotStarted();

    if (mounted) {
      setState(() {
        _allSupervisors = allResult.data ?? [];
        _pendingSupervisors = pendingResult.data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _approveSupervisor(AdminWorkerDto supervisor) async {
    // Show dialog to select department
    final selectedDepartment = await showDialog<Department>(
      context: context,
      builder: (context) => const _SelectDepartmentDialog(),
    );

    if (selectedDepartment == null) return;

    // Show loading
    _showSnackBar('Approving supervisor...');

    final result = await AdminService.acceptSupervisor(
      supervisorId: supervisor.id,
      department: selectedDepartment.name,
    );

    if (mounted) {
      _showSnackBar(result.message ?? 'Operation completed');
      if (result.success) {
        _loadData(); // Refresh data
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text(
                'Supervisors',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF1976D2),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Pending (${_pendingSupervisors.length})'),
              Tab(text: 'All (${_allSupervisors.length})'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSupervisorsList(_pendingSupervisors, isPending: true),
                    _buildSupervisorsList(_allSupervisors, isPending: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSupervisorsList(
    List<AdminWorkerDto> supervisors, {
    required bool isPending,
  }) {
    if (supervisors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending
                  ? Icons.check_circle_outline_rounded
                  : Icons.supervisor_account_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending supervisors' : 'No supervisors found',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: supervisors.length,
        itemBuilder: (context, index) {
          final supervisor = supervisors[index];
          return _buildSupervisorCard(supervisor, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildSupervisorCard(
    AdminWorkerDto supervisor, {
    required bool isPending,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Text(
                  supervisor.username.isNotEmpty
                      ? supervisor.username[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supervisor.username,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            supervisor.location ?? 'Unknown location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPending)
                ElevatedButton(
                  onPressed: () => _approveSupervisor(supervisor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: supervisor.started
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    supervisor.started ? 'Active' : 'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: supervisor.started ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          if (supervisor.department != null && !isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 14,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    supervisor.department!.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            supervisor.timeAgo,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB D: PROFILE
// ---------------------------------------------------------------------------

class _AdminProfileTab extends StatefulWidget {
  const _AdminProfileTab();

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  String _userName = 'Admin';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await SecureStorageService.getUserName();
    final email = await SecureStorageService.getUserEmail();

    if (mounted) {
      setState(() {
        _userName = name ?? 'Admin';
        _userEmail = email ?? '';
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService.clearAll();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _userName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            _userEmail,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ADMINISTRATOR',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Settings options
          _buildProfileOption(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.info_outline_rounded,
            title: 'About',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _buildProfileOption(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF1976D2),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIALOGS
// ---------------------------------------------------------------------------

class _SelectSupervisorDialog extends StatelessWidget {
  final List<AdminWorkerDto> supervisors;

  const _SelectSupervisorDialog({required this.supervisors});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Supervisor',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: supervisors.length,
          itemBuilder: (context, index) {
            final supervisor = supervisors[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Text(
                  supervisor.username.isNotEmpty
                      ? supervisor.username[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              title: Text(
                supervisor.username,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                supervisor.department?.displayName ?? 'No department',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () => Navigator.pop(context, supervisor),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}

class _SelectDepartmentDialog extends StatelessWidget {
  const _SelectDepartmentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Department',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Department.values.length,
          itemBuilder: (context, index) {
            final department = Department.values[index];
            return ListTile(
              leading: Icon(
                _getDepartmentIcon(department),
                color: const Color(0xFF1976D2),
              ),
              title: Text(
                department.displayName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, department),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }

  IconData _getDepartmentIcon(Department department) {
    switch (department) {
      case Department.ROAD:
        return Icons.add_road_rounded;
      case Department.WATER:
        return Icons.water_drop_rounded;
      case Department.GARBAGE:
        return Icons.delete_rounded;
      case Department.VEHICLE:
        return Icons.directions_car_rounded;
      case Department.STREETLIGHT:
        return Icons.lightbulb_rounded;
      case Department.OTHER:
        return Icons.category_rounded;
    }
  }
}
