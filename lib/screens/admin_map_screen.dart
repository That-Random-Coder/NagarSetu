import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/issue_service.dart';
import '../services/hotspot_service.dart';
import '../models/issue_map_model.dart';
import '../models/hotspot_model.dart';
import '../widgets/lottie_loader.dart';
import 'issue_detail_screen.dart';
import 'admin_hotspots_screen.dart';

/// Admin Map Screen - Shows all issues for admin oversight
/// Uses /api/issue/map/admin endpoint
class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();

  List<IssueMapModel> _issues = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingLocation = true;

  // View mode: 'stage' or 'criticality'
  String _viewMode = 'stage';

  // Hotspot visualization
  bool _showHotspots = false;
  List<HotspotModel> _hotspots = [];

  // Filter by issue type
  String _selectedIssueType = 'ALL';
  final List<String> _issueTypes = [
    'ALL',
    'ROAD',
    'WATER',
    'GARBAGE',
    'VEHICLE',
    'STREETLIGHT',
    'OTHER',
  ];

  // Default location, will be updated with user's location
  LatLng _userLocation = const LatLng(28.6120, 77.2050);
  LatLng _currentCenter = const LatLng(28.6120, 77.2050);
  double _currentZoom = 12.0;

  List<IssueMapModel> get _filteredIssues {
    if (_selectedIssueType == 'ALL') return _issues;
    return _issues
        .where(
          (issue) =>
              issue.issueType.toUpperCase() == _selectedIssueType.toUpperCase(),
        )
        .toList();
  }

  Color _getMarkerColor(IssueMapModel issue) {
    if (_viewMode == 'criticality') {
      return _getCriticalityColor(issue.criticality);
    } else {
      return _getStatusColor(issue.stages);
    }
  }

  Color _getCircleColorForIssue(IssueMapModel issue) {
    return _getMarkerColor(issue).withValues(alpha: 0.25);
  }

  Color _getBorderColorForIssue(IssueMapModel issue) {
    return _getMarkerColor(issue).withValues(alpha: 0.7);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'TEAM_ASSIGNED':
        return Colors.blue;
      case 'ACKNOWLEDGED':
        return Colors.blue;
      case 'RECONSIDERED':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }

  Color _getCriticalityColor(String criticality) {
    switch (criticality.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIssueIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROAD':
        return Icons.add_road;
      case 'WATER':
        return Icons.water_drop;
      case 'GARBAGE':
        return Icons.delete;
      case 'VEHICLE':
        return Icons.directions_car;
      case 'STREETLIGHT':
        return Icons.lightbulb;
      default:
        return Icons.report_problem;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _fetchIssues();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _currentCenter = _userLocation;
          _isLoadingLocation = false;
        });
        _mapController.move(_userLocation, 12.0);
      }
    } catch (e) {
      debugPrint('[AdminMapScreen] Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchIssues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await IssueService.getIssueMapForAdmin();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _issues = result.data!;
          // Compute hotspots from issues
          _hotspots = HotspotService.detectHotspots(_issues);
          debugPrint(
            '[AdminMapScreen] Loaded ${_issues.length} issues, ${_hotspots.length} hotspots',
          );

          if (_issues.isNotEmpty) {
            final firstIssue = _issues.first;
            if (firstIssue.latitude != 0 && firstIssue.longitude != 0) {
              _mapController.move(
                LatLng(firstIssue.latitude, firstIssue.longitude),
                12.0,
              );
            }
          }
        } else {
          _error = result.message ?? 'Failed to load issues';
        }
      });
    }
  }

  void _showIssueDetails(IssueMapModel issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssueDetailScreen(issueId: issue.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 12.0,
              minZoom: 8,
              maxZoom: 18,
              onPositionChanged: (mapPosition, _) {
                if (mapPosition.center != null && mapPosition.zoom != null) {
                  setState(() {
                    _currentCenter = mapPosition.center!;
                    _currentZoom = mapPosition.zoom!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nagarsetu.app',
              ),
              // Hotspot overlay circles (shown below issue markers)
              if (_showHotspots && _hotspots.isNotEmpty)
                CircleLayer(
                  circles: _hotspots.map((hotspot) {
                    return CircleMarker(
                      point: hotspot.center,
                      radius: hotspot.radiusMeters,
                      useRadiusInMeter: true,
                      color: hotspot.overlayColor,
                      borderColor: hotspot.borderColor,
                      borderStrokeWidth: 3,
                    );
                  }).toList(),
                ),
              // User location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              // Hotspot center markers (when hotspots are shown)
              if (_showHotspots && _hotspots.isNotEmpty)
                MarkerLayer(
                  markers: _hotspots.map((hotspot) {
                    return Marker(
                      point: hotspot.center,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showHotspotInfo(hotspot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: hotspot.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: hotspot.color.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(hotspot.icon, color: Colors.white, size: 16),
                              Text(
                                '${hotspot.issueCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (!_isLoading && _filteredIssues.isNotEmpty && !_showHotspots)
                CircleLayer(
                  circles: _filteredIssues.map((issue) {
                    return CircleMarker(
                      point: LatLng(issue.latitude, issue.longitude),
                      radius: 80,
                      useRadiusInMeter: true,
                      color: _getCircleColorForIssue(issue),
                      borderColor: _getBorderColorForIssue(issue),
                      borderStrokeWidth: 2,
                    );
                  }).toList(),
                ),
              if (!_isLoading && _filteredIssues.isNotEmpty && !_showHotspots)
                MarkerLayer(
                  markers: _filteredIssues.map((issue) {
                    return Marker(
                      point: LatLng(issue.latitude, issue.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showIssueDetails(issue),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getMarkerColor(issue),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIssueIcon(issue.issueType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 8),
                _buildHotspotToggle(),
                const SizedBox(height: 8),
                if (!_showHotspots) _buildViewModeToggle(),
                if (!_showHotspots) const SizedBox(height: 8),
                if (!_showHotspots) _buildIssueTypeFilter(),
                const SizedBox(height: 8),
                _showHotspots ? _buildHotspotLegend() : _buildLegend(),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _buildMapButton(icon: Icons.refresh, onTap: _fetchIssues),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.add,
                  onTap: () {
                    _mapController.move(_currentCenter, _currentZoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  onTap: () {
                    _mapController.move(_currentCenter, _currentZoom - 1);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _getCurrentLocation();
                    _mapController.move(_userLocation, 12);
                  },
                ),
                if (_showHotspots && _hotspots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.list_alt_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminHotspotsScreen(hotspots: _hotspots),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          // Stats summary at bottom left
          Positioned(
            bottom: 100,
            left: 16,
            child: _showHotspots
                ? _buildHotspotSummary()
                : _buildStatsSummary(),
          ),
          if (_isLoading)
            const Center(
              child: LottieLoader(size: 120, message: 'Loading all issues...'),
            ),
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchIssues,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (!_isLoading && _error == null && _issues.isEmpty)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No issues reported in the system',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          const Text(
            'Admin Map View',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredIssues.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Stage', 'stage'),
          _buildToggleButton('Criticality', 'criticality'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypeFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _issueTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _issueTypes[index];
          final isSelected = _selectedIssueType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedIssueType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1976D2) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type != 'ALL')
                    Icon(
                      _getIssueIcon(type),
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  if (type != 'ALL') const SizedBox(width: 4),
                  Text(
                    type == 'ALL'
                        ? 'All'
                        : type[0] + type.substring(1).toLowerCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    final items = _viewMode == 'stage'
        ? [
            {'color': Colors.red, 'label': 'Pending'},
            {'color': Colors.blue, 'label': 'Acknowledged'},
            {'color': Colors.orange, 'label': 'In Progress'},
            {'color': Colors.green, 'label': 'Resolved'},
          ]
        : [
            {'color': Colors.red, 'label': 'High'},
            {'color': Colors.orange, 'label': 'Medium'},
            {'color': Colors.green, 'label': 'Low'},
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final pending = _issues.where((i) => i.stages == 'PENDING').length;
    final inProgress = _issues.where((i) => i.stages == 'IN_PROGRESS').length;
    final resolved = _issues.where((i) => i.stages == 'RESOLVED').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Pending', pending, Colors.red),
          _buildStatRow('In Progress', inProgress, Colors.orange),
          _buildStatRow('Resolved', resolved, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF1976D2)),
        ),
      ),
    );
  }

  // Hotspot toggle button
  Widget _buildHotspotToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHotspotToggleButton('Issues', false),
          _buildHotspotToggleButton('Hotspots', true),
        ],
      ),
    );
  }

  Widget _buildHotspotToggleButton(String label, bool showHotspots) {
    final isSelected = _showHotspots == showHotspots;
    final color = showHotspots ? Colors.red : const Color(0xFF1976D2);
    return GestureDetector(
      onTap: () => setState(() => _showHotspots = showHotspots),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showHotspots
                  ? Icons.warning_amber_rounded
                  : Icons.report_problem_rounded,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (showHotspots && _hotspots.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_hotspots.length}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Hotspot legend
  Widget _buildHotspotLegend() {
    final items = [
      {'color': Colors.red.shade800, 'label': 'Critical'},
      {'color': Colors.red, 'label': 'High'},
      {'color': Colors.orange, 'label': 'Moderate'},
      {'color': Colors.yellow.shade700, 'label': 'Low'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Hotspot summary panel
  Widget _buildHotspotSummary() {
    final summary = HotspotService.getHotspotSummary(_hotspots);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Hotspots',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHotspotStatRow('Total', summary['total'] ?? 0, Colors.white),
          _buildHotspotStatRow(
            'Critical',
            summary['critical'] ?? 0,
            Colors.red.shade200,
          ),
          _buildHotspotStatRow(
            'High',
            summary['high'] ?? 0,
            Colors.red.shade100,
          ),
          _buildHotspotStatRow(
            'Moderate',
            summary['moderate'] ?? 0,
            Colors.orange.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotStatRow(String label, int count, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Show hotspot info dialog
  void _showHotspotInfo(HotspotModel hotspot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: hotspot.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(hotspot.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotspot.locality,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hotspot.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${hotspot.severityLabel} Severity',
                            style: TextStyle(
                              color: hotspot.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildInfoStat(
                    'Issues',
                    hotspot.issueCount.toString(),
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoStat(
                    'High',
                    hotspot.highCriticalityCount.toString(),
                    Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoStat(
                    'Medium',
                    hotspot.mediumCriticalityCount.toString(),
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoStat(
                    'Low',
                    hotspot.lowCriticalityCount.toString(),
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Score bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hotspot Score',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        '${hotspot.hotspotScore.toInt()}/100',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hotspot.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hotspot.hotspotScore / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(hotspot.color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
              if (hotspot.topIssueTypes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Top Issue Types',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: hotspot.topIssueTypes.map((type) {
                    return Chip(
                      label: Text(type, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
