import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is NavigateToLoginState) {
          // context.read<HomeBloc>().add(HomeScreenEvent());
          context.go('/login');
        } else if (state is NavigateToOtpState) {
          context
              .read<HomeBloc>()
              .add(SendOtpEvent(phoneNumber: state.phoneNumber));
          context.go('/otp');
        } else if (state is NavigateToHomeState) {
          context.read<HomeBloc>().add(HomeScreenEvent());
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.shield_lefthalf_fill,
                      size: screenHeight * 0.08,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Text(
                    'Suraksha',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: screenHeight * 0.05,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Your Safety, Our Priority',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w400,
                      fontSize: screenHeight * 0.022,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeaturePill(
                        CupertinoIcons.lock_shield_fill,
                        'Secure',
                      ),
                      const SizedBox(width: 12),
                      _buildFeaturePill(
                        CupertinoIcons.checkmark_shield_fill,
                        'Reliable',
                      ),
                      const SizedBox(width: 12),
                      _buildFeaturePill(
                        CupertinoIcons.timer,
                        'Fast',
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Trigger the check in HomeBloc
                        context.read<HomeBloc>().add(GetStartedEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_right_circle_fill,
                            size: 24,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: AppTheme.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Emergency safety app for women',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
