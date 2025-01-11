part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

class ContactsLoadingState extends HomeState {}

class ContactsFetchedState extends HomeState {
  final List<Map<String, dynamic>> contacts;
  ContactsFetchedState(this.contacts);
}

class ContactsErrorState extends HomeState {
  final String error;
  ContactsErrorState(this.error);
}
