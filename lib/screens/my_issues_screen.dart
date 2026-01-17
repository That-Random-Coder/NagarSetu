import 'package:flutter/material.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatelessWidget {
  const MyIssuesScreen({super.key});

  static final List<Map<String, dynamic>> dummyIssues = [
    {
      'id': 'NS2026-001234',
      'title': 'Pothole on Main Street',
      'type': 'Road',
      'status': 'Resolved',
      'statusColor': Colors.green,
      'reportedDate': 'January 10, 2026',
      'location': 'Main Street, Sector 5',
      'description':
          'Large pothole causing traffic issues and risk to vehicles.',
      'latitude': 28.6139,
      'longitude': 77.2090,
      'timeline': [
        {
          'status': 'Resolved',
          'date': '03/18/2024',
          'description': 'Issue has been fixed',
        },
        {
          'status': 'In Progress',
          'date': '03/16/2024',
          'description': 'Assigned to team on 03/16/2024',
        },
        {
          'status': 'Team Assigned',
          'date': '03/17/2024',
          'description': 'Team dispatched on 03/17/2024',
        },
        {
          'status': 'Acknowledged',
          'date': '03/15/2024',
          'description': 'Reported on 03/15/2024',
        },
      ],
    },
    {
      'id': 'NS2026-001235',
      'title': 'Street Light Not Working',
      'type': 'Electricity',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'reportedDate': 'January 12, 2026',
      'location': 'Park Avenue, Block C',
      'description': 'Street light pole #45 has been out for 3 days.',
      'latitude': 28.6200,
      'longitude': 77.2150,
      'timeline': [
        {
          'status': 'In Progress',
          'date': '01/14/2026',
          'description': 'Assigned to team on 01/14/2026',
        },
        {
          'status': 'Team Assigned',
          'date': '01/13/2026',
          'description': 'Team dispatched on 01/13/2026',
        },
        {
          'status': 'Acknowledged',
          'date': '01/12/2026',
          'description': 'Reported on 01/12/2026',
        },
      ],
    },
    {
      'id': 'NS2026-001236',
      'title': 'Water Leakage',
      'type': 'Water',
      'status': 'Team Assigned',
      'statusColor': Colors.blue,
      'reportedDate': 'January 15, 2026',
      'location': 'Gandhi Road, Near Temple',
      'description': 'Water pipe burst causing water wastage.',
      'latitude': 28.6050,
      'longitude': 77.2000,
      'timeline': [
        {
          'status': 'Team Assigned',
          'date': '01/16/2026',
          'description': 'Team dispatched on 01/16/2026',
        },
        {
          'status': 'Acknowledged',
          'date': '01/15/2026',
          'description': 'Reported on 01/15/2026',
        },
      ],
    },
    {
      'id': 'NS2026-001237',
      'title': 'Garbage Not Collected',
      'type': 'Waste',
      'status': 'Acknowledged',
      'statusColor': Colors.grey,
      'reportedDate': 'January 16, 2026',
      'location': 'Nehru Colony, House 23',
      'description': 'Garbage has not been collected for 5 days.',
      'latitude': 28.6100,
      'longitude': 77.1950,
      'timeline': [
        {
          'status': 'Acknowledged',
          'date': '01/16/2026',
          'description': 'Reported on 01/16/2026',
        },
      ],
    },
    {
      'id': 'NS2026-001238',
      'title': 'Broken Drainage Cover',
      'type': 'Road',
      'status': 'Pending',
      'statusColor': Colors.red,
      'reportedDate': 'January 17, 2026',
      'location': 'MG Road, Near Bus Stop',
      'description':
          'Drainage cover is broken and causing safety hazard for pedestrians.',
      'latitude': 28.6180,
      'longitude': 77.1980,
      'timeline': [
        {
          'status': 'Pending',
          'date': '01/17/2026',
          'description': 'Waiting for acknowledgement',
        },
      ],
    },
  ];

  IconData _getIssueIcon(String type) {
    switch (type) {
      case 'Road':
        return Icons.add_road;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Water':
        return Icons.water_drop;
      case 'Waste':
        return Icons.delete_outline;
      default:
        return Icons.report_problem;
    }
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
          'My Issues',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyIssues.length,
        itemBuilder: (context, index) {
          final issue = dummyIssues[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueDetailScreen(issue: issue),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIssueIcon(issue['type']),
                        color: Colors.blue[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issue['location'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (issue['statusColor'] as Color)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  issue['status'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: issue['statusColor'],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                issue['reportedDate'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
