import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock Data
  List<Map<String, dynamic>> notifications = [
    {
      "id": 1,
      "title": "Issue Resolved",
      "message": "The pothole reported at Main Street has been successfully repaired.",
      "time": "2 hours ago",
      "isRead": false,
      "type": "success" // for icon color
    },
    {
      "id": 2,
      "title": "Status Update",
      "message": "Your report #4829 is now 'In Progress'.",
      "time": "5 hours ago",
      "isRead": false,
      "type": "info"
    },
    {
      "id": 3,
      "title": "System Maintenance",
      "message": "The app will be down for maintenance tonight from 2 AM to 4 AM.",
      "time": "1 day ago",
      "isRead": true,
      "type": "warning"
    },
    {
      "id": 4,
      "title": "New Comment",
      "message": "Official Rajesh Kumar commented on your issue: 'Team is on the way.'",
      "time": "2 days ago",
      "isRead": true,
      "type": "message"
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read")),
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we have any unread
    bool hasUnread = notifications.any((n) => n['isRead'] == false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFF1976D2)),
              tooltip: "Mark all as read",
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: Key(item['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteNotification(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: _buildNotificationCard(item),
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item['isRead'] ? Colors.white : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getIconBgColor(item['type']),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(item['type']),
            color: _getIconColor(item['type']),
            size: 20,
          ),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontWeight: item['isRead'] ? FontWeight.w600 : FontWeight.bold,
            color: Colors.black87,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['message'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['time'],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        trailing: item['isRead']
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No Notifications",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods for Icons & Colors ---

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'message':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF1976D2);
    }
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.withOpacity(0.1);
      case 'warning':
        return Colors.orange.withOpacity(0.1);
      default:
        return const Color(0xFF1976D2).withOpacity(0.1);
    }
  }
}