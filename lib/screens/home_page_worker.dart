import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/worker_service.dart';
import '../services/issue_service.dart';
import '../models/issue_map_model.dart';
import 'discover.dart';
import 'notifications.dart'; // Import the notifications screen
import 'update_work.dart';
import 'worker_map_screen.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  int _selectedIndex = 0;

  // List of tabs corresponding to the bottom navigation items
  static const List<Widget> _widgetOptions = <Widget>[
    _DashboardTab(),
    _IssuesTab(),
    WorkerMapScreen(),
    _WorkerProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Theme Constants
  final Color _primaryColor = const Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light Gray Background
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
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handyman_rounded),
              label: 'Issues',
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

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _userName = 'Worker';
  bool _isLoading = true;
  String? _workerId;
  List<IssueMapModel> _assignedIssues = [];

  // Stats
  int _assignedCount = 0;
  int _pendingCount = 0;
  int _doneCount = 0;

  // Urgent issues (HIGH criticality)
  List<IssueMapModel> _urgentIssues = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserName();
    await _loadWorkerId();
    await _loadAssignedIssues();
  }

  Future<void> _loadUserName() async {
    final name = await SecureStorageService.getUserName();
    if (mounted && name != null) {
      // Get first name only
      final firstName = name.split(' ').first;
      setState(() => _userName = firstName);
    }
  }

  Future<void> _loadWorkerId() async {
    final userId = await SecureStorageService.getUserId();
    if (mounted && userId != null) {
      setState(() => _workerId = userId);
    }
  }

  Future<void> _loadAssignedIssues() async {
    if (_workerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await IssueService.getIssueMapForWorker(_workerId!);

    if (mounted) {
      if (result.success && result.data != null) {
        final issues = result.data!;

        // Calculate stats
        int assigned = issues.length;
        int pending = issues
            .where(
              (i) =>
                  i.stages.toUpperCase() == 'PENDING' ||
                  i.stages.toUpperCase() == 'ACKNOWLEDGED' ||
                  i.stages.toUpperCase() == 'TEAM_ASSIGNED',
            )
            .length;
        int done = issues
            .where((i) => i.stages.toUpperCase() == 'RESOLVED')
            .length;

        // Get urgent issues (HIGH criticality, not resolved)
        final urgent = issues
            .where(
              (i) =>
                  i.criticality.toUpperCase() == 'HIGH' &&
                  i.stages.toUpperCase() != 'RESOLVED',
            )
            .take(2)
            .toList();

        setState(() {
          _assignedIssues = issues;
          _assignedCount = assigned;
          _pendingCount = pending;
          _doneCount = done;
          _urgentIssues = urgent;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadAssignedIssues();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1976D2);

    return RefreshIndicator(
      onRefresh: _refreshData,
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
                      "Hello, $_userName",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      "Municipal Services",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                // UPDATED: Added GestureDetector for Navigation
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid with Icons - Now using real data
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      _buildStatCard(
                        "Assigned",
                        _assignedCount.toString(),
                        "assets/Assigned.png",
                        primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "Pending",
                        _pendingCount.toString(),
                        "assets/Pending.png",
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "Done",
                        _doneCount.toString(),
                        "assets/Completed.png",
                        Colors.green,
                      ),
                    ],
                  ),
            const SizedBox(height: 32),

            // Urgent Section
            const Text(
              "Urgent Attention",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),

            // Show urgent issues from API
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_urgentIssues.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade400,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No urgent issues",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "All high priority tasks are completed",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._urgentIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUrgentCard(
                    title: issue.issueType,
                    address: 'Unknown location',
                    time: _formatTimeAgo(null),
                    issue: issue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Updated Card Builder to accept Icon Path
  Widget _buildStatCard(
    String label,
    String count,
    String iconPath,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            // Display the Asset Image
            Image.asset(
              iconPath,
              height: 90,
              width: 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported, color: color, size: 40),
            ),
            const SizedBox(height: 5),
            Text(
              count,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentCard({
    required String title,
    required String address,
    required String time,
    IssueMapModel? issue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), // Lighter red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: issue != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateWorkPage(
                          taskTitle: title,
                          taskAddress: address,
                          currentStatus: issue.stages,
                          issueId: issue.id,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("View"),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB B: ISSUES (TASK MANAGEMENT)
// ---------------------------------------------------------------------------

class _IssuesTab extends StatefulWidget {
  const _IssuesTab();

  @override
  State<_IssuesTab> createState() => _IssuesTabState();
}

class _IssuesTabState extends State<_IssuesTab> {
  final List<String> filters = [
    "All",
    "High Priority",
    "Pending",
    "In Progress",
    "Resolved",
  ];
  int selectedFilter = 0;

  bool _isLoading = true;
  String? _workerId;
  List<IssueMapModel> _allIssues = [];
  List<IssueMapModel> _filteredIssues = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadWorkerId();
    await _loadAssignedIssues();
  }

  Future<void> _loadWorkerId() async {
    final userId = await SecureStorageService.getUserId();
    if (mounted && userId != null) {
      setState(() => _workerId = userId);
    }
  }

  Future<void> _loadAssignedIssues() async {
    if (_workerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await IssueService.getIssueMapForWorker(_workerId!);

    if (mounted) {
      if (result.success && result.data != null) {
        setState(() {
          _allIssues = result.data!;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    switch (selectedFilter) {
      case 0: // All
        _filteredIssues = List.from(_allIssues);
        break;
      case 1: // High Priority
        _filteredIssues = _allIssues
            .where((i) => i.criticality.toUpperCase() == 'HIGH')
            .toList();
        break;
      case 2: // Pending
        _filteredIssues = _allIssues
            .where(
              (i) =>
                  i.stages.toUpperCase() == 'PENDING' ||
                  i.stages.toUpperCase() == 'ACKNOWLEDGED' ||
                  i.stages.toUpperCase() == 'TEAM_ASSIGNED',
            )
            .toList();
        break;
      case 3: // In Progress
        _filteredIssues = _allIssues
            .where((i) => i.stages.toUpperCase() == 'IN_PROGRESS')
            .toList();
        break;
      case 4: // Resolved
        _filteredIssues = _allIssues
            .where((i) => i.stages.toUpperCase() == 'RESOLVED')
            .toList();
        break;
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadAssignedIssues();
  }

  Color _getStatusColor(String stages) {
    switch (stages.toUpperCase()) {
      case 'PENDING':
        return Colors.grey;
      case 'ACKNOWLEDGED':
        return Colors.blue;
      case 'TEAM_ASSIGNED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String stages) {
    switch (stages.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'TEAM_ASSIGNED':
        return 'Team Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      default:
        return stages;
    }
  }

  String _formatDueDate(DateTime? createdAt) {
    if (createdAt == null) return 'No date';
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Created Today';
    } else if (difference.inDays == 1) {
      return 'Created Yesterday';
    } else if (difference.inDays < 7) {
      return 'Created ${difference.inDays} days ago';
    } else {
      return 'Created ${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          color: const Color(0xFFF5F7FA),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Assigned Tasks",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      "${_filteredIssues.length} tasks",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final bool isSelected = selectedFilter == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filters[index]),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            selectedFilter = index;
                            _applyFilter();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF1976D2),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontFamily: 'Poppins',
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF1976D2)
                                : Colors.transparent,
                          ),
                        ),
                        showCheckmark: false,
                        elevation: isSelected ? 2 : 0,
                        shadowColor: Colors.black26,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredIssues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No tasks found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedFilter == 0
                            ? "You don't have any assigned tasks"
                            : "No tasks match this filter",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _filteredIssues.length,
                    itemBuilder: (context, index) {
                      final issue = _filteredIssues[index];
                      return _buildTaskCard(
                        issue: issue,
                        title: issue.issueType,
                        address: 'Unknown location',
                        date: _formatDueDate(null),
                        status: _getStatusDisplay(issue.stages),
                        statusColor: _getStatusColor(issue.stages),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required IssueMapModel issue,
    required String title,
    required String address,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  // CHANGED: Navigation to UpdateWorkPage with issue ID
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateWorkPage(
                          taskTitle: title,
                          taskAddress: address,
                          currentStatus: status,
                          issueId: issue.id,
                        ),
                      ),
                    ).then((_) => _refreshData()); // Refresh after returning
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// TAB C: PROFILE
// ---------------------------------------------------------------------------

class _WorkerProfileTab extends StatefulWidget {
  const _WorkerProfileTab();

  @override
  State<_WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<_WorkerProfileTab> {
  String _userName = 'Worker';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await SecureStorageService.getUserName();
    if (mounted && name != null) {
      setState(() => _userName = name);
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    await WorkerService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DiscoverPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Profile Pic
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.person, size: 50, color: Color(0xFF1976D2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Field Worker • Municipal Services",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 32),

          // Settings List
          _buildSettingsTile(
            Icons.person_outline,
            "Edit Profile",
            onTap: () {},
          ),
          // UPDATED: Added navigation for Notifications
          _buildSettingsTile(
            Icons.notifications_outlined,
            "Notifications",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(Icons.history, "Task History", onTap: () {}),
          _buildSettingsTile(Icons.help_outline, "Support", onTap: () {}),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoggingOut ? null : _handleLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Added nullable onTap callback
  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1976D2)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
