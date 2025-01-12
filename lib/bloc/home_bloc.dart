import 'package:bloc/bloc.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<ShowContactsEvent>(showContactsEvent);
    on<SendOtpEvent>(sendOtpEvent);
    on<VerifyOtpEvent>(verifyOtpEvent);
    on<HomeScreenEvent>(bringBacktoHomeScreen);
  }

  String phone_number = '';

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

  Future<void> showContactsEvent(
    ShowContactsEvent event,
    Emitter<HomeState> emit,
  ) async {
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
