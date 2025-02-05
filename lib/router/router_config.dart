import 'package:flutter_setup/pages/contacts.dart';
import 'package:flutter_setup/pages/contacts_log.dart';
import 'package:flutter_setup/pages/home_screen.dart';
import 'package:flutter_setup/pages/landing_screen.dart';
import 'package:flutter_setup/pages/login_with_otp_screen.dart';
import 'package:flutter_setup/pages/otp_screen.dart';
import 'package:flutter_setup/pages/profile_page.dart';
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
          builder: (context, state) => LandingScreen(),
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
          builder: (context, state) => HomeScreen(),
        ),

        GoRoute(
          path: '/contacts',
          name: 'contacts',
          builder: (context, state) => ContactsLog(),
        ),
        GoRoute(
          path: '/manage_contacts',
          name: 'manage_contacts',
          builder: (context, state) => Contacts(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => ProfilePage(),
        ),
        // GoRoute(path: .)ute
      ],
    );
  }

  // Rename the old initializeRouter to _getInitialLocation
  static Future<String> _getInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('pn') ?? '';
    if (phoneNumber.isNotEmpty) {
      return '/home';
    }
    return '/';
  }
}
