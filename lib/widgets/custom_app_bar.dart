// lib/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import '../core/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showProfileAvatar;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;

  CustomAppBar({
    required this.title,
    this.showBackButton = false,
    this.showProfileAvatar = false,
    this.onProfileTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyles.heading2,
      ),
      backgroundColor: AppColors.primaryColor,
      centerTitle: true,
      actions: actions ?? [
        if (showProfileAvatar)
          GestureDetector(
            onTap: onProfileTap ?? () {
              // Default action if no callback provided
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile avatar tapped')),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: AppColors.accentColor,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
