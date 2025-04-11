import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

enum NotificationType {
  success,
  error,
  info,
  warning
}

class CustomNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onDismissed;
  final bool showIcon;
  final bool showProgress;

  const CustomNotification({
    Key? key,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
    this.showIcon = true,
    this.showProgress = true,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismissed,
    bool showIcon = true,
    bool showProgress = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry; // Declare as late

    overlayEntry = OverlayEntry(
      builder: (context) => CustomNotification(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          overlayEntry.remove(); // Now overlayEntry is properly initialized
          onDismissed?.call();
        },
        showIcon: showIcon,
        showProgress: showProgress,
      ),
    );

    overlay.insert(overlayEntry);
  }


  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.forward();

    if (widget.duration != Duration.zero) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onDismissed?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.successColor.withOpacity(0.1);
      case NotificationType.error:
        return AppColors.errorColor.withOpacity(0.1);
      case NotificationType.warning:
        return AppColors.accentColor.withOpacity(0.1);
      case NotificationType.info:
        return AppColors.primaryColor.withOpacity(0.1);
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.successColor;
      case NotificationType.error:
        return AppColors.errorColor;
      case NotificationType.warning:
        return AppColors.accentColor;
      case NotificationType.info:
        return AppColors.primaryColor;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value * 100, 0),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            _controller.reverse().then((_) {
              widget.onDismissed?.call();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getIconColor().withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.showIcon) ...[
                      Icon(
                        _getIcon(),
                        color: _getIconColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textColor.withOpacity(0.5),
                      onPressed: () {
                        _controller.reverse().then((_) {
                          widget.onDismissed?.call();
                        });
                      },
                    ),
                  ],
                ),
                if (widget.showProgress && widget.duration != Duration.zero)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: _getIconColor().withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 