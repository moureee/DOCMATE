import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (appData.notifications.isEmpty) {
            return const Center(
              child: Text(
                'You do not have any notifications.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: appData.notifications.length,
            itemBuilder: (context, index) {
              final notification = appData.notifications[index];

              return buildNotificationCard(
                appData,
                notification,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildNotificationCard(
    AppData appData,
    NotificationModel notification,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        appData.markNotificationRead(
          notification,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.read ? Colors.white : AppColors.lightMint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.read ? Colors.grey.shade300 : AppColors.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
                  notification.read ? Colors.grey.shade200 : AppColors.primary,
              child: Icon(
                notificationIcon(notification.title),
                color: notification.read ? Colors.black54 : Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDate(notification.date),
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData notificationIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('appointment') || lowerTitle.contains('booking')) {
      return Icons.calendar_month;
    }

    if (lowerTitle.contains('medicine')) {
      return Icons.medication;
    }

    if (lowerTitle.contains('emergency')) {
      return Icons.emergency;
    }

    if (lowerTitle.contains('announcement')) {
      return Icons.campaign;
    }

    return Icons.notifications;
  }
}
