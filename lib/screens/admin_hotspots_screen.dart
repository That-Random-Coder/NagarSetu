import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hotspot_model.dart';

/// Screen to display all detected hotspots with filtering options
class AdminHotspotsScreen extends StatefulWidget {
  final List<HotspotModel> hotspots;

  const AdminHotspotsScreen({super.key, required this.hotspots});

  @override
  State<AdminHotspotsScreen> createState() => _AdminHotspotsScreenState();
}

class _AdminHotspotsScreenState extends State<AdminHotspotsScreen> {
  HotspotSeverity? _selectedSeverity;
  String _sortBy = 'score'; // 'score', 'issues', 'name'

  List<HotspotModel> get _filteredHotspots {
    var filtered = widget.hotspots;

    // Filter by severity
    if (_selectedSeverity != null) {
      filtered = filtered
          .where((h) => h.severity == _selectedSeverity)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'score':
        filtered.sort((a, b) => b.hotspotScore.compareTo(a.hotspotScore));
        break;
      case 'issues':
        filtered.sort((a, b) => b.issueCount.compareTo(a.issueCount));
        break;
      case 'name':
        filtered.sort((a, b) => a.locality.compareTo(b.locality));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hotspot Areas',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF1976D2),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          _buildSummaryHeader(),

          // Filter chips
          _buildFilterChips(),

          // Hotspots List
          Expanded(
            child: _filteredHotspots.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHotspots.length,
                    itemBuilder: (context, index) {
                      return _buildHotspotCard(
                        _filteredHotspots[index],
                        index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final critical = widget.hotspots
        .where((h) => h.severity == HotspotSeverity.critical)
        .length;
    final high = widget.hotspots
        .where((h) => h.severity == HotspotSeverity.high)
        .length;
    final moderate = widget.hotspots
        .where((h) => h.severity == HotspotSeverity.moderate)
        .length;
    final low = widget.hotspots
        .where((h) => h.severity == HotspotSeverity.low)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.orange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.hotspots.length} Hotspots Detected',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryChip('Critical', critical, Colors.red[900]!),
              _buildSummaryChip('High', high, Colors.red),
              _buildSummaryChip('Moderate', moderate, Colors.orange),
              _buildSummaryChip('Low', low, Colors.yellow[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('All', null),
          _buildChip('Critical', HotspotSeverity.critical),
          _buildChip('High', HotspotSeverity.high),
          _buildChip('Moderate', HotspotSeverity.moderate),
          _buildChip('Low', HotspotSeverity.low),
        ],
      ),
    );
  }

  Widget _buildChip(String label, HotspotSeverity? severity) {
    final isSelected = _selectedSeverity == severity;
    Color chipColor;

    if (severity == null) {
      chipColor = const Color(0xFF1976D2);
    } else {
      switch (severity) {
        case HotspotSeverity.critical:
          chipColor = Colors.red[900]!;
          break;
        case HotspotSeverity.high:
          chipColor = Colors.red;
          break;
        case HotspotSeverity.moderate:
          chipColor = Colors.orange;
          break;
        case HotspotSeverity.low:
          chipColor = Colors.yellow[700]!;
          break;
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = severity),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : Colors.grey[300]!),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHotspotCard(HotspotModel hotspot, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hotspot.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hotspot.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotspot.locality,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${hotspot.issueCount} issues in this area',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hotspot.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hotspot.icon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        hotspot.severityLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Criticality breakdown
                Row(
                  children: [
                    _buildCriticalityStat(
                      'High',
                      hotspot.highCriticalityCount,
                      Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildCriticalityStat(
                      'Medium',
                      hotspot.mediumCriticalityCount,
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildCriticalityStat(
                      'Low',
                      hotspot.lowCriticalityCount,
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
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${hotspot.hotspotScore.toInt()}/100',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hotspot.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hotspot.hotspotScore / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(hotspot.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),

                // Issue types
                if (hotspot.topIssueTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Top issues: ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          hotspot.topIssueTypes.join(', '),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalityStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedSeverity != null
                ? 'No ${_selectedSeverity!.name} severity hotspots'
                : 'No hotspots detected',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'The city is in good condition!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption(
                    'Hotspot Score (Highest First)',
                    'score',
                    setModalState,
                  ),
                  _buildSortOption(
                    'Issue Count (Most First)',
                    'issues',
                    setModalState,
                  ),
                  _buildSortOption(
                    'Location Name (A-Z)',
                    'name',
                    setModalState,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setModalState(() {});
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1976D2).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF1976D2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF1976D2) : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
