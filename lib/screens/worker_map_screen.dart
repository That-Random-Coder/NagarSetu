import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/issue_service.dart';
import '../services/secure_storage_service.dart';
import '../models/issue_map_model.dart';
import '../widgets/lottie_loader.dart';
import 'issue_detail_screen.dart';

/// Worker Map Screen - Shows issues assigned to the worker
/// Uses /api/issue/map/worker endpoint
class WorkerMapScreen extends StatefulWidget {
  const WorkerMapScreen({super.key});

  @override
  State<WorkerMapScreen> createState() => _WorkerMapScreenState();
}

class _WorkerMapScreenState extends State<WorkerMapScreen> {
  final MapController _mapController = MapController();

  List<IssueMapModel> _issues = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingLocation = true;

  // View mode: 'stage' or 'criticality'
  String _viewMode = 'stage';

  // Default location, will be updated with user's location
  LatLng _userLocation = const LatLng(28.6120, 77.2050);
  LatLng _currentCenter = const LatLng(28.6120, 77.2050);
  double _currentZoom = 13.5;

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
        _mapController.move(_userLocation, 14.0);
      }
    } catch (e) {
      debugPrint('[WorkerMapScreen] Error getting location: $e');
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

    final workerId = await SecureStorageService.getUserId();
    if (workerId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Worker ID not found. Please login again.';
      });
      return;
    }

    final result = await IssueService.getIssueMapForWorker(workerId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _issues = result.data!;
          debugPrint('[WorkerMapScreen] Loaded ${_issues.length} issues');

          if (_issues.isNotEmpty) {
            final firstIssue = _issues.first;
            if (firstIssue.latitude != 0 && firstIssue.longitude != 0) {
              _mapController.move(
                LatLng(firstIssue.latitude, firstIssue.longitude),
                14.0,
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
              initialZoom: 14.0,
              minZoom: 10,
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
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isLoading && _issues.isNotEmpty)
                CircleLayer(
                  circles: _issues.map((issue) {
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
              if (!_isLoading && _issues.isNotEmpty)
                MarkerLayer(
                  markers: _issues.map((issue) {
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
                _buildViewModeToggle(),
                const SizedBox(height: 8),
                _buildLegend(),
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
                    _mapController.move(_userLocation, 14);
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: LottieLoader(size: 120, message: 'Loading your issues...'),
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
                        'No issues assigned to you yet',
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
          const Icon(Icons.map_outlined, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          const Text(
            'My Assigned Issues',
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
              '${_issues.length}',
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
}
