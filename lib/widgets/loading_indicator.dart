import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/constants/colors.dart';

/// An animated loading indicator with multiple animation styles
///
/// This widget provides various loading animations that can be used
/// throughout the app for a consistent and engaging loading experience.
class AnimatedLoadingIndicator extends StatefulWidget {
  /// The type of animation to display
  final LoadingAnimationType type;

  /// Primary color of the animation
  final Color primaryColor;

  /// Secondary color for animations that use multiple colors
  final Color secondaryColor;

  /// Size of the loading indicator
  final double size;

  /// Animation speed factor (1.0 = normal speed)
  final double speedFactor;

  /// Optional text to display below the loading indicator
  final String? loadingText;

  /// Whether to show a fading effect
  final bool withFading;

  const AnimatedLoadingIndicator({
    Key? key,
    this.type = LoadingAnimationType.circularPulse,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlueAccent,
    this.size = 50.0,
    this.speedFactor = 1.0,
    this.loadingText,
    this.withFading = true,
  }) : super(key: key);

  @override
  State<AnimatedLoadingIndicator> createState() => _AnimatedLoadingIndicatorState();
}

/// Types of loading animations available
enum LoadingAnimationType {
  /// Standard circular progress indicator with pulsing effect
  circularPulse,

  /// Bouncing dots in a row
  bouncingDots,

  /// Rotating dots in a circle
  rotatingDots,

  /// Fading circles that appear and disappear
  fadingCircles,

  /// Wave pattern of bars
  waveBar,

  /// Staggered rotating squares
  rotatingSquares,
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late List<AnimationController> _dotsControllers;

  @override
  void initState() {
    super.initState();

    // Main rotation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1500 / widget.speedFactor).round()),
    )..repeat();

    // Pulse effect controller
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1200 / widget.speedFactor).round()),
    )..repeat(reverse: true);

    // Fade effect controller
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (800 / widget.speedFactor).round()),
    )..repeat(reverse: true);

    // Controllers for bouncing dots
    _dotsControllers = List.generate(
      5,
          (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (600 / widget.speedFactor).round()),
      )..repeat(reverse: true),
    );

    // Stagger the dots animations
    for (int i = 0; i < _dotsControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _dotsControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    for (var controller in _dotsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingAnimation(),
          if (widget.loadingText != null) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: widget.withFading
                      ? 0.6 + (_fadeController.value * 0.4)
                      : 1.0,
                  child: child,
                );
              },
              child: Text(
                widget.loadingText!,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    switch (widget.type) {
      case LoadingAnimationType.circularPulse:
        return _buildCircularPulseIndicator();
      case LoadingAnimationType.bouncingDots:
        return _buildBouncingDotsIndicator();
      case LoadingAnimationType.rotatingDots:
        return _buildRotatingDotsIndicator();
      case LoadingAnimationType.fadingCircles:
        return _buildFadingCirclesIndicator();
      case LoadingAnimationType.waveBar:
        return _buildWaveBarIndicator();
      case LoadingAnimationType.rotatingSquares:
        return _buildRotatingSquaresIndicator();
    }
  }

  Widget _buildCircularPulseIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _pulseController]),
      builder: (context, child) {
        return SizedBox(
          height: widget.size,
          width: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing circle
              if (widget.withFading)
                Transform.scale(
                  scale: 0.8 + (_pulseController.value * 0.3),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),

              // Rotating gradient arc
              SizedBox(
                height: widget.size * 0.9,
                width: widget.size * 0.9,
                child: CircularProgressIndicator(
                  strokeWidth: widget.size * 0.1,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.primaryColor,
                  ),
                ),
              ),

              // Inner pulsing circle
              Transform.scale(
                scale: 0.6 + (_pulseController.value * 0.2),
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.secondaryColor.withOpacity(
                      widget.withFading ? 0.7 : 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBouncingDotsIndicator() {
    return SizedBox(
      height: widget.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _dotsControllers[index],
            builder: (context, child) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: Transform.translate(
                  offset: Offset(0, -10 * _dotsControllers[index].value),
                  child: Container(
                    width: widget.size * 0.15,
                    height: widget.size * 0.15,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        widget.primaryColor,
                        widget.secondaryColor,
                        index / 4,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildRotatingDotsIndicator() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.size,
          width: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(8, (index) {
              final position = index / 8;
              final rotationAngle = _controller.value;
              final offset = widget.size * 0.35;

              return Transform(
                transform: Matrix4.identity()
                  ..translate(
                    offset * math.cos(2 * math.pi * (position + rotationAngle)),
                    offset * math.sin(2 * math.pi * (position + rotationAngle)),
                  ),
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.15,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      widget.primaryColor,
                      widget.secondaryColor,
                      (index % 2 == 0) ? 0.0 : 0.5,
                    )!.withOpacity(0.7 + (0.3 * (1 - position))),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildFadingCirclesIndicator() {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              final delay = index / 4;
              final value = (_fadeController.value + delay) % 1.0;

              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.5 + (value * 0.5),
                  child: Container(
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        widget.primaryColor,
                        widget.secondaryColor,
                        index / 3,
                      )!.withOpacity(0.7 - (value * 0.5)),
                      border: Border.all(
                        color: widget.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildWaveBarIndicator() {
    return SizedBox(
      height: widget.size * 0.8,
      width: widget.size * 1.2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _dotsControllers[index],
            builder: (context, child) {
              return Container(
                width: widget.size * 0.12,
                height: widget.size * 0.5 * (0.3 + _dotsControllers[index].value * 0.7),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    widget.primaryColor,
                    widget.secondaryColor,
                    index / 4,
                  ),
                  borderRadius: BorderRadius.circular(widget.size * 0.06),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildRotatingSquaresIndicator() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.size,
          width: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(4, (index) {
              final rotationAngle = _controller.value * 2 * math.pi;
              final size = widget.size * (0.6 - (index * 0.1));

              return Transform.rotate(
                angle: rotationAngle + (index * math.pi / 4),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(size * 0.1),
                    border: Border.all(
                      color: Color.lerp(
                        widget.primaryColor,
                        widget.secondaryColor,
                        index / 3,
                      )!,
                      width: 3,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}