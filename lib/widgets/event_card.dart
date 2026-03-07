// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class EventCard extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final String eventLocation;
  final VoidCallback onTap;
  final String? tag;

  const EventCard({
    super.key,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color:
                tag == 'leadership'
                    ? Colors.amber.withOpacity(0.3)
                    : AppColors.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        color:
            tag == 'leadership'
                ? Colors.amber.withOpacity(0.1)
                : Theme.of(context).colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      tag == 'leadership'
                          ? Colors.amber.withOpacity(0.2)
                          : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  tag == 'leadership' ? Icons.push_pin : Icons.event,
                  color:
                      tag == 'leadership'
                          ? Colors.amber.shade700
                          : AppColors.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventTitle,
                      style: TextStyles.heading2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tag == 'leadership') ...[
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'Leadership Meeting',
                            style: TextStyles.bodyText.copyWith(
                              color: Colors.amber.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          eventDate,
                          style: TextStyles.bodyText.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          eventLocation,
                          style: TextStyles.bodyText.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onBackground,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
