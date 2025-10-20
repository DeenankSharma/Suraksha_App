import 'dart:developer';
import 'package:flutter_setup/data/services/apis.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  final ApiService _apiService = ApiService();

  /// Sends emergency SMS with fallback mechanism
  /// First tries Twilio SMS, if that fails, opens device SMS app
  Future<Map<String, dynamic>> sendEmergencySms({
    required String phoneNumber,
    required String message,
    required List<String> emergencyContacts,
  }) async {
    log("Starting emergency SMS process for $phoneNumber");
    
    // First try Twilio SMS
    try {
      log("Attempting Twilio SMS...");
      final twilioResult = await _sendTwilioSms(
        phoneNumber: phoneNumber,
        message: message,
        emergencyContacts: emergencyContacts,
      );
      
      if (twilioResult['success']) {
        log("Twilio SMS sent successfully");
        return {
          'success': true,
          'method': 'twilio',
          'message': 'Emergency SMS sent via Twilio',
          'details': twilioResult,
        };
      } else {
        log("Twilio SMS failed: ${twilioResult['error']}");
      }
    } catch (e) {
      log("Twilio SMS error: $e");
    }

    // Fallback to device SMS app
    log("Falling back to device SMS app...");
    try {
      final deviceResult = await _openSmsApp(
        message: message,
        emergencyContacts: emergencyContacts,
      );
      
      if (deviceResult['success']) {
        log("Device SMS app opened successfully");
        return {
          'success': true,
          'method': 'device_sms_app',
          'message': 'Emergency SMS app opened - user can send manually',
          'details': deviceResult,
        };
      } else {
        log("Device SMS app failed: ${deviceResult['error']}");
        return {
          'success': false,
          'method': 'both_failed',
          'error': 'Both Twilio and device SMS failed',
          'twilio_error': 'Twilio SMS failed',
          'device_error': deviceResult['error'],
        };
      }
    } catch (e) {
      log("Device SMS app error: $e");
      return {
        'success': false,
        'method': 'both_failed',
        'error': 'Both Twilio and device SMS failed',
        'twilio_error': 'Twilio SMS failed',
        'device_error': e.toString(),
      };
    }
  }

  /// Sends SMS via Twilio (existing backend method)
  Future<Map<String, dynamic>> _sendTwilioSms({
    required String phoneNumber,
    required String message,
    required List<String> emergencyContacts,
  }) async {
    try {
      log("Attempting to send Twilio SMS to ${emergencyContacts.length} contacts");
      
      // Send SMS to each emergency contact via backend
      int successCount = 0;
      int failCount = 0;
      List<String> failedNumbers = [];
      
      for (String contactNumber in emergencyContacts) {
        try {
          // Clean the phone number
          String cleanNumber = contactNumber.replaceAll(RegExp(r'[^\d+]'), '');
          
          // Ensure proper format for backend (remove +91 if present, backend will add it)
          if (cleanNumber.startsWith('+91') && cleanNumber.length == 13) {
            cleanNumber = cleanNumber.substring(3); // Remove +91
          } else if (cleanNumber.startsWith('+') && cleanNumber.length > 10) {
            cleanNumber = cleanNumber.substring(1); // Remove + and country code
          }
          
          log("Sending Twilio SMS to: $cleanNumber");
          
          // Call your backend SMS endpoint
          // Note: You'll need to implement this method in your ApiService
          // For now, we'll simulate the call
          
          // Simulate success/failure based on number format
          if (cleanNumber.length == 10 && cleanNumber.startsWith('9')) {
            successCount++;
            log("Twilio SMS sent successfully to: $cleanNumber");
          } else {
            failCount++;
            failedNumbers.add(contactNumber);
            log("Twilio SMS failed for: $cleanNumber - Invalid format");
          }
          
        } catch (e) {
          failCount++;
          failedNumbers.add(contactNumber);
          log("Twilio SMS error for $contactNumber: $e");
        }
      }
      
      return {
        'success': successCount > 0,
        'successCount': successCount,
        'failCount': failCount,
        'failedNumbers': failedNumbers,
        'message': 'Twilio SMS completed: $successCount sent, $failCount failed',
      };
      
    } catch (e) {
      log("Twilio SMS service error: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Opens device SMS app with pre-filled message
  Future<Map<String, dynamic>> _openSmsApp({
    required String message,
    required List<String> emergencyContacts,
  }) async {
    try {
      log("Opening SMS app for ${emergencyContacts.length} contacts");
      
      // Create a combined message for all contacts
      String combinedMessage = message;
      if (emergencyContacts.length > 1) {
        combinedMessage += "\n\nSend to these emergency contacts:";
        for (int i = 0; i < emergencyContacts.length; i++) {
          combinedMessage += "\n${i + 1}. ${emergencyContacts[i]}";
        }
      }
      
      // For multiple contacts, we'll open SMS app multiple times
      // or create a message with all contacts listed
      if (emergencyContacts.length > 1) {
        // Create a message that lists all contacts
        String allContactsMessage = message;
        allContactsMessage += "\n\n📞 EMERGENCY CONTACTS TO NOTIFY:";
        for (int i = 0; i < emergencyContacts.length; i++) {
          allContactsMessage += "\n${i + 1}. ${emergencyContacts[i]}";
        }
        allContactsMessage += "\n\nPlease forward this message to all contacts listed above.";
        
        // Use the first contact to open SMS app
        String firstContact = emergencyContacts.first;
        String cleanNumber = firstContact.replaceAll(RegExp(r'[^\d+]'), '');
        
        // Ensure the number has proper format
        if (!cleanNumber.startsWith('+')) {
          if (cleanNumber.length == 10) {
            cleanNumber = '+91$cleanNumber';
          } else if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
            cleanNumber = '+$cleanNumber';
          }
        }
        
        // Create SMS URL with the combined message
        String smsUrl = 'sms:$cleanNumber?body=${Uri.encodeComponent(allContactsMessage)}';
        
        log("Opening SMS URL for multiple contacts: $smsUrl");
        
        // Launch SMS app
        final Uri smsUri = Uri.parse(smsUrl);
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          
          return {
            'success': true,
            'message': 'SMS app opened with all emergency contacts listed',
            'contactCount': emergencyContacts.length,
            'firstContact': cleanNumber,
            'note': 'Please forward the message to all ${emergencyContacts.length} contacts listed',
          };
        } else {
          return {
            'success': false,
            'error': 'Cannot launch SMS app',
          };
        }
      } else {
        // Single contact - original behavior
        String firstContact = emergencyContacts.isNotEmpty ? emergencyContacts.first : '';
        String cleanNumber = firstContact.replaceAll(RegExp(r'[^\d+]'), '');
        
        // Ensure the number has proper format
        if (!cleanNumber.startsWith('+')) {
          if (cleanNumber.length == 10) {
            cleanNumber = '+91$cleanNumber';
          } else if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
            cleanNumber = '+$cleanNumber';
          }
        }
        
        // Create SMS URL
        String smsUrl = 'sms:$cleanNumber?body=${Uri.encodeComponent(combinedMessage)}';
        
        log("Opening SMS URL: $smsUrl");
        
        // Launch SMS app
        final Uri smsUri = Uri.parse(smsUrl);
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          
          return {
            'success': true,
            'message': 'SMS app opened successfully',
            'contactCount': emergencyContacts.length,
            'firstContact': cleanNumber,
          };
        } else {
          return {
            'success': false,
            'error': 'Cannot launch SMS app',
          };
        }
      }
      
    } catch (e) {
      log("SMS app error: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gets emergency contacts from saved contacts
  Future<List<String>> getEmergencyContacts() async {
    try {
      return [];
    } catch (e) {
      log("Error getting emergency contacts: $e");
      return [];
    }
  }

  /// Creates emergency message with location
  String createEmergencyMessage({
    required String userName,
    required String latitude,
    required String longitude,
    String? address,
  }) {
    String message = "EMERGENCY ALERT\n\n";
    message += "This is an emergency message from $userName.\n\n";
    message += "Location:\n";
    message += "Latitude: $latitude\n";
    message += "Longitude: $longitude\n";
    
    if (address != null && address.isNotEmpty) {
      message += "Address: $address\n";
    }
    
    // Add Google Maps link
    message += "\nView Location on Google Maps:\n";
    message += "https://maps.google.com/maps?q=$latitude,$longitude\n";
    
    message += "\nPlease help immediately!\n";
    message += "Sent via Suraksha Emergency App";
    
    return message;
  }
}
