// ========================================
// MOBILE APP - NOTIFICATIONS SCREEN
// Displays system and file notifications
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../widgets/glass_container.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when screen opens? Or maybe not automatically.
    // Let's leave it manual or on-tap for now, or just simply display them.
  }

  // Group notifications by date (Today, Yesterday, Older)
  Map<String, List<AppNotification>> _groupNotificationsByDate(List<AppNotification> notifications) {
    final grouped = <String, List<AppNotification>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notification in notifications) {
      final date = notification.timestamp.toLocal();
      final notificationDate = DateTime(date.year, date.month, date.day);
      
      if (notificationDate == today) {
        grouped['Today']!.add(notification);
      } else if (notificationDate == yesterday) {
        grouped['Yesterday']!.add(notification);
      } else {
        grouped['Older']!.add(notification);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }
  
  void _clearAll(BuildContext context) {
    final service = Provider.of<NotificationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Delete all notifications?'),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text('Cancel'),
          ),
          TextButton(
             onPressed: () {
               service.clearAllNotifications();
               Navigator.pop(ctx);
             },
             child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppConstants.getBackgroundGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
              onPressed: () => _clearAll(context),
            ),
          ],
        ),
        body: Consumer<NotificationService>(
          builder: (context, notificationService, child) {
            final notifications = notificationService.notifications;
            
            // Mock Data for Visualization if empty (Optional, but good for demo)
            // Uncomment the following list to test UI without real data
            /*
            if (notifications.isEmpty) {
               return const Center(child: Text('No notifications', style: TextStyle(color: Colors.white)));
            }
            */
            
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No new notifications',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final grouped = _groupNotificationsByDate(notifications);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
                      child: Text(
                        entry.key.toUpperCase(), // TODAY, YESTERDAY
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...entry.value.map((notification) => _buildNotificationItem(notification, notificationService)),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, NotificationService service) {
    IconData icon;
    Color color;
    Color iconColor;

    // determine icon based on type (or message/filename heuristic since types are limited)
    if (notification.type == 'PRINT_COMPLETED') {
      icon = Icons.check_circle;
      color = Colors.green.withOpacity(0.2);
      iconColor = Colors.green.shade300;
    } else if (notification.type == 'REJECTED') {
      icon = Icons.warning; // Reference uses warning triangle
      color = Colors.orange.withOpacity(0.2);
      iconColor = Colors.orange.shade300;
    } else if (notification.type == 'SECURE_QUEUE') { // Hypothetical type
      icon = Icons.lock;
      color = Colors.blue.withOpacity(0.2);
      iconColor = Colors.blue.shade300;
    } else {
      // Default / System
      icon = Icons.notifications;
      color = Colors.purple.withOpacity(0.2); // Reference uses purple for system
      iconColor = Colors.purple.shade300;
    }

    final timeStr = DateFormat('hh:mm a').format(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) {
         service.clearNotification(notification.id);
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Mark as read or expand
          service.markAsRead(notification.id);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(notification),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(AppNotification n) {
    if (n.type == 'PRINT_COMPLETED') return 'Document Printed Successfully';
    if (n.type == 'REJECTED') return 'Print Job Rejected';
    return 'Notification';
  }
}
