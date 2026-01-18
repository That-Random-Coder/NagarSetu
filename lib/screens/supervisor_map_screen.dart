import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/supervisor_service.dart';
import '../services/secure_storage_service.dart';
import '../models/supervisor_models.dart';
import '../widgets/lottie_loader.dart';
import 'issue_detail_screen.dart';

/// Supervisor Map Screen with filter capabilities
/// Uses the /api/supervisior/filter endpoint to show filtered issues
class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({super.key});

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  final MapController _mapController = MapController();

  List<SupervisorMapIssue> _issues = [];
  bool _isLoading = false;
  String? _error;

  // Filter parameters
  String _selectedLocation = '';
  String _selectedStage = 'ALL';

  // Available stages for filtering
  final List<String> _stages = [
    'ALL',
    'PENDING',
    'ACKNOWLEDGED',
    'TEAM_ASSIGNED',
    'IN_PROGRESS',
    'RESOLVED',
    'RECONSIDERED',
  ];

  // View mode: 'stage' or 'criticality'
  String _viewMode = 'stage';

  // Default to Delhi, will be updated with user's location
  LatLng _userLocation = const LatLng(28.6120, 77.2050);
  LatLng _currentCenter = const LatLng(28.6120, 77.2050);
  double _currentZoom = 13.5;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getUserLocation();
    await _getCurrentLocation();
  }

  Future<void> _getUserLocation() async {
    // Try to get stored location first
    final userLocation = await SecureStorageService.getUserLocation();
    if (userLocation != null && userLocation.isNotEmpty) {
      setState(() {
        _selectedLocation = userLocation;
      });
      // Fetch issues with the stored location
      _fetchFilteredIssues();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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
        });

        _mapController.move(_userLocation, 14.0);
      }
    } catch (e) {
      debugPrint('[SupervisorMap] Error getting location: $e');
    }
  }

  Future<void> _fetchFilteredIssues() async {
    if (_selectedLocation.isEmpty) {
      _showLocationInputDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final stage = _selectedStage == 'ALL' ? 'PENDING' : _selectedStage;

    final result = await SupervisorService.filterIssues(
      location: _selectedLocation,
      stage: stage,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _issues = result.data!;
          debugPrint(
            '[SupervisorMap] Loaded ${_issues.length} filtered issues',
          );

          // Center on first issue if available
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

  void _showLocationInputDialog() {
    final controller = TextEditingController(text: _selectedLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_city, color: Color(0xFF1976D2)),
            SizedBox(width: 8),
            Text('Enter Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the city or area name to filter issues',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g., Delhi, Mumbai, Sector 5',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final location = controller.text.trim();
              if (location.isNotEmpty) {
                setState(() {
                  _selectedLocation = location;
                });
                Navigator.pop(context);
                _fetchFilteredIssues();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Color _getMarkerColor(SupervisorMapIssue issue) {
    if (_viewMode == 'criticality') {
      return _getCriticalityColor(issue.criticality);
    } else {
      return _getStatusColor(issue.stages);
    }
  }

  Color _getCircleColorForIssue(SupervisorMapIssue issue) {
    return _getMarkerColor(issue).withOpacity(0.25);
  }

  Color _getBorderColorForIssue(SupervisorMapIssue issue) {
    return _getMarkerColor(issue).withOpacity(0.7);
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
        return Colors.cyan;
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

  IconData _getIssueIcon(String issueType) {
    switch (issueType.toUpperCase()) {
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

  void _showIssueDetails(SupervisorMapIssue issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getMarkerColor(issue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIssueIcon(issue.issueType),
                    color: _getMarkerColor(issue),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.issueTypeDisplay,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(issue.stages).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          issue.statusDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(issue.stages),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.priority_high,
              'Criticality',
              issue.criticalityDisplay,
            ),
            _buildInfoRow(
              Icons.location_on,
              'Coordinates',
              '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
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
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Full Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation,
            initialZoom: 14.0,
            minZoom: 10,
            maxZoom: 18,
            onPositionChanged: (mapPosition, _) {
              setState(() {
                _currentCenter = mapPosition.center;
                _currentZoom = mapPosition.zoom;
              });
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
            // Issue circles
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
            // Issue markers
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
                              color: Colors.black.withOpacity(0.2),
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

        // Header with filters
        SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildFilterChips(),
              const SizedBox(height: 8),
              _buildViewModeToggle(),
              const SizedBox(height: 8),
              _buildLegend(),
            ],
          ),
        ),

        // Map controls
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              _buildMapButton(icon: Icons.refresh, onTap: _fetchFilteredIssues),
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

        // Loading indicator
        if (_isLoading)
          const Center(
            child: LottieLoader(size: 120, message: 'Loading issues...'),
          ),

        // Error state
        if (_error != null && !_isLoading)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchFilteredIssues,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

        // Empty state
        if (!_isLoading &&
            _error == null &&
            _issues.isEmpty &&
            _selectedLocation.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                    'No Issues Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No issues match your current filter',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

        // Prompt to enter location
        if (_selectedLocation.isEmpty && !_isLoading)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showLocationInputDialog,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_searching,
                        color: Color(0xFF1976D2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Location to View Issues',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to enter your area or city',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: Color(0xFF1976D2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supervisor Map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (_selectedLocation.isNotEmpty)
                  GestureDetector(
                    onTap: _showLocationInputDialog,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedLocation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
              ],
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

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final isSelected = _selectedStage == stage;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                stage == 'ALL' ? 'All Stages' : _formatStageName(stage),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStage = stage;
                });
                _fetchFilteredIssues();
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1976D2),
              checkmarkColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
            ),
          );
        },
      ),
    );
  }

  String _formatStageName(String stage) {
    return stage
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
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
            color: Colors.black.withOpacity(0.1),
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
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _viewMode == 'criticality'
            ? [
                _buildLegendItem(Colors.red, 'High'),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.orange, 'Medium'),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.green, 'Low'),
              ]
            : [
                _buildLegendItem(Colors.red, 'Pending'),
                const SizedBox(width: 8),
                _buildLegendItem(Colors.orange, 'In Progress'),
                const SizedBox(width: 8),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey[700], size: 22),
      ),
    );
  }
}
