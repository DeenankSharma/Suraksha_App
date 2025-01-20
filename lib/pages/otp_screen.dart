// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_setup/bloc/home_bloc.dart';
// import 'package:go_router/go_router.dart';
//
// class OtpVerificationScreen extends StatelessWidget {
//   OtpVerificationScreen({super.key});
//
//   final TextEditingController _otpController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   Widget build(BuildContext context) {
//     HomeBloc homeBloc = HomeBloc();
//     const primaryBlue = Color.fromARGB(255, 0, 56, 147);
//     final screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       backgroundColor: primaryBlue,
//       body: SafeArea(
//           child: BlocConsumer(
//         bloc: homeBloc,
//         listener: (context, state) {
//           if (state is OtpVerifiedState) {
//             context.go('/home');
//           } else if (state is OtpErrorState) {
//             context.go('/login');
//           }
//         },
//         builder: (context, state) {
//           if (state is OtpSentState) {
//             return Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     const Color.fromARGB(255, 106, 206, 245),
//                     const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
//                   ],
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: screenHeight * 0.05),
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       SizedBox(height: screenHeight * 0.05),
//                       Text(
//                         'Enter\nVerification Code',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineMedium
//                             ?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               height: 1.2,
//                             ),
//                       ),
//                       SizedBox(height: screenHeight * 0.02),
//                       Text(
//                         'Enter the 6-digit code we sent to your phone',
//                         style:
//                             Theme.of(context).textTheme.titleMedium?.copyWith(
//                                   color: Colors.white.withOpacity(0.9),
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                       ),
//                       SizedBox(height: screenHeight * 0.06),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: TextFormField(
//                           controller: _otpController,
//                           keyboardType: TextInputType.number,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 8,
//                           ),
//                           inputFormatters: [
//                             LengthLimitingTextInputFormatter(6),
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           decoration: InputDecoration(
//                             hintText: '------',
//                             hintStyle: TextStyle(
//                               color: Colors.grey[400],
//                               fontSize: 24,
//                               letterSpacing: 8,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide.none,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: const EdgeInsets.all(20),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter the verification code';
//                             }
//                             if (value.length != 6) {
//                               return 'Please enter a valid 6-digit code';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.04),
//                       TextButton(
//                         onPressed: () {
//                           context.go('/');
//                         },
//                         child: Text(
//                           'Resend Code',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: screenHeight * 0.07,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               if (_formKey.currentState!.validate()) {
//                                 // Scaffold.of(context).
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       'Verifying ...',
//                                       style: TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.w500),
//                                     ),
//                                     backgroundColor: Color(0xFF6ACEF5),
//                                   ),
//                                 );
//                                 context.read<HomeBloc>().add(VerifyOtpEvent(
//                                     verificationId: state.verificationId,
//                                     otp: _otpController.text.toString()));
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               foregroundColor: primaryBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: const Text(
//                               'Verify',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: screenHeight * 0.04),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           } else {
//             return Container();
//           }
//         },
//       )),
//     );
//   }
// }
