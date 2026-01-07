import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:call_log/call_log.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter_setup/data/services/apis.dart';
import 'package:flutter_setup/data/services/sms_service.dart';
import 'package:flutter_setup/utils/get_location.dart';
import 'package:location/location.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart'
    as contactPermission;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/auth_data_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  bool _isLoadingContacts = false;

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
    on<UpdateProfileEvent>(updateProfile);
    on<LogoutEvent>(logoutEvent);
    on<GetStartedEvent>(getStarted);
  }

  Future<void> openSettings(
    OpenSettingsEvent event,
    Emitter<HomeState> emit,
  ) async {
    //logic here
  }

  Future<void> getStarted(
    GetStartedEvent event,
    Emitter<HomeState> emit,
  ) async {
    const String prefsKey = 'auth_data';
    final prefs = await SharedPreferences.getInstance();
    final String? authJson = prefs.getString(prefsKey);

    // Scenario 1: No data found -> Login
    if (authJson == null) {
      emit(NavigateToLoginState());
      return;
    }

    try {
      final authData = AuthData.fromJson(authJson);

      if (authData.isVerified) {
        // Scenario 3: Verified -> Home
        emit(NavigateToHomeState());
      } else {
        // Scenario 2: Exists but not verified -> OTP
        // We might want to resend OTP here automatically,
        // but for now, we just navigate to the screen.
        emit(NavigateToOtpState(authData.phoneNumber));
      }
    } catch (e) {
      // Corrupt data -> Clear and Login
      await prefs.remove(prefsKey);
      emit(NavigateToLoginState());
    }
  }

  Future<void> onFetchLogs(
    GetContactLogsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(LogsLoadingState());
    const String prefsKey = 'auth_data';

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      // 1. Check if auth data exists. If not, force login.
      if (authJson == null) {
        dev.log('No auth data found, navigating to login.');
        emit(NavigateToLoginState());
        return;
      }

      AuthData authData;

      // 2. Try parsing the data. If corrupt, clear prefs and force login.
      try {
        authData = AuthData.fromJson(authJson);
      } catch (e) {
        dev.log('Auth data corrupted: $e');
        await prefs.remove(prefsKey);
        emit(NavigateToLoginState());
        return;
      }

      // 3. Proceed with API call using the parsed phone number
      ApiService api = ApiService();
      dev.log('Fetching logs for phone number: ${authData.phoneNumber}');

      final logs = await api.getLogs(phoneNumber: authData.phoneNumber);

      dev.log('Logs fetched successfully: ${logs.toString()}');
      emit(LogsFetchedState(logs));
    } catch (e) {
      // 4. Handle API/Network errors (Do not logout here, just show error)
      dev.log('Error fetching logs: $e');
      emit(LogsErrorState(e.toString()));
    }
  }

  Future<void> helpFormSubmission(
      HelpFormSubmittedEvent event, Emitter<HomeState> emit) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String phoneNumber = prefs.getString('phoneNumber')!;
      ApiService api = ApiService();
      Map<String, dynamic>? _locationData = await getLocation();
      api.logDetailedEmergency(
        phoneNumber: phoneNumber,
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
      final String phoneNumber = prefs.getString('phoneNumber')!;
      dev.log("Emergency help requested for phone: $phoneNumber");

      ApiService api = ApiService();
      dev.log("API service initialized");

      Map<String, dynamic>? locationData = await getLocation();
      dev.log("Location data fetched: $locationData");

      final response = await api.logEmergency(
          phoneNumber: phoneNumber,
          longitude: locationData?['longitude'],
          latitude: locationData?['latitude']);
      dev.log("Emergency logged to backend: ${response.toString()}");

      await _sendEmergencySmsWithFallback(
        phoneNumber: phoneNumber,
        locationData: locationData,
        emit: emit,
      );

      emit(HelpRequestedState("emer"));
    } catch (er) {
      dev.log("Error in emergency help: $er");
      emit(HelpRequestedState("emer"));
    }
  }

  Future<void> _sendEmergencySmsWithFallback({
    required String phoneNumber,
    required Map<String, dynamic>? locationData,
    required Emitter<HomeState> emit,
  }) async {
    try {
      final SmsService smsService = SmsService();

      final emergencyContacts = await _getEmergencyContacts();
      if (emergencyContacts.isEmpty) {
        dev.log("No emergency contacts found");
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Emergency User';

      final message = smsService.createEmergencyMessage(
        userName: userName,
        latitude: locationData?['latitude']?.toString() ?? 'Unknown',
        longitude: locationData?['longitude']?.toString() ?? 'Unknown',
        address: locationData?['address'],
      );

      dev.log("Sending emergency SMS to ${emergencyContacts.length} contacts");

      // Send SMS with fallback
      final smsResult = await smsService.sendEmergencySms(
        phoneNumber: phoneNumber,
        message: message,
        emergencyContacts: emergencyContacts,
      );

      if (smsResult['success']) {
        dev.log("Emergency SMS sent successfully via ${smsResult['method']}");
      } else {
        dev.log("Emergency SMS failed: ${smsResult['error']}");
      }
    } catch (e) {
      dev.log("Error in SMS fallback: $e");
    }
  }

  Future<List<String>> _getEmergencyContacts() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final emergencyNumbers =
          prefs.getStringList('emergency_contact_numbers') ?? [];

      dev.log("Found ${emergencyNumbers.length} emergency contacts from setup");

      if (emergencyNumbers.isEmpty) {
        final String phoneNumber = prefs.getString('phoneNumber') ?? '';
        if (phoneNumber.isNotEmpty) {
          final ApiService api = ApiService();
          final savedContacts = await api.getSavedContacts(phoneNumber);

          for (var contact in savedContacts) {
            final phoneNumber = contact['contactPhoneNumber']?.toString();
            if (phoneNumber != null && phoneNumber.isNotEmpty) {
              emergencyNumbers.add(phoneNumber);
            }
          }
        }
      }

      dev.log("Found ${emergencyNumbers.length} emergency contacts");
      return emergencyNumbers;
    } catch (e) {
      dev.log("Error getting emergency contacts: $e");
      return [];
    }
  }

  Future<void> bringBacktoHomeScreen(
    HomeScreenEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeScreenState());
  }

  late String phoneNumber; // Declare as class member

  Future<void> sendOtpEvent(
    SendOtpEvent event,
    Emitter<HomeState> emit,
  ) async {
    const String prefsKey = 'auth_data';

    try {
      emit(OtpLoadingState());
      final phoneNumber = event.phoneNumber;

      // 1. Save strictly as AuthData (Unverified)
      final authData = AuthData(phoneNumber: phoneNumber, isVerified: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, authData.toJson());

      // 2. Call API
      ApiService apiService = ApiService();
      // NOTE: Ensure your ApiService doesn't rely on 'phoneNumber' from shared prefs internally
      await apiService.loginUser(phoneNumber);

      emit(OtpSentState());
    } catch (e) {
      // Error handling: Clear struct
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);

      emit(OtpErrorState(e.toString()));
    }
  }

  Future<void> verifyOtpEvent(
    VerifyOtpEvent event,
    Emitter<HomeState> emit,
  ) async {
    const String prefsKey = 'auth_data';

    try {
      emit(OtpLoadingState());

      final prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      if (authJson == null) {
        emit(OtpErrorState("Session expired. Please login again."));
        return;
      }

      // Read current phone number from AuthData
      final currentAuth = AuthData.fromJson(authJson);
      final phoneNumber = currentAuth.phoneNumber;

      ApiService apiService = ApiService();
      final response = await apiService.verifyOtp(event.otp, phoneNumber);

      if (response['success']) {
        // Success: Update AuthData to Verified
        final newAuth = AuthData(phoneNumber: phoneNumber, isVerified: true);
        await prefs.setString(prefsKey, newAuth.toJson());

        emit(OtpVerifiedState());
      } else {
        // Failure: Delete struct as requested
        await prefs.remove(prefsKey);
        emit(OtpErrorState('Verification failed'));
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
      emit(OtpErrorState(e.toString()));
    }
  }

  Future<void> showContactsEvent(
    ShowContactsEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (_isLoadingContacts) {
      print("Contacts are already being loaded, skipping...");
      return;
    }

    try {
      _isLoadingContacts = true;
      emit(ContactsLoadingState());

      print("Fetching device contacts...");
      final deviceContactsResult = await getDeviceContacts();
      if (!deviceContactsResult['success']) {
        print("Device contacts error: ${deviceContactsResult['error']}");
        emit(ContactsErrorState(deviceContactsResult['error'].toString()));
        return;
      }

      print("Fetching saved contacts...");
      final savedContactsResult = await getSavedContacts(emit);
      if (!savedContactsResult['success']) {
        print("Saved contacts error: ${savedContactsResult['error']}");
        emit(ContactsErrorState(savedContactsResult['error'].toString()));
        return;
      }

      print("Fetching call logs...");
      final callLogsResult = await getCallLogs();
      if (!callLogsResult['success']) {
        print("Call logs error: ${callLogsResult['error']}");
      }

      print("Processing contacts...");
      final processedContacts = processContacts(
        deviceContactsResult['contacts'],
        savedContactsResult['contacts'],
        callLogsResult['callLogs'] ?? [],
      );

      print("Successfully loaded ${processedContacts.length} contacts");
      emit(ContactsFetchedState(processedContacts));
    } catch (err) {
      print("Error in showContactsEvent: $err");
      emit(ContactsErrorState('Failed to load contacts: ${err.toString()}'));
    } finally {
      _isLoadingContacts = false;
    }
  }

  Future<void> addContactEvent(
    AddContactEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(ContactsLoadingState());

      // 1. Get Auth Data
      const String prefsKey = 'auth_data';
      final prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      if (authJson == null) {
        emit(ContactsErrorState('User session not found.'));
        return;
      }

      // 2. Parse Phone Number
      final authData = AuthData.fromJson(authJson);
      final phoneNumber = authData.phoneNumber;

      if (phoneNumber.isEmpty) {
        emit(ContactsErrorState('Invalid user data.'));
        return;
      }

      // 3. Prepare Contact Data
      final contactName = event.contact['displayName'] ?? 'Unknown';
      final contactPhone = event.contact['phones']?.isNotEmpty == true
          ? event.contact['phones'][0].toString()
          : '';

      if (contactPhone.isEmpty) {
        emit(ContactsErrorState('Invalid contact phone number'));
        return;
      }

      // 4. Call API
      ApiService api = ApiService();
      print("Adding contact: $contactName ($contactPhone)");

      final response = await api.addSosContact(
          userPhoneNumber: phoneNumber,
          contactName: contactName,
          contactPhoneNumber: contactPhone);

      if (response == 200) {
        print("Contact added successfully");
        add(ShowContactsEvent());
      } else {
        emit(ContactsErrorState('Failed to add contact'));
      }
    } catch (err) {
      print("Error adding contact: $err");
      emit(ContactsErrorState('Failed to add contact: ${err.toString()}'));
    }
  }

  Future<void> removeContactEvent(
    RemoveContactEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(ContactsLoadingState());

      // 1. Get Auth Data
      const String prefsKey = 'auth_data';
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      if (authJson == null) {
        emit(ContactsErrorState('User session not found.'));
        return;
      }

      // 2. Parse Phone Number
      final authData = AuthData.fromJson(authJson);
      final phoneNumber = authData.phoneNumber;

      // 3. Extract Contact Phone Number safely
      final contactPhones = event.contact['phones'];
      String contactPhoneNumber = '';

      if (contactPhones != null &&
          (contactPhones is List) &&
          contactPhones.isNotEmpty) {
        contactPhoneNumber = contactPhones[0].toString();
      } else {
        emit(ContactsErrorState('Invalid contact phone number'));
        return;
      }

      // 4. Call API
      ApiService api = ApiService();
      final response = await api.removeSosContact(
          userPhoneNumber: phoneNumber, contactPhoneNumber: contactPhoneNumber);

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

      // Request permission and check if it was granted
      final permissionStatus =
          await contactPermission.Permission.contacts.request();
      print("Permission status: $permissionStatus");

      if (permissionStatus != contactPermission.PermissionStatus.granted) {
        return {
          'success': false,
          'error':
              'Contacts permission not granted. Please enable contacts permission in settings.',
          'contacts': [],
        };
      }

      print("Permission granted, fetching contacts...");
      contacts = await FastContacts.getAllContacts(fields: fields);
      print("Fetched ${contacts.length} contacts");

      List<Map<String, dynamic>> processedContacts = contacts.map((contact) {
        return {
          'id': contact.id,
          'displayName': contact.displayName,
          'phones': contact.phones.map((phone) => phone.number).toList(),
        };
      }).toList();

      print("Processed ${processedContacts.length} contacts");
      return {
        'success': true,
        'contacts': processedContacts,
      };
    } catch (e) {
      print("Error in getDeviceContacts: $e");
      return {
        'success': false,
        'error': 'Failed to load contacts: ${e.toString()}',
        'contacts': [],
      };
    }
  }

  Future<Map<String, dynamic>> getSavedContacts(Emitter<HomeState> emit) async {
    const String prefsKey = 'auth_data';

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      // 1. Check if auth data exists. If not, navigate to login.
      if (authJson == null) {
        print("No auth data found in getSavedContacts");
        emit(NavigateToLoginState());
        return {'success': false, 'contacts': []};
      }

      AuthData authData;

      // 2. Try parsing the data. If corrupt, clear prefs and navigate to login.
      try {
        authData = AuthData.fromJson(authJson);
      } catch (e) {
        print("Auth data corrupted in getSavedContacts: $e");
        await prefs.remove(prefsKey);
        emit(NavigateToLoginState());
        return {'success': false, 'contacts': []};
      }

      final String phoneNumber = authData.phoneNumber;

      // 3. Call the API
      print("Fetching saved contacts for phone: $phoneNumber");
      ApiService api = ApiService();
      final response = await api.getSavedContacts(phoneNumber);

      print("Raw saved contacts response: $response");

      return {
        'success': true,
        'contacts': response,
      };
    } catch (e) {
      print("Error fetching saved contacts: $e");
      // Note: For network errors, we usually just return failure so the UI shows a snackbar,
      // rather than logging the user out.
      return {
        'success': false,
        'error': 'Failed to fetch saved contacts: ${e.toString()}',
        'contacts': [],
      };
    }
  }

  Future<Map<String, dynamic>> getCallLogs() async {
    try {
      final callLogPermission = await contactPermission.Permission.phone.status;
      if (callLogPermission != contactPermission.PermissionStatus.granted) {
        final requestResult =
            await contactPermission.Permission.phone.request();
        if (requestResult != contactPermission.PermissionStatus.granted) {
          return {
            'success': false,
            'error': 'Call log permission not granted',
            'callLogs': [],
          };
        }
      }

      dev.log("Call log permission granted, fetching call logs...");

      Iterable<CallLogEntry> entries = await CallLog.get();

      // Convert to list and filter recent calls (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      List<Map<String, dynamic>> callLogs = entries
          .where((entry) =>
              entry.timestamp != null &&
              DateTime.fromMillisecondsSinceEpoch(entry.timestamp!)
                  .isAfter(thirtyDaysAgo))
          .map((entry) => {
                'phoneNumber': entry.number ?? '',
                'callType': entry.callType?.toString() ?? 'unknown',
                'timestamp': entry.timestamp,
                'duration': entry.duration,
              })
          .toList();

      dev.log("Found ${callLogs.length} call logs from last 30 days");

      return {
        'success': true,
        'callLogs': callLogs,
      };
    } catch (e) {
      dev.log("Error fetching call logs: $e");
      return {
        'success': false,
        'error': 'Failed to fetch call logs: ${e.toString()}',
        'callLogs': [],
      };
    }
  }

  List<Map<String, dynamic>> processContacts(
    List<Map<String, dynamic>> deviceContacts,
    dynamic savedContactsRaw,
    List<Map<String, dynamic>> callLogs,
  ) {
    List<Map<String, dynamic>> savedContacts = [];
    try {
      if (savedContactsRaw is List) {
        savedContacts = savedContactsRaw.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return <String, dynamic>{};
          }
        }).toList();
      }
    } catch (e) {
      print("Error processing saved contacts: $e");
      savedContacts = [];
    }

    print(
        "Processing ${deviceContacts.length} device contacts with ${savedContacts.length} saved contacts and ${callLogs.length} call logs");

    final savedPhones = Set<String>.from(
      savedContacts.map((c) => c['contactPhoneNumber']?.toString() ?? ''),
    );

    Map<String, int> callCounts = {};
    for (var log in callLogs) {
      try {
        final phoneNumber = log['phoneNumber']?.toString() ?? '';
        if (phoneNumber.isNotEmpty) {
          String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

          List<String> possibleNumbers = [cleanNumber];

          if (cleanNumber.startsWith('+91') && cleanNumber.length == 13) {
            possibleNumbers.add(cleanNumber.substring(3));
          } else if (cleanNumber.length == 10) {
            possibleNumbers.add('+91$cleanNumber');
          }

          for (String number in possibleNumbers) {
            callCounts[number] = (callCounts[number] ?? 0) + 1;
          }
        }
      } catch (e) {
        print("Error processing call log: $e");
      }
    }

    dev.log("Call counts calculated: ${callCounts.length} unique numbers");

    final processedDeviceContacts = deviceContacts.map((contact) {
      final phone =
          contact['phones'].isNotEmpty ? contact['phones'][0].toString() : '';

      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      int callCount = 0;

      if (callCounts.containsKey(cleanPhone)) {
        callCount = callCounts[cleanPhone]!;
      } else {
        if (cleanPhone.startsWith('+91') && cleanPhone.length == 13) {
          String withoutCountryCode = cleanPhone.substring(3);
          callCount = callCounts[withoutCountryCode] ?? 0;
        } else if (cleanPhone.length == 10) {
          String withCountryCode = '+91$cleanPhone';
          callCount = callCounts[withCountryCode] ?? 0;
        }
      }

      return {
        ...contact,
        'isSaved': savedPhones.contains(phone),
        'callCount': callCount,
        'isManual': false,
      };
    }).toList();

    final devicePhones = Set<String>.from(
      deviceContacts
          .map((c) => c['phones'].isNotEmpty ? c['phones'][0].toString() : ''),
    );

    final manualContacts = savedContacts.where((savedContact) {
      final phone = savedContact['contactPhoneNumber']?.toString() ?? '';
      return phone.isNotEmpty && !devicePhones.contains(phone);
    }).map((savedContact) {
      final phone = savedContact['contactPhoneNumber']?.toString() ?? '';
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      int callCount = 0;
      if (callCounts.containsKey(cleanPhone)) {
        callCount = callCounts[cleanPhone]!;
      } else {
        if (cleanPhone.startsWith('+91') && cleanPhone.length == 13) {
          String withoutCountryCode = cleanPhone.substring(3);
          callCount = callCounts[withoutCountryCode] ?? 0;
        } else if (cleanPhone.length == 10) {
          String withCountryCode = '+91$cleanPhone';
          callCount = callCounts[withCountryCode] ?? 0;
        }
      }

      return {
        'id': 'manual_${savedContact['contactPhoneNumber']}',
        'displayName': savedContact['contactName'] ?? 'Unknown',
        'phones': [savedContact['contactPhoneNumber']?.toString() ?? ''],
        'isSaved': true,
        'callCount': callCount,
        'isManual': true,
      };
    }).toList();

    // Combine device and manual contacts
    final allContacts = [...processedDeviceContacts, ...manualContacts];

    // Sort contacts
    allContacts.sort((a, b) {
      if (a['isSaved'] && !b['isSaved']) return -1;
      if (!a['isSaved'] && b['isSaved']) return 1;
      return a['displayName'].compareTo(b['displayName']);
    });

    print(
        "Final processed contacts: ${allContacts.length} (${processedDeviceContacts.length} device + ${manualContacts.length} manual)");
    return allContacts;
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

  Future<void> updateProfile(
    UpdateProfileEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.isEditing) {
        final ApiService api = ApiService();
        await api.updateProfile(email: event.email!, address: event.address!);
        emit(ProfileUpdatedState(
            !event.isEditing, event.email!, event.address!));
      } else {
        emit(ProfileUpdatedState(
            !event.isEditing, event.email!, event.address!));
      }
    } catch (e) {
      print("error in updating profile");
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> logoutEvent(
    LogoutEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Clear all stored user data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Emit logout state
      emit(LogoutState());

      dev.log("User logged out successfully");
    } catch (e) {
      dev.log("Error during logout: $e");
      emit(ProfileErrorState("Logout failed: ${e.toString()}"));
    }
  }
}
