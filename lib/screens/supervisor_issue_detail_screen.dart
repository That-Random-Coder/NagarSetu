import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/environment.dart';
import '../services/supervisor_service.dart';
import '../models/supervisor_models.dart';
import '../widgets/lottie_loader.dart';
import 'supervisor_issue.dart';

class SupervisorIssueDetailScreen extends StatefulWidget {
  final String issueId;

  const SupervisorIssueDetailScreen({super.key, required this.issueId});

  @override
  State<SupervisorIssueDetailScreen> createState() =>
      _SupervisorIssueDetailScreenState();
}

class _SupervisorIssueDetailScreenState
    extends State<SupervisorIssueDetailScreen> {
  SupervisorIssue? _issue;
  Map<String, String?>? _workerInfo;
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

    // Fetch issue details and worker info in parallel
    final results = await Future.wait([
      SupervisorService.getIssueById(widget.issueId),
      SupervisorService.getIssueWorker(widget.issueId),
    ]);

    final issueResult = results[0] as SupervisorApiResult<SupervisorIssue>;
    final workerResult =
        results[1] as SupervisorApiResult<Map<String, String?>>;

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (issueResult.success && issueResult.data != null) {
          _issue = issueResult.data;
          if (workerResult.success && workerResult.data != null) {
            _workerInfo = workerResult.data;
          }
        } else {
          _error = issueResult.message ?? 'Failed to load issue details';
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase().replaceAll('_', ' ')) {
      case 'RESOLVED':
        return Colors.green;
      case 'IN PROGRESS':
        return Colors.orange;
      case 'TEAM ASSIGNED':
        return Colors.blue;
      case 'ACKNOWLEDGED':
        return Colors.purple;
      case 'PENDING':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCriticalityColor(String criticality) {
    switch (criticality.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
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
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double connectorWidth = 20;
          const double minStageWidth = 58;
          final double totalMinWidth =
              stages.length * minStageWidth +
              (stages.length - 1) * connectorWidth;
          final bool needsScroll = totalMinWidth > constraints.maxWidth;

          Widget buildStage(int i, double stageWidth) {
            final stage = stages[i];
            final bool completed = i < currentIndex;
            final bool active = i == currentIndex;
            final Color stageColor = stage['color'] as Color;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: stageWidth,
                  child: Column(
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
                        width: stageWidth,
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
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != stages.length - 1)
                  SizedBox(
                    width: connectorWidth,
                    child: Center(
                      child: Container(
                        width: needsScroll ? 16 : 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i < currentIndex
                              ? Colors.green
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          if (needsScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(
                  stages.length,
                  (i) => buildStage(i, minStageWidth),
                ),
              ),
            );
          }

          final double availableStageWidth =
              ((constraints.maxWidth - (stages.length - 1) * connectorWidth) /
                      stages.length)
                  .clamp(48.0, 120.0);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              stages.length,
              (i) => buildStage(i, availableStageWidth),
            ),
          );
        },
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
        actions: [
          if (_issue != null)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[600]),
              onPressed: _fetchIssueDetails,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _issue != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBottomBar() {
    final hasWorker =
        _workerInfo != null &&
        _workerInfo!['workerName'] != null &&
        _workerInfo!['workerName']!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssignIssuePage(
                  issueId: _issue!.id,
                  issueTitle: _issue!.title.isNotEmpty
                      ? _issue!.title
                      : _issue!.issueTypeDisplay,
                ),
              ),
            ).then((_) => _fetchIssueDetails());
          },
          icon: Icon(hasWorker ? Icons.swap_horiz : Icons.person_add),
          label: Text(hasWorker ? 'Reassign Worker' : 'Assign Worker'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
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
    final hasWorker =
        _workerInfo != null &&
        _workerInfo!['workerName'] != null &&
        _workerInfo!['workerName']!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Timeline
          _buildHorizontalTimeline(issue.stages),

          // Issue Image
          if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CloudinaryImage(url: issue.imageUrl!),
            const SizedBox(height: 16),
          ],

          // Issue Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    issue.title.isNotEmpty
                        ? issue.title
                        : issue.issueTypeDisplay,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status & Criticality Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            issue.stages,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.statusDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(issue.stages),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCriticalityColor(
                            issue.criticality,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.criticality,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getCriticalityColor(issue.criticality),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (issue.createdAt != null)
                        Text(
                          _formatDate(issue.createdAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description.isNotEmpty
                        ? issue.description
                        : 'No description provided',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          issue.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Issue Type
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        issue.issueTypeDisplay,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  if (issue.submittedBy != null &&
                      issue.submittedBy!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Submitted by: ${issue.submittedBy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Worker Assignment Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
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
                      Icon(
                        Icons.engineering,
                        size: 20,
                        color: hasWorker ? Colors.blue : Colors.grey[400],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Assigned Worker',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasWorker)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: Text(
                              _workerInfo!['workerName']![0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _workerInfo!['workerName']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Worker ID: ${_workerInfo!['workerId']?.substring(0, 8) ?? 'N/A'}...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Assigned',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Worker Assigned',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Assign a worker to start work on this issue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
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

          const SizedBox(height: 16),

          // Map
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
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
                          color: _getCriticalityColor(issue.criticality),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _CloudinaryImage extends StatefulWidget {
  final String url;
  const _CloudinaryImage({required this.url});

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
  }

  List<String> _buildCandidates(String original) {
    final List<String> list = [];
    list.add(original);

    final uri = Uri.tryParse(original);
    if (uri != null) {
      final base = uri
          .replace(queryParameters: {}, fragment: '')
          .toString()
          .split('?')
          .first;
      if (!list.contains(base)) list.add(base);

      final hasExt = base.split('/').last.contains('.');
      if (!hasExt) {
        if (!list.contains('$base.jpg')) list.add('$base.jpg');
        if (!list.contains('$base.png')) list.add('$base.png');
      }
    }

    return list;
  }

  void _tryNext() {
    if (_index < _candidates.length - 1) {
      setState(() => _index += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _candidates[_index];
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
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
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _tryNext());
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            );
          },
        ),
      ),
    );
  }
}
