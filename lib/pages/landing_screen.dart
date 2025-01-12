import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color.fromARGB(255, 0, 56, 147);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6ACEF5),
                const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: screenHeight * 0.05,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.security,
                    size: screenHeight * 0.1,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Text(
                  'Suraksha',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: screenHeight * 0.06,
                        letterSpacing: 1.2,
                      ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'Your Safety, Our Concern',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        fontSize: screenHeight * 0.024,
                        letterSpacing: 0.5,
                      ),
                ),
                const Spacer(flex: 3),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_android, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Login with OTP',
                            style: TextStyle(
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'Secure • Reliable',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: screenHeight * 0.016,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
