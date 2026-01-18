import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
import '../services/secure_storage_service.dart';
import '../models/admin_models.dart';
import 'login.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
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
            const SizedBox(height: 30),

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

            const SizedBox(height: 30),

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
          ],
        ),
      ),
    );
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
            indicator: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
            indicator: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
