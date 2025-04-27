// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class EventCard extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final String eventLocation;
  final VoidCallback onTap;

  const EventCard({super.key, 
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.1), width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.event,
                  color: AppColors.primaryColor,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          eventDate,
                          style: TextStyles.bodyText.copyWith(
                            color: AppColors.secondaryColor,
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
                          color: AppColors.textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          eventLocation,
                          style: TextStyles.bodyText.copyWith(
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
