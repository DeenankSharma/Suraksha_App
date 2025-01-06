import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_setup/pages/home_screen.dart';
import 'package:flutter_setup/pages/landing_screen.dart';
import 'package:flutter_setup/pages/login_with_otp_screen.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Static instance of GoRouter that can be accessed throughout the app
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginWithOtpScreen(),
      ),
    ],
  );

  static const String landing = '/';
  static const String home = '/home';
  static const String login = '/login';
}