import 'package:flutter/material.dart';

/// A utility class for managing page routing animations in the application.
/// This class provides various transition animations for navigating between screens.
class PageRouter {
  /// Navigate to a new screen with a fade transition
  static Route<dynamic> fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        var tween = Tween(begin: begin, end: end);
        var fadeAnimation = animation.drive(tween);
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to a new screen with a slide transition from right to left
  static Route<dynamic> slideRightTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end);
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to a new screen with a slide transition from left to right
  static Route<dynamic> slideLeftTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end);
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to a new screen with a slide transition from bottom to top
  static Route<dynamic> slideUpTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end);
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to a new screen with a scale transition
  static Route<dynamic> scaleTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        var tween = Tween(begin: begin, end: end);
        var scaleAnimation = animation.drive(tween);
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to a new screen with a combined fade and scale transition
  static Route<dynamic> fadeScaleTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        
        var fadeTween = Tween(begin: 0.0, end: 1.0);
        var fadeAnimation = animation.drive(fadeTween.chain(curveTween));
        
        var scaleTween = Tween(begin: 0.8, end: 1.0);
        var scaleAnimation = animation.drive(scaleTween.chain(curveTween));
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to a new screen with a rotation and scale transition
  static Route<dynamic> rotationTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        
        var rotateTween = Tween(begin: 0.0, end: 0.0); // No rotation by default
        var rotateAnimation = animation.drive(rotateTween.chain(curveTween));
        
        var scaleTween = Tween(begin: 0.0, end: 1.0);
        var scaleAnimation = animation.drive(scaleTween.chain(curveTween));
        
        return RotationTransition(
          turns: rotateAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  /// A helper method to navigate to a new screen with the specified transition
  static void navigateTo(BuildContext context, Widget page, {TransitionType type = TransitionType.slide}) {
    Route<dynamic> route;
    
    switch (type) {
      case TransitionType.fade:
        route = fadeTransition(page);
        break;
      case TransitionType.slideRight:
        route = slideRightTransition(page);
        break;
      case TransitionType.slideLeft:
        route = slideLeftTransition(page);
        break;
      case TransitionType.slideUp:
        route = slideUpTransition(page);
        break;
      case TransitionType.scale:
        route = scaleTransition(page);
        break;
      case TransitionType.fadeScale:
        route = fadeScaleTransition(page);
        break;
      case TransitionType.rotation:
        route = rotationTransition(page);
        break;
      case TransitionType.slide:
      default:
        route = slideRightTransition(page);
        break;
    }
    
    Navigator.of(context).push(route);
  }

  /// A helper method to replace the current screen with a new one using the specified transition
  static void navigateReplacementTo(BuildContext context, Widget page, {TransitionType type = TransitionType.slide}) {
    Route<dynamic> route;
    
    switch (type) {
      case TransitionType.fade:
        route = fadeTransition(page);
        break;
      case TransitionType.slideRight:
        route = slideRightTransition(page);
        break;
      case TransitionType.slideLeft:
        route = slideLeftTransition(page);
        break;
      case TransitionType.slideUp:
        route = slideUpTransition(page);
        break;
      case TransitionType.scale:
        route = scaleTransition(page);
        break;
      case TransitionType.fadeScale:
        route = fadeScaleTransition(page);
        break;
      case TransitionType.rotation:
        route = rotationTransition(page);
        break;
      case TransitionType.slide:
      default:
        route = slideRightTransition(page);
        break;
    }
    
    Navigator.of(context).pushReplacement(route);
  }
}

/// Enum defining the available transition types
enum TransitionType {
  fade,
  slide,
  slideRight,
  slideLeft,
  slideUp,
  scale,
  fadeScale,
  rotation,
}