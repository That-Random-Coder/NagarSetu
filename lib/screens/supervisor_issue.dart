import 'package:flutter/material.dart';
import '../services/supervisor_service.dart';
import '../services/secure_storage_service.dart';
import '../models/supervisor_models.dart';

class AssignIssuePage extends StatefulWidget {
  final String issueId;
  final String issueTitle;

  const AssignIssuePage({
    super.key,
    required this.issueId,
    required this.issueTitle,
  });

  @override
  State<AssignIssuePage> createState() => _AssignIssuePageState();
}

class _AssignIssuePageState extends State<AssignIssuePage> {
  final TextEditingController _searchController = TextEditingController();
  List<AssignableWorker> _allWorkers = [];
  List<AssignableWorker> _filteredWorkers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAssigning = false;

  // Theme Colors
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _searchController.addListener(_filterWorkers);
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await SupervisorService.getAllWorkers();

      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _allWorkers = result.data!;
            _filteredWorkers = _allWorkers;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result.message ?? 'Failed to load workers';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading workers';
          _isLoading = false;
        });
      }
    }
  }

  void _filterWorkers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        final name = (worker.username ?? '').toLowerCase();
        final dept = (worker.department ?? '').toLowerCase();
        final location = (worker.location ?? '').toLowerCase();
        return name.contains(query) ||
            dept.contains(query) ||
            location.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmAssignment(AssignableWorker worker) async {
    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Assignment",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assign ${worker.username ?? 'Worker'} to:",
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.issueId}: ${widget.issueTitle}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (worker.started == false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Warning: This worker is not yet approved.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Assign",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldAssign == true && mounted) {
      await _performAssignment(worker);
    }
  }

  Future<void> _performAssignment(AssignableWorker worker) async {
    if (worker.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot assign: Worker ID is missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      // Get current supervisor ID
      final supervisorId = await SecureStorageService.getUserId();

      if (supervisorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isAssigning = false);
        }
        return;
      }

      final result = await SupervisorService.reassignWorker(
        workerId: worker.id!,
        supervisorId: supervisorId,
      );

      if (mounted) {
        setState(() => _isAssigning = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Assigned to ${worker.username ?? 'Worker'}"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close Assign Screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "Assignment failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An error occurred during assignment"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Assign Worker",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- Search Bar ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name or department...",
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    filled: true,
                    fillColor: _backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // --- Worker List ---
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWorkers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredWorkers.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workers found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadWorkers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredWorkers.length,
                      itemBuilder: (context, index) {
                        final worker = _filteredWorkers[index];
                        return _buildWorkerCard(worker);
                      },
                    ),
                  ),
                ),
            ],
          ),
          // Loading overlay for assignment
          if (_isAssigning)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Assigning worker...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(AssignableWorker worker) {
    bool isAvailable = worker.started == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _confirmAssignment(worker),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: isAvailable
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                child: Text(
                  (worker.username ?? 'W').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.orange,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            worker.username ?? 'Unknown Worker',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Department Badge
                        if (worker.department != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              worker.department!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (worker.location != null)
                      Text(
                        worker.location!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable
                                ? Icons.check_circle
                                : Icons.timelapse_rounded,
                            size: 14,
                            color: isAvailable ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? "Approved" : "Pending Approval",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.green : Colors.orange,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
