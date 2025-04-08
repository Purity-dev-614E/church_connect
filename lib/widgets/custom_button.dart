import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

/// An enhanced button widget with customizable pulsing animation
///
/// This button supports various animation styles, custom content,
/// and responsive sizing options.
class CustomButton extends StatefulWidget {
  /// The text to display on the button
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Background color of the button
  final Color color;

  /// Shadow elevation of the button
  final double elevation;

  /// Whether the button should have a pulsing animation
  final bool isPulsing;

  /// The type of animation effect (scale, glow, or both)
  final PulseEffectType pulseEffect;

  /// Duration of one pulse cycle in milliseconds
  final int pulseDuration;

  /// Scale factor for the pulse animation (1.0 = no scale, 1.1 = 10% larger)
  final double pulseScale;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Horizontal padding for the button content
  final double horizontalPadding;

  /// Vertical padding for the button content
  final double verticalPadding;

  /// Border radius of the button
  final double borderRadius;

  /// Whether the button should expand to fill its parent width
  final bool isFullWidth;

  /// Optional custom child widget instead of text label
  final Widget? child;

  /// Optional loading state that shows a progress indicator
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryColor,
    this.elevation = 2.0,
    this.isPulsing = false,
    this.pulseEffect = PulseEffectType.scale,
    this.pulseDuration = 800,
    this.pulseScale = 1.05,
    this.icon,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 16.0,
    this.borderRadius = 8.0,
    this.isFullWidth = true,
    this.child,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

/// Types of pulse animation effects
enum PulseEffectType {
  /// Only scales the button up and down
  scale,

  /// Only adds a glowing effect around the button
  glow,

  /// Combines both scale and glow effects
  both
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-initialize animations if relevant properties changed
    if (oldWidget.isPulsing != widget.isPulsing ||
        oldWidget.pulseDuration != widget.pulseDuration ||
        oldWidget.pulseScale != widget.pulseScale ||
        oldWidget.pulseEffect != widget.pulseEffect) {
      _disposeAnimations();
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    if (widget.isPulsing) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.pulseDuration),
      )..repeat(reverse: true);

      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.pulseScale,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );

      _glowAnimation = Tween<double>(
        begin: 0.0,
        end: 2.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  void _disposeAnimations() {
    if (widget.isPulsing) {
      _animationController.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPulsing) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return _buildAnimatedButton();
        },
      );
    } else {
      return _buildButton();
    }
  }

  Widget _buildAnimatedButton() {
    Widget button = _buildButton();

    // Apply animations based on the selected effect type
    switch (widget.pulseEffect) {
      case PulseEffectType.scale:
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        );

      case PulseEffectType.glow:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 4),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _glowAnimation.value),
                blurRadius: 10.0 * _glowAnimation.value,
                spreadRadius: 2.0 * _glowAnimation.value,
              ),
            ],
          ),
          child: button,
        );

      case PulseEffectType.both:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 4),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _glowAnimation.value),
                blurRadius: 10.0 * _glowAnimation.value,
                spreadRadius: 2.0 * _glowAnimation.value,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          ),
        );
    }
  }

  Widget _buildButton() {
    final buttonContent = widget.child ?? _buildDefaultContent();

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color,
          elevation: widget.elevation,
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          disabledBackgroundColor: widget.color.withOpacity(0.6),
        ),
        child: widget.isLoading
            ? _buildLoadingIndicator()
            : buttonContent,
      ),
    );
  }

  Widget _buildDefaultContent() {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: Colors.white),
          SizedBox(width: 8.0),
          Text(
            widget.label,
            style: TextStyles.buttonText,
          ),
        ],
      );
    } else {
      return Text(
        widget.label,
        style: TextStyles.buttonText,
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}