import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Timeline'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final timelineItems = List<TimelineItem>.from(
            appData.timeline,
          );

          timelineItems.sort(
            (firstItem, secondItem) {
              return secondItem.date.compareTo(
                firstItem.date,
              );
            },
          );

          if (timelineItems.isEmpty) {
            return const Center(
              child: Text(
                'No health timeline information found.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: timelineItems.length,
            itemBuilder: (context, index) {
              final item = timelineItems[index];
              final isLast = index == timelineItems.length - 1;

              return buildTimelineItem(
                item,
                isLast,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildTimelineItem(
    TimelineItem item,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 105,
                color: AppColors.primary,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.details,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 15,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(item.date),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
