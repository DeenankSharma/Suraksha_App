part of 'home_bloc.dart';

@immutable
abstract class HomeEvent {}

class ShowContactsEvent extends HomeEvent {}

class SendOtpEvent extends HomeEvent {
  final String phoneNumber;

  SendOtpEvent({required this.phoneNumber});
}

class VerifyOtpEvent extends HomeEvent {
  final String verificationId;
  final String otp;

  VerifyOtpEvent({
    required this.verificationId,
    required this.otp,
  });
}

class HomeScreenEvent extends HomeEvent {}
