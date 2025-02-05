part of 'home_bloc.dart';

@immutable
abstract class HomeEvent {}

class ShowContactsEvent extends HomeEvent {}

class AddContactEvent extends HomeEvent {
  final Map<String, dynamic> contact;
  AddContactEvent(this.contact);
}

class RemoveContactEvent extends HomeEvent {
  final Map<String, dynamic> contact;
  RemoveContactEvent(this.contact);
}

class SendOtpEvent extends HomeEvent {
  final String phoneNumber;

  SendOtpEvent({required this.phoneNumber});
}

class VerifyOtpEvent extends HomeEvent {
  final String otp;

  VerifyOtpEvent({required this.otp});
}

class HomeScreenEvent extends HomeEvent {}

class HelpButtonClickedEvent extends HomeEvent {}

class HelpFormSubmittedEvent extends HomeEvent {
  final String area;
  final String landmark;
  final String description;

  HelpFormSubmittedEvent(
      {required this.area, required this.landmark, required this.description});
}

class GetContactLogsEvent extends HomeEvent {}

class OpenSettingsEvent extends HomeEvent {}

class UpdateProfileEvent extends HomeEvent {
  final String? email;
  final String? address;
  final bool isEditing;

  UpdateProfileEvent(
      {this.email, this.address, required this.isEditing});
}
