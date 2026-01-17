import 'package:flutter/material.dart';
import 'supervisor_issue.dart'; // Import for navigation
import '../services/supervisor_service.dart';
import '../services/secure_storage_service.dart';
import '../models/supervisor_models.dart';
import 'login.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    _AdminDashboardTab(),
    _AdminIssuesTab(),
    _AdminMapTab(),
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
              icon: Icon(Icons.analytics_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_open_rounded),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public_rounded),
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
// TAB A: DASHBOARD (UPDATED LOGIC WITH SMOOTH ANIMATION)
// ---------------------------------------------------------------------------

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Command Center",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Real-time city monitoring",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- 1. Staff Activity Section ---
          const Text(
            "Staff Activity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildStaffCard(
                  "Rajesh K.",
                  "En Route",
                  "Water Leak #402",
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStaffCard(
                  "Amit Singh",
                  "Fixing",
                  "Power Outage #991",
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStaffCard(
                  "Priya D.",
                  "Surveying",
                  "Road Block #112",
                  Colors.purple,
                ),
                const SizedBox(width: 12),
                _buildStaffCard(
                  "Vikram M.",
                  "En Route",
                  "Drainage #332",
                  Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- 2. Priority Watchlist Section ---
          const Text(
            "Priority Watchlist",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          // High Severity Group
          _buildPriorityGroup("High Severity", Colors.red, [
            {
              "id": "CRIT-201",
              "title": "Main Water Line Burst",
              "location": "Sector 4, Main Rd",
              "desc":
                  "Major pipeline burst causing flooding in Sector 4 market area. Traffic halted.",
              "team": ["Rajesh K.", "Sunil M.", "Amit S.", "Team B"],
            },
            {
              "id": "CRIT-205",
              "title": "Transformer Fire",
              "location": "Industrial Area Ph-1",
              "desc":
                  "Fire reported at Sub-station 4. Fire brigade on site. Power cut in 3 blocks.",
              "team": ["Vikram M.", "Fire Dept"],
            },
          ], context),

          const SizedBox(height: 20),

          // Medium Severity Group
          _buildPriorityGroup("Medium Priority", Colors.orange, [
            {
              "id": "MED-112",
              "title": "Traffic Light Malfunction",
              "location": "Gandhi Chowk",
              "desc": "All 4 lights stuck on red. Causing moderate congestion.",
              "team": ["Traffic Police", "Tech Team A"],
            },
          ], context),

          const SizedBox(height: 20),

          // Low Severity Group
          _buildPriorityGroup("Low Priority", Colors.blue, [
            {
              "id": "LOW-404",
              "title": "Park Bench Broken",
              "location": "Central Park",
              "desc": "Wooden bench broken near north gate.",
              "team": ["Parks Dept"],
            },
          ], context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStaffCard(
    String name,
    String status,
    String issue,
    Color statusColor,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: statusColor.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            issue,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityGroup(
    String title,
    Color color,
    List<Map<String, dynamic>> issues,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              color: color,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...issues.map((issue) => _buildIssueCard(issue, color, context)),
      ],
    );
  }

  Widget _buildIssueCard(
    Map<String, dynamic> issue,
    Color accentColor,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: accentColor,
            size: 20,
          ),
        ),
        title: Text(
          issue['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          issue['location'],
          style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
        ),
        trailing: TextButton(
          onPressed: () => _showIssueDetails(context, issue),
          child: const Text(
            "View Details",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- UPDATED METHOD: Fixed Closing Animation ---
  void _showIssueDetails(BuildContext context, Map<String, dynamic> issue) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Details",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250), // Slightly faster
      pageBuilder: (ctx, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            issue['title'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                Icons.confirmation_number_outlined,
                "ID: ${issue['id']}",
              ),
              const SizedBox(height: 8),
              _detailRow(Icons.location_on_outlined, issue['location']),
              const SizedBox(height: 16),
              const Text(
                "Description:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                issue['desc'],
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Current Team:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: (issue['team'] as List<String>)
                    .map(
                      (name) => Chip(
                        avatar: CircleAvatar(
                          child: Text(
                            name[0],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        label: Text(name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey[100],
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        // --- FIXED ANIMATION LOGIC ---
        // curve: easeOutBack (Bounce In)
        // reverseCurve: easeIn (Smooth Shrink Out - No bouncing)
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TAB B: ISSUES (WITH API INTEGRATION)
// ---------------------------------------------------------------------------

class _AdminIssuesTab extends StatefulWidget {
  const _AdminIssuesTab();

  @override
  State<_AdminIssuesTab> createState() => _AdminIssuesTabState();
}

class _AdminIssuesTabState extends State<_AdminIssuesTab> {
  List<SupervisorIssue> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SupervisorService.getRecentIssues();

      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _issues = result.data!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result.message ?? 'Failed to load issues';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading issues';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'ESCALATED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Unassigned';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          color: const Color(0xFFF5F7FA),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Issue Management",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Assign or reassign tasks to field workers",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadIssues,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadIssues,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_issues.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No issues found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadIssues,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _issues.length,
                itemBuilder: (context, index) {
                  return _buildIssueCard(_issues[index]);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIssueCard(SupervisorIssue issue) {
    final statusColor = _getStatusColor(issue.status);
    final hasAssignee =
        issue.assignedWorkerName != null &&
        issue.assignedWorkerName!.isNotEmpty;

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
              Text(
                '#${issue.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(issue.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issue.title ?? issue.type ?? 'Untitled Issue',
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
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  issue.location ?? 'Unknown location',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hasAssignee) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  "Assigned to: ${issue.assignedWorkerName}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // --- Assign/Reassign Button ---
          SizedBox(
            width: double.infinity,
            child: hasAssignee
                ? OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignIssuePage(
                            issueId: issue.id ?? '',
                            issueTitle: issue.title ?? issue.type ?? 'Issue',
                          ),
                        ),
                      ).then((_) => _loadIssues()); // Refresh on return
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Reassign",
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignIssuePage(
                            issueId: issue.id ?? '',
                            issueTitle: issue.title ?? issue.type ?? 'Issue',
                          ),
                        ),
                      ).then((_) => _loadIssues()); // Refresh on return
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Assign Worker",
                      style: TextStyle(
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
}

// ---------------------------------------------------------------------------
// TAB C: MAP (UNCHANGED VISUAL)
// ---------------------------------------------------------------------------

class _AdminMapTab extends StatelessWidget {
  const _AdminMapTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE3F2FD),
          child: Stack(
            children: [
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Positioned(
                top: 300,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 150,
                child: Container(
                  width: 20,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              _buildClusterMarker(100, 80, "12", Colors.orange),
              _buildClusterMarker(250, 200, "5", Colors.red),
              _buildClusterMarker(400, 120, "8", Colors.blue),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Hotspot Detected",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      "Sector 5 • 8 Critical Issues",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClusterMarker(double t, double l, String c, Color col) =>
      Positioned(
        top: t,
        left: l,
        child: CircleAvatar(
          backgroundColor: col,
          radius: 20,
          child: Text(c, style: const TextStyle(color: Colors.white)),
        ),
      );
}

// ---------------------------------------------------------------------------
// TAB D: PROFILE (WITH API INTEGRATION)
// ---------------------------------------------------------------------------

class _AdminProfileTab extends StatefulWidget {
  const _AdminProfileTab();

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  String _userName = 'Supervisor';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final fullName = await SecureStorageService.getFullName();
      final email = await SecureStorageService.getEmail();

      if (mounted) {
        setState(() {
          _userName = fullName ?? 'Supervisor';
          _userEmail = email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Perform logout
      await SupervisorService.logout();

      // Navigate to login screen
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 50,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (_userEmail.isNotEmpty)
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    const Text(
                      "City Supervisor",
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 32),
          _buildTile(Icons.people, "User Management"),
          _buildTile(Icons.settings, "System Settings"),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              child: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData i, String t) => ListTile(
    leading: Icon(i, color: const Color(0xFF1976D2)),
    title: Text(t, style: const TextStyle(fontFamily: 'Poppins')),
    trailing: const Icon(Icons.chevron_right),
  );
}
