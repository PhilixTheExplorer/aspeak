import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Base URLs for different environments
  static const String _androidEmulatorUrl = 'https://c2c9-202-28-7-39.ngrok-free.app';
  static const String _iosSimulatorUrl = 'https://c2c9-202-28-7-39.ngrok-free.app';
  static const String _physicalDeviceUrl = 'https://c2c9-202-28-7-39.ngrok-free.app'; // Replace with your computer's IP

  String response = "Waiting for response";
  // Get the appropriate base URL based on the platform
  static String get baseUrl {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _androidEmulatorUrl;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _iosSimulatorUrl;
      }
    }
    return _physicalDeviceUrl;
  }

  // Example GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to make GET request: $e');
    }
  }

  // Example POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to make POST request: $e');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API request failed with status code: ${response.statusCode}');
    }
  }
} 