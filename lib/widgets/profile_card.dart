import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import 'custom_button.dart';

class ProfileCard extends StatelessWidget {
  final String avatarUrl; // URL or asset path for the avatar image
  final String fullName;
  final String contact;
  final String nextOfKin;
  final String nextOfKinNumber;
  final VoidCallback? onUpdateTap;  // Callback for the update button

  ProfileCard({
    required this.avatarUrl,
    required this.fullName,
    required this.contact,
    required this.nextOfKin,
    required this.nextOfKinNumber,
    this.onUpdateTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpdateTap, // This allows tapping on the card (e.g., for updates)
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar image
              CircleAvatar(
                radius: 40.0,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: AppColors.primaryColor, // Fallback color if the image is not found
              ),
              SizedBox(width: 16.0),
              // Profile details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyles.heading2, // Full Name
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Contact: $contact',
                      style: TextStyles.bodyText,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Next of Kin: $nextOfKin',
                      style: TextStyles.bodyText,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Next of Kin Number: $nextOfKinNumber',
                      style: TextStyles.bodyText,
                    ),
                    SizedBox(height: 8.0),
                    // Update Button
                   CustomButton(
                     label: 'Update Profile',
                     onPressed: onUpdateTap ?? () {},
                     color: AppColors.primaryColor,
                     isFullWidth: false,
                     horizontalPadding: 20,
                     verticalPadding: 8,
                     isPulsing: true
                   )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
