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

class OtpSentState extends HomeState {}

class OtpVerifiedState extends HomeState {}

class OtpErrorState extends HomeState {
  final String error;

  OtpErrorState(this.error);
}

class OtpTimeoutState extends HomeState {
  final String message;
  final String verificationId;

  OtpTimeoutState({required this.message, required this.verificationId});
}

//Home Screen States
class HomeScreenState extends HomeState {}

// Help States
class HelpRequestedState extends HomeScreenState {
  final String type;

  HelpRequestedState(this.type);
}

// Logs States
class LogsFetchedState extends HomeScreenState {
  final Map<String, dynamic> logs;

  LogsFetchedState(this.logs);
}

class LogsErrorState extends HomeState {
  final String error;

  LogsErrorState(this.error);
}

class LogsLoadingState extends HomeState {}

class ProfileUpdatedState extends HomeState {
  final bool isEditing;
  final String email;
  final String address;

  ProfileUpdatedState(this.isEditing, this.email, this.address);
}

class ProfileErrorState extends HomeState {
  final String error;

  ProfileErrorState(this.error);
}
