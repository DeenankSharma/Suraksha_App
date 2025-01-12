import 'package:bloc/bloc.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_setup/data/services/apis.dart';
import 'package:flutter_setup/utils/get_location.dart';
import 'package:location/location.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart'
    as contactPermission;
import 'package:shared_preferences/shared_preferences.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<ShowContactsEvent>(showContactsEvent);
    on<AddContactEvent>(addContactEvent);
    on<RemoveContactEvent>(removeContactEvent);
    on<SendOtpEvent>(sendOtpEvent);
    on<VerifyOtpEvent>(verifyOtpEvent);
    on<HomeScreenEvent>(bringBacktoHomeScreen);
    on<HelpButtonClickedEvent>(callForEmergencyHelp);
    on<HelpFormSubmittedEvent>(helpFormSubmission);
    on<GetContactLogsEvent>(onFetchLogs);
    on<OpenSettingsEvent>(openSettings);
  }

  String phone_number = '';

  Future<void> openSettings(
    OpenSettingsEvent event,
    Emitter<HomeState> emit,
  ) async {
    //logic here
  }

  Future<void> onFetchLogs(
    GetContactLogsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(LogsLoadingState());
    try {
      ApiService api = ApiService();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String pn = prefs.getString('pn')!;
      final logs = await api.getLogs(phoneNumber: pn);
      emit(LogsFetchedState(logs));
    } catch (e) {
      emit(LogsErrorState(e.toString()));
    }
  }

  Future<void> helpFormSubmission(
      HelpFormSubmittedEvent event, Emitter<HomeState> emit) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String pn = prefs.getString('pn')!;
      ApiService api = ApiService();
      Map<String, dynamic>? _locationData = await getLocation();
      api.logDetailedEmergency(
        phoneNumber: pn,
        longitude: _locationData?['longitude'],
        latitude: _locationData?['latitude'],
        area: event.area,
        description: event.description,
        landmark: event.landmark,
      );

      emit(HelpRequestedState("desc"));
    } catch (er) {
      print(er);
    }
    // emit(HelpRequestedState("description"));
  }

  Future<void> callForEmergencyHelp(
    HelpButtonClickedEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String pn = prefs.getString('pn')!;
      ApiService api = ApiService();
      Map<String, dynamic>? _locationData = await getLocation();
      api.logEmergency(
          phoneNumber: pn,
          longitude: _locationData?['longitude'],
          latitude: _locationData?['latitude']);
      emit(HelpRequestedState("emer"));
    } catch (er) {
      print(er);
    }
    // emit(HelpRequestedState());
  }

  Future<void> bringBacktoHomeScreen(
    HomeScreenEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeScreenState());
  }

  Future<void> sendOtpEvent(
    SendOtpEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(OtpLoadingState());
      phone_number = event.phoneNumber;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${event.phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.setString('pn', event.phoneNumber);

            emit(OtpVerifiedState());
          } catch (e) {
            phone_number = '';
            emit(OtpErrorState('Auto-verification failed: ${e.toString()}'));
          }
        },
        verificationFailed: (FirebaseAuthException ex) {
          String errorMessage;

          switch (ex.code) {
            case 'invalid-phone-number':
              errorMessage = 'The provided phone number is invalid.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection.';
              break;
            default:
              errorMessage = 'Verification failed: ${ex.message}';
          }
          phone_number = '';
          emit(OtpErrorState(errorMessage));
        },
        codeSent: (String verificationId, int? resendToken) {
          emit(OtpSentState(
            verificationId: verificationId,
            resendToken: resendToken,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          emit(OtpSentState(
            verificationId: verificationId,
            resendToken: null,
          ));
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(OtpErrorState('Unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> verifyOtpEvent(
    VerifyOtpEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(OtpLoadingState());

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pn', phone_number);
      emit(OtpVerifiedState());
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please try again.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification. Please request new OTP.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message}';
      }

      emit(OtpErrorState(errorMessage));
    } catch (e) {
      emit(OtpErrorState('Unexpected error occurred: ${e.toString()}'));
    }
  }

  // Future<void> showContactsEvent(
  //   ShowContactsEvent event,
  //   Emitter<HomeState> emit,
  // ) async {
  //   try {
  //     emit(ContactsLoadingState());
  //
  //     final result = await getContacts();
  //
  //     if (result['success']) {
  //       emit(ContactsFetchedState(result['contacts']));
  //     } else {
  //       emit(ContactsErrorState(result['error'].toString()));
  //     }
  //   } catch (err) {
  //     emit(ContactsErrorState(err.toString()));
  //   }
  // }
  Future<void> showContactsEvent(
    ShowContactsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(ContactsLoadingState());

      // Get device contacts
      final deviceContacts = await getDeviceContacts();

      // Get saved SOS contacts
      final savedContacts = await getSavedContacts();

      if (deviceContacts['success'] && savedContacts['success']) {
        // Merge and process contacts
        final processedContacts = processContacts(
          deviceContacts['contacts'],
          savedContacts['contacts'],
        );
        emit(ContactsFetchedState(processedContacts));
      } else {
        emit(ContactsErrorState('Failed to fetch contacts'));
      }
    } catch (err) {
      emit(ContactsErrorState(err.toString()));
    }
  }

  Future<void> addContactEvent(
    AddContactEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(ContactsLoadingState());
      ApiService api = ApiService();
      // final response = await api.post(
      //   Uri.parse('$baseUrl/add_contact'),
      //   body: {
      //     'userPhoneNumber': 'YOUR_USER_PHONE', // Replace with actual user phone
      //     'contactName': event.contact['displayName'],
      //     'contactPhoneNumber': event.contact['phones'][0],
      //   },
      // );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final pn = await prefs.getString('pn');
      final response = api.addSosContact(
          userPhoneNumber: pn!,
          contactName: event.contact['displayName'],
          contactPhoneNumber: event.contact['phones'][0]);

      if (response == 201) {
        add(ShowContactsEvent());
      } else {
        emit(ContactsErrorState('Failed to add contact'));
      }
    } catch (err) {
      emit(ContactsErrorState(err.toString()));
    }
  }

  Future<void> removeContactEvent(
    RemoveContactEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(ContactsLoadingState());

      // final response = await http.delete(
      //   Uri.parse('$baseUrl/remove_contact'),
      //   body: {
      //     'userPhoneNumber': 'YOUR_USER_PHONE', // Replace with actual user phone
      //     'contactPhoneNumber': event.contact['phones'][0],
      //   },
      // );
      ApiService api = ApiService();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final pn = await prefs.getString('pn');
      final response = api.removeSosContact(
          userPhoneNumber: pn!, contactPhoneNumber: event.contact['phones'][0]);

      if (response == 200) {
        add(ShowContactsEvent());
      } else {
        emit(ContactsErrorState('Failed to remove contact'));
      }
    } catch (err) {
      emit(ContactsErrorState(err.toString()));
    }
  }

  Future<Map<String, dynamic>> getDeviceContacts() async {
    try {
      List<Contact> contacts = [];
      List<ContactField> fields = ContactField.values.toList();

      final permissionStatus =
          await contactPermission.Permission.contacts.request();
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
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'contacts': [],
      };
    }
  }

  Future<Map<String, dynamic>> getSavedContacts() async {
    try {
      // final response = await http.get(
      //   Uri.parse(
      //       '$baseUrl/saved_contacts?phoneNumber=YOUR_USER_PHONE'), // Replace with actual user phone
      // );
      //
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final pn = await prefs.getString('pn');
      ApiService api = ApiService();
      final response = await api.getSavedContacts(pn!);
      // if (response == 200) {
      return {
        'success': true,
        // 'error': e.toString(),
        'contacts': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'contacts': [],
      };
    }
  }

  List<Map<String, dynamic>> processContacts(
    List<Map<String, dynamic>> deviceContacts,
    List<Map<String, dynamic>> savedContacts,
  ) {
    final savedPhones = Set<String>.from(
      savedContacts.map((c) => c['contactPhoneNumber']),
    );

    final processed = deviceContacts.map((contact) {
      final phone = contact['phones'].isNotEmpty ? contact['phones'][0] : '';
      return {
        ...contact,
        'isSaved': savedPhones.contains(phone),
      };
    }).toList();

    processed.sort((a, b) {
      if (a['isSaved'] && !b['isSaved']) return -1;
      if (!a['isSaved'] && b['isSaved']) return 1;
      return a['displayName'].compareTo(b['displayName']);
    });

    return processed;
  }

  Future<Map<String, dynamic>> getContacts() async {
    try {
      List<Contact> contacts = [];
      List<ContactField> fields = ContactField.values.toList();

      final permissionStatus =
          await contactPermission.Permission.contacts.request();
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
