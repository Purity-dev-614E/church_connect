import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/theme/app_theme.dart';
import 'package:group_management_church_app/core/utils/auth_error_handler.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';
import 'package:group_management_church_app/features/auth/signup.dart';
import 'package:group_management_church_app/features/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
    // Listen for auth errors when new routes are pushed
    _setupAuthErrorListener(route);
  }
  
  void _setupAuthErrorListener(Route<dynamic> route) {
    if (route.settings.name != '/login' && 
        route.settings.name != '/signup' && 
        route.settings.name != '/reset-password') {
      // Add listener for auth errors on non-auth routes
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
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