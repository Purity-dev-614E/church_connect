import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

enum NotificationType { success, error, info, warning }

class NotificationManager {
  static final List<OverlayEntry> _activeNotifications = [];
  static const int maxNotifications = 3;

  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
    bool showIcon = true,
    bool showProgress = true,
    String? title,
    bool allowSwipe = true,
  }) {
    // Remove oldest notification if we exceed max
    if (_activeNotifications.length >= maxNotifications) {
      final oldest = _activeNotifications.removeAt(0);
      oldest.remove();
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => ImprovedNotification(
            message: message,
            type: type,
            duration: duration,
            onDismissed: () {
              _activeNotifications.remove(overlayEntry);
              overlayEntry.remove();
              onDismissed?.call();
              _repositionNotifications();
            },
            showIcon: showIcon,
            showProgress: showProgress,
            title: title,
            allowSwipe: allowSwipe,
            index: _activeNotifications.length,
          ),
    );

    _activeNotifications.add(overlayEntry);
    overlay.insert(overlayEntry);
  }

  static void _repositionNotifications() {
    for (int i = 0; i < _activeNotifications.length; i++) {
      if (_activeNotifications[i].mounted) {
        _activeNotifications[i].markNeedsBuild();
      }
    }
  }

  static void dismissAll() {
    for (final entry in List.from(_activeNotifications)) {
      entry.remove();
    }
    _activeNotifications.clear();
  }
}

class ImprovedNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onDismissed;
  final bool showIcon;
  final bool showProgress;
  final String? title;
  final bool allowSwipe;
  final int index;

  const ImprovedNotification({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.onDismissed,
    this.showIcon = true,
    this.showProgress = true,
    this.title,
    this.allowSwipe = true,
    this.index = 0,
  });

  @override
  State<ImprovedNotification> createState() => _ImprovedNotificationState();
}

class _ImprovedNotificationState extends State<ImprovedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDismissing = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();

    if (widget.duration != Duration.zero) {
      Future.delayed(widget.duration, () {
        if (mounted && !_isDismissing) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.type) {
      case NotificationType.success:
        return isDark
            ? const Color(0xFF064E3B)
            : const Color(0xFFD1FAE5); // Dark/light green
      case NotificationType.error:
        return isDark
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEE2E2); // Dark/light red
      case NotificationType.warning:
        return isDark
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF3C7); // Dark/light amber
      case NotificationType.info:
        return isDark
            ? const Color(0xFF1E3A8A)
            : const Color(0xFFDBEAFE); // Dark/light blue
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF10B981); // Modern green
      case NotificationType.error:
        return const Color(0xFFEF4444); // Modern red
      case NotificationType.warning:
        return const Color(0xFFF59E0B); // Modern amber
      case NotificationType.info:
        return const Color(0xFF3B82F6); // Modern blue
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF047857); // Dark green
      case NotificationType.error:
        return const Color(0xFFB91C1C); // Dark red
      case NotificationType.warning:
        return const Color(0xFFD97706); // Dark amber
      case NotificationType.info:
        return const Color(0xFF1D4ED8); // Dark blue
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (widget.type) {
      case NotificationType.success:
        return isDark ? const Color(0xFF6EE7B7) : const Color(0xFF064E3B);
      case NotificationType.error:
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D);
      case NotificationType.warning:
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFF78350F);
      case NotificationType.info:
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A);
    }
  }

  Color _getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.8);
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  String _getEmoji() {
    switch (widget.type) {
      case NotificationType.success:
        return '✅';
      case NotificationType.error:
        return '❌';
      case NotificationType.warning:
        return '⚠️';
      case NotificationType.info:
        return 'ℹ️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topOffset =
        MediaQuery.of(context).padding.top + 16.0 + (widget.index * 80.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: topOffset,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value * 120 + _dragOffset, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value * (1 - (_dragOffset.abs() / 300)),
                child: child,
              ),
            ),
          );
        },
        child: GestureDetector(
          onPanUpdate:
              widget.allowSwipe
                  ? (details) {
                    setState(() {
                      _dragOffset += details.delta.dx;
                    });
                  }
                  : null,
          onPanEnd:
              widget.allowSwipe
                  ? (details) {
                    if (_dragOffset.abs() > 100) {
                      _dismiss();
                    } else {
                      setState(() {
                        _dragOffset = 0.0;
                      });
                    }
                  }
                  : null,
          onTap: () {
            _dismiss();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getSurfaceColor(context),
                  _getSurfaceColor(context).withOpacity(0.8),
                ],
              ),
              border: Border.all(
                color: _getBackgroundColor().withOpacity(isDark ? 0.5 : 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getBackgroundColor().withOpacity(isDark ? 0.3 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getBackgroundColor().withOpacity(isDark ? 0.3 : 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (widget.showIcon) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getBackgroundColor().withOpacity(
                                isDark ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getEmoji(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _getIcon(),
                                  color: _getIconColor(),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null) ...[
                                Text(
                                  widget.title!,
                                  style: TextStyles.bodyText.copyWith(
                                    color: _getTextColor(context),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.message,
                                style: TextStyles.bodyText.copyWith(
                                  color: _getSecondaryTextColor(context),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                maxLines: widget.title != null ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _dismiss(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: _getSecondaryTextColor(
                                context,
                              ).withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showProgress && widget.duration != Duration.zero)
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _getBackgroundColor().withOpacity(
                          isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getBackgroundColor(),
                                    _getBackgroundColor().withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Backward compatibility
class CustomNotification {
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
    bool showIcon = true,
    bool showProgress = true,
    String? title,
  }) {
    NotificationManager.show(
      context: context,
      message: message,
      type: type,
      duration: duration,
      onDismissed: onDismissed,
      showIcon: showIcon,
      showProgress: showProgress,
      title: title,
    );
  }
}
