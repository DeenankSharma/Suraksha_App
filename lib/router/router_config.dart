import 'package:flutter_setup/pages/contacts.dart';
import 'package:flutter_setup/pages/contacts_log.dart';
import 'package:flutter_setup/pages/home_screen.dart';
import 'package:flutter_setup/pages/login_with_otp_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Static instance of GoRouter that can be accessed throughout the app
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginWithOtpScreen(),
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
    ],
  );
}
