import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  void _markAsRead(dynamic notification) async {
    if (notification['is_read'] == false) {
      await ApiService().markNotificationAsRead(notification['id'].toString());
      // Re-fetch to update state globally
      NotificationService().fetchNotifications();
    }
  }

  void _markAllAsRead() async {
    await ApiService().markAllNotificationsAsRead();
    NotificationService().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: NotificationService().systemNotifications,
      builder: (context, notifications, child) {
        return ValueListenableBuilder<int>(
          valueListenable: NotificationService().unreadRequestsCount,
          builder: (context, count, child) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: PopupMenuButton<dynamic>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onSelected: _markAsRead,
                itemBuilder: (context) {
                  List<PopupMenuEntry<dynamic>> items = [];
                  
                  // Header
                  items.add(
                    PopupMenuItem(
                      enabled: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          if (count > 0)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _markAllAsRead();
                              },
                              child: const Text('Tout marquer lu', style: TextStyle(fontSize: 12)),
                            )
                        ],
                      ),
                    )
                  );
                  
                  items.add(const PopupMenuDivider());

                  if (notifications.isEmpty) {
                    items.add(
                      const PopupMenuItem(
                        enabled: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Aucune notification', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      )
                    );
                  } else {
                    for (var notif in notifications.take(10)) {
                      final bool isRead = notif['is_read'] == true;
                      items.add(
                        PopupMenuItem(
                          value: notif,
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _getIconForType(notif['type']),
                                  color: isRead ? Colors.grey : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'] ?? '',
                                        style: TextStyle(
                                          color: isRead ? Colors.grey.shade600 : Colors.black87,
                                          fontSize: 12,
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
                        )
                      );
                    }
                  }

                  return items;
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications;
    if (type.contains('chat') || type.contains('message')) return Icons.chat;
    if (type.contains('appointment')) return Icons.calendar_month;
    if (type.contains('med')) return Icons.medication;
    if (type.contains('lab')) return Icons.science;
    return Icons.notifications;
  }
}


