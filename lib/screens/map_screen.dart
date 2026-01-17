import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/issue_service.dart';
import '../models/issue_map_model.dart';
import '../widgets/lottie_loader.dart';
import 'issue_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<IssueMapModel> _issues = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingLocation = true;

  // Default to Delhi, will be updated with user's location
  LatLng _userLocation = const LatLng(28.6120, 77.2050);
  LatLng _currentCenter = const LatLng(28.6120, 77.2050);
  double _currentZoom = 13.5;

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

  Color _getCircleColor(String status) {
    final c = _getStatusColor(status);
    return c.withOpacity(0.25);
  }

  Color _getBorderColor(String status) {
    final c = _getStatusColor(status);
    return c.withOpacity(0.7);
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
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[MapScreen] Location services are disabled');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[MapScreen] Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[MapScreen] Location permission permanently denied');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '[MapScreen] Got location: ${position.latitude}, ${position.longitude}',
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _currentCenter = _userLocation;
          _isLoadingLocation = false;
        });

        // Move map to user location
        _mapController.move(_userLocation, 14.0);
      }
    } catch (e) {
      debugPrint('[MapScreen] Error getting location: $e');
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

    final result = await IssueService.getIssuesForMap();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _issues = result.data!;
          debugPrint('[MapScreen] Loaded ${_issues.length} issues');

          // If we have issues and got location, center on first issue or user location
          if (_issues.isNotEmpty) {
            // Move to first issue location if available
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

  Future<void> _testApiConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final results = await IssueService.testApiConnection();

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Build issue locations string
    String issueLocations = _issues.isEmpty
        ? 'No issues'
        : _issues
              .take(3)
              .map(
                (i) =>
                    '${i.issueTypeDisplay}: (${i.latitude.toStringAsFixed(4)}, ${i.longitude.toStringAsFixed(4)})',
              )
              .join('\n');
    if (_issues.length > 3) {
      issueLocations += '\n... and ${_issues.length - 3} more';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugRow(
                'Base URL',
                results['baseUrl']?.toString() ?? 'N/A',
              ),
              _buildDebugRow(
                'Has Token',
                results['hasToken']?.toString() ?? 'N/A',
              ),
              _buildDebugRow('User ID', results['userId']?.toString() ?? 'N/A'),
              _buildDebugRow(
                'Success',
                results['success']?.toString() ?? 'N/A',
              ),
              _buildDebugRow('Issues on Map', '${_issues.length}'),
              _buildDebugRow(
                'User Location',
                '${_userLocation.latitude.toStringAsFixed(4)}, ${_userLocation.longitude.toStringAsFixed(4)}',
              ),
              if (_issues.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Issue Locations:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(issueLocations, style: const TextStyle(fontSize: 11)),
              ],
              if (results['error'] != null)
                _buildDebugRow('Error', results['error'].toString()),
              if (results['mapEndpoint'] != null) ...[
                const Divider(),
                const Text(
                  'Map Endpoint:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildDebugRow(
                  'URL',
                  results['mapEndpoint']['url']?.toString() ?? 'N/A',
                ),
                _buildDebugRow(
                  'Status Code',
                  results['mapEndpoint']['statusCode']?.toString() ?? 'N/A',
                ),
                _buildDebugRow(
                  'Status',
                  results['mapEndpoint']['statusMessage']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Response:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    results['mapEndpoint']['body']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchIssues();
            },
            child: const Text('Refresh Map'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
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
                            color: Colors.blue.withOpacity(0.3),
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
                      color: _getCircleColor(issue.stages),
                      borderColor: _getBorderColor(issue.stages),
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
                            color: _getStatusColor(issue.stages),
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
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.refresh,
                  onTap: () {
                    _fetchIssues();
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.bug_report,
                  onTap: _testApiConnection,
                ),
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
              child: LottieLoader(size: 120, message: 'Loading issues...'),
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
          // Show empty state when no issues
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No Issues Reported Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Report an issue to see it on the map',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[700], size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Issue Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_issues.length} Issues',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.red, 'Pending'),
          _buildLegendItem(Colors.orange, 'In Progress'),
          _buildLegendItem(Colors.blue, 'Acknowledged'),
          _buildLegendItem(Colors.green, 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey[700], size: 22),
      ),
    );
  }

  IconData _getIssueIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROAD':
        return Icons.add_road;
      case 'ELECTRICITY':
        return Icons.electrical_services;
      case 'WATER':
        return Icons.water_drop;
      case 'GARBAGE':
        return Icons.delete_outline;
      case 'VEHICLE':
        return Icons.directions_car;
      case 'OTHER':
        return Icons.report_problem;
      default:
        return Icons.report_problem;
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

  void _showIssueDetails(IssueMapModel issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.stages).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIssueIcon(issue.issueType),
                    color: _getStatusColor(issue.stages),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.issueTypeDisplay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${issue.latitude.toStringAsFixed(4)}, Lng: ${issue.longitude.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.stages).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(issue.stages),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.statusDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(issue.stages),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getCriticalityColor(
                      issue.criticality,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: _getCriticalityColor(issue.criticality),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue.criticalityDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getCriticalityColor(issue.criticality),
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
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              IssueDetailScreen(issueId: issue.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
