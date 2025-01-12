part of 'home_bloc.dart';

@immutable
abstract class HomeState {}

class HomeInitial extends HomeState {}

// Contact States
class ContactsLoadingState extends HomeState {}

class ContactsFetchedState extends HomeState {
  final List<Map<String, dynamic>> contacts;

  ContactsFetchedState(this.contacts);
}

class ContactsErrorState extends HomeState {
  final String error;

  ContactsErrorState(this.error);
}

// OTP States
class OtpLoadingState extends HomeState {}

class OtpSentState extends HomeState {
  final String verificationId;
  final int? resendToken;

  OtpSentState({
    required this.verificationId,
    this.resendToken,
  });
}

class OtpVerifiedState extends HomeState {}

class OtpErrorState extends HomeState {
  final String error;

  OtpErrorState(this.error);
}

class HomeScreenState extends HomeState {}
