import 'package:bloc/bloc.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<ShowContactsEvent>(showContactsEvent);
  }

  Future<void> showContactsEvent(
      ShowContactsEvent event, Emitter<HomeState> emit) async {
    try {
      emit(ContactsLoadingState());

      final result = await getContacts();

      if (result['success']) {
        emit(ContactsFetchedState(result['contacts']));
      } else {
        emit(ContactsErrorState(result['error'].toString()));
      }
    } catch (err) {
      emit(ContactsErrorState(err.toString()));
    }
  }

  Future<Map<String, dynamic>> getContacts() async {
    try {
      List<Contact> contacts = [];
      List<ContactField> fields = ContactField.values.toList();

      final permissionStatus = await Permission.contacts.request();
      if (permissionStatus != PermissionStatus.granted) {
        throw Exception('Contacts permission not granted');
      }

      contacts = await FastContacts.getAllContacts(fields: fields);

      List<Map<String, dynamic>> processedContacts = contacts.map((contact) {
        return {
          'id': contact.id,
          'displayName': contact.displayName,
          'phones': contact.phones.map((phone) => phone.number).toList(),
        };
      }).toList();

      return {
        'success': true,
        'contacts': processedContacts,
        'count': contacts.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'contacts': [],
        'count': 0,
      };
    }
  }
}
