import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = dotenv.env['BASE_URL'].toString();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
  }

  Future<Map<String, dynamic>> logEmergency({
    required String phoneNumber,
    required double longitude,
    required double latitude,
    required String city,
  }) async {
    try {
      final response = await _dio.post('/emergency', data: {
        'phoneNumber': phoneNumber,
        'longitude': longitude,
        'latitude': latitude,
        'city': city,
      });
      return response.data;
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
    required String city,
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
        'city': city,
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

  Future<Map<String, dynamic>> addSosContact({
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
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> removeSosContact({
    required String userPhoneNumber,
    required String contactPhoneNumber,
  }) async {
    try {
      final response = await _dio.delete('/remove_contact', data: {
        'userPhoneNumber': userPhoneNumber,
        'contactPhoneNumber': contactPhoneNumber,
      });
      return response.data;
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
