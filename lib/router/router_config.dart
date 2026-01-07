import 'package:flutter_setup/data/models/auth_data_model.dart';
import 'package:flutter_setup/pages/contacts.dart';
import 'package:flutter_setup/pages/contacts_log.dart';
import 'package:flutter_setup/pages/home_screen.dart';
import 'package:flutter_setup/pages/landing_screen.dart';
import 'package:flutter_setup/pages/login_with_otp_screen.dart';
import 'package:flutter_setup/pages/otp_screen.dart';
import 'package:flutter_setup/pages/profile_page.dart';
import 'package:flutter_setup/pages/setup_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  AppRouter._();

  static Future<GoRouter> initializeRouter() async {
    final initialLocation = await _getInitialLocation();
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          name: 'landing',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => LoginWithOtpScreen(),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => OtpVerificationScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/contacts',
          name: 'contacts',
          builder: (context, state) => const ContactsLog(),
        ),
        GoRoute(
          path: '/manage_contacts',
          name: 'manage_contacts',
          builder: (context, state) => const Contacts(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/setup',
          name: 'setup',
          builder: (context, state) => const SetupScreen(),
        ),
      ],
    );
  }

  static Future<String> _getInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? authJson = prefs.getString('auth_data');

    // Scenario 1: No data found -> Landing Page
    if (authJson == null) {
      return '/';
    }

    try {
      final authData = AuthData.fromJson(authJson);

      // Scenario 3: Verified -> Home
      if (authData.isVerified) {
        // Note: If you still need the Setup logic (e.g., checking if emergency contacts exist),
        // you can check a separate flag here. For now, we route directly to Home.
        return '/home';
      }
      // Scenario 2: Data exists but not verified -> OTP Screen
      else {
        return '/otp';
      }
    } catch (e) {
      // If parsing fails (corrupt data), clear it and go to Landing
      await prefs.remove('auth_data');
      return '/';
    }
  }
}
