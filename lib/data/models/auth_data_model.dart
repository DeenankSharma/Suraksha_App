import 'dart:convert';

class AuthData {
  final String phoneNumber;
  final bool isVerified;

  AuthData({required this.phoneNumber, required this.isVerified});

  // Convert to JSON string
  String toJson() {
    return jsonEncode({
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
    });
  }

  // Create from JSON string
  factory AuthData.fromJson(String jsonString) {
    Map<String, dynamic> map = jsonDecode(jsonString);
    return AuthData(
      phoneNumber: map['phoneNumber'],
      isVerified: map['isVerified'],
    );
  }
}
