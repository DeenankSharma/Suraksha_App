import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "https://39c5-103-37-201-221.ngrok-free.app";

  ApiService() {
    _dio.options.baseUrl = baseUrl;
  }

  Future<Map<String, dynamic>> logEmergency({
    required String phoneNumber,
    required double longitude,
    required double latitude,
  }) async {
    try {
      final response = await _dio.post('/emergency', data: {
        'phoneNumber': phoneNumber,
        'longitude': longitude,
        'latitude': latitude,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLogs({
    required String phoneNumber,
  }) async {
    try {
      final response1 = await _dio
          .get('/get_logs', queryParameters: {"phone_number": phoneNumber});
      final response2 = await _dio.get('/get_detailed_logs',
          queryParameters: {"phone_number": phoneNumber});
      final response = {
        'logs': response1.data,
        'detailed_logs': response2.data
      };
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> logDetailedEmergency({
    required String phoneNumber,
    required double longitude,
    required double latitude,
    required String area,
    required String description,
    // required String city,
    String? landmark,
  }) async {
    try {
      final response = await _dio.post('/descriptive_emergency', data: {
        'phoneNumber': phoneNumber,
        'longitude': longitude,
        'latitude': latitude,
        'area': area,
        'landmark': landmark,
        'description': description,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getSavedContacts(String phoneNumber) async {
    try {
      final response = await _dio.get('/saved_contacts',
          queryParameters: {'phoneNumber': phoneNumber});
      return response.data['contacts'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int?> addSosContact({
    required String userPhoneNumber,
    required String contactName,
    required String contactPhoneNumber,
  }) async {
    try {
      final response = await _dio.post('/add_contact', data: {
        'userPhoneNumber': userPhoneNumber,
        'contactName': contactName,
        'contactPhoneNumber': contactPhoneNumber,
      });
      return response.statusCode;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int?> removeSosContact({
    required String userPhoneNumber,
    required String contactPhoneNumber,
  }) async {
    try {
      final response = await _dio.delete('/remove_contact', data: {
        'userPhoneNumber': userPhoneNumber,
        'contactPhoneNumber': contactPhoneNumber,
      });
      return response.statusCode;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginUser(String phoneNumber) async {
    try {
      final response = await _dio.post('/login', data: {
        'phoneNumber': phoneNumber,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get('/get_location', queryParameters: {
        'lat': latitude,
        'long': longitude,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(e.response?.data['error'] ?? 'Server error occurred');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timed out');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Response timed out');
    } else {
      return Exception('Network error occurred');
    }
  }
}
