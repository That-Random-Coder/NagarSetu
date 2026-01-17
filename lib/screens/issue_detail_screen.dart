import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/environment.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../widgets/lottie_loader.dart';

class IssueDetailScreen extends StatefulWidget {
  final String issueId;

  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  IssueModel? _issue;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIssueDetails();
  }

  Future<void> _fetchIssueDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await IssueService.getIssueById(widget.issueId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _issue = result.data;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'team assigned':
        return Colors.blue;
      case 'acknowledged':
        return Colors.grey;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in progress':
        return Icons.autorenew;
      case 'team assigned':
        return Icons.groups;
      case 'acknowledged':
        return Icons.visibility;
      default:
        return Icons.circle;
    }
  }

  Widget _buildHorizontalTimeline(String currentStatus) {
    final stages = [
      {
        'key': 'PENDING',
        'label': 'Pending',
        'icon': Icons.hourglass_empty,
        'color': Colors.red,
      },
      {
        'key': 'ACKNOWLEDGED',
        'label': 'Acknowledged',
        'icon': Icons.visibility,
        'color': Colors.blue,
      },
      {
        'key': 'TEAM_ASSIGNED',
        'label': 'Team Assigned',
        'icon': Icons.groups,
        'color': Colors.purple,
      },
      {
        'key': 'IN_PROGRESS',
        'label': 'In Progress',
        'icon': Icons.autorenew,
        'color': Colors.orange,
      },
      {
        'key': 'RESOLVED',
        'label': 'Resolved',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    int currentIndex = stages.indexWhere((s) {
      final normalizedStage = (s['key'] as String)
          .replaceAll(RegExp(r'[_\s]+'), '')
          .toLowerCase();
      final normalizedCurrent = currentStatus
          .replaceAll(RegExp(r'[_\s]+'), '')
          .toLowerCase();
      return normalizedStage == normalizedCurrent;
    });

    if (currentIndex == -1) currentIndex = 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(stages.length, (i) {
          final stage = stages[i];
          final bool completed = i < currentIndex;
          final bool active = i == currentIndex;
          final Color stageColor = stage['color'] as Color;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.green
                          : (active
                                ? stageColor.withOpacity(0.15)
                                : Colors.grey[100]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: completed
                            ? Colors.green
                            : (active ? stageColor : Colors.grey[300]!),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        completed ? Icons.check : stage['icon'] as IconData,
                        color: completed
                            ? Colors.white
                            : (active ? stageColor : Colors.grey[500]),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 58,
                    child: Text(
                      stage['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: active
                            ? stageColor
                            : (completed ? Colors.green : Colors.grey[600]),
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != stages.length - 1)
                Container(
                  width: 20,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: i < currentIndex ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Issue Details',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LottieLoader(size: 120, message: 'Loading issue details...'),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchIssueDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_issue == null) {
      return Center(
        child: Text(
          'Issue not found',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return _buildIssueContent();
  }

  Widget _buildIssueContent() {
    final issue = _issue!;
    final LatLng location = LatLng(issue.latitude, issue.longitude);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Timeline
          _buildHorizontalTimeline(issue.status),

          // Issue Image
          if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CloudinaryImage(url: issue.imageUrl!),
            const SizedBox(height: 16),
          ],

          // Description / Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Issue ID: ',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      Expanded(
                        child: Text(
                          '#${issue.id}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    issue.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          issue.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            issue.status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(issue.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Map below description
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(initialCenter: location, initialZoom: 15.0),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nagarsetu.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.blue[600],
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CloudinaryImage extends StatefulWidget {
  final String url;
  const _CloudinaryImage({Key? key, required this.url}) : super(key: key);

  @override
  State<_CloudinaryImage> createState() => _CloudinaryImageState();
}

class _CloudinaryImageState extends State<_CloudinaryImage> {
  late final List<String> _candidates;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.url);
    if (Environment.enableLogging) {
      print('Image candidates: $_candidates');
    }
  }

  List<String> _buildCandidates(String original) {
    final List<String> list = [];
    list.add(original);

    final uri = Uri.tryParse(original);
    if (uri != null) {
      // Strip query params and fragment
      final base = uri
          .replace(queryParameters: {}, fragment: '')
          .toString()
          .split('?')
          .first;
      if (!list.contains(base)) list.add(base);

      // If there's no extension, try common ones
      final hasExt = base.split('/').last.contains('.');
      if (!hasExt) {
        if (!list.contains('$base.jpg')) list.add('$base.jpg');
        if (!list.contains('$base.png')) list.add('$base.png');
        if (!list.contains('$base.jpeg')) list.add('$base.jpeg');
      }

      // Try adding format param
      if (!original.contains('?')) {
        final withFormat = '$original?format=jpg';
        if (!list.contains(withFormat)) list.add(withFormat);
      }
    }

    return list;
  }

  void _tryNext() {
    if (_index < _candidates.length - 1) {
      setState(() {
        _index += 1;
        if (Environment.enableLogging)
          print('Retrying image with: ${_candidates[_index]}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _candidates[_index];
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) {
            if (Environment.enableLogging)
              print('Image load error: $error for URL: $url');
            // Try next candidate
            WidgetsBinding.instance.addPostFrameCallback((_) => _tryNext());
            return Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
