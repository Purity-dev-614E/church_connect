import 'dart:async'; // <-- added
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:group_management_church_app/core/theme/app_theme.dart';
import 'package:group_management_church_app/core/utils/auth_error_handler.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/regional_manager_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';
import 'package:group_management_church_app/features/auth/signup.dart';
import 'package:group_management_church_app/features/splash_screen.dart';

import 'package:group_management_church_app/core/utils/log_service.dart';

import 'features/dev_tools/log_screen.dart'; // <-- your logger

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

/// Custom navigator observer to handle authentication errors
class _AuthErrorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setupAuthErrorListener(route);
  }
  
  void _setupAuthErrorListener(Route<dynamic> route) {
    if (route.settings.name != '/login' && 
        route.settings.name != '/signup' && 
        route.settings.name != '/reset-password') {
      Future.delayed(Duration.zero, () {
        if (navigator?.context != null) {
          final authProvider = Provider.of<AuthProvider>(navigator!.context, listen: false);
          if (authProvider.status == AuthStatus.unauthenticated && 
              authProvider.errorMessage.contains('Authentication failed')) {
            AuthErrorHandler.handleAuthError(navigator!.context);
          }
        }
      });
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => RegionalManagerAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminAnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Church Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
        // Add global error handling for HTTP errors
        navigatorObservers: [
          _AuthErrorObserver(),
        ],
      ),
    );
  }
}