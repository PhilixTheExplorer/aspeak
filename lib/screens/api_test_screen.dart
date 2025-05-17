import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  String _response = 'No data yet';
  bool _isLoading = false;
  String _connectionStatus = 'Not tested';
  String _currentStep = '';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _response = 'Testing connection...';
      _connectionStatus = 'Testing...';
      _currentStep = 'Checking network connectivity...';
    });

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      } 
      // First test the health endpoint
      final healthData = await _apiService.get('/health/');
      setState(() {
        _connectionStatus = 'Connected to server';
        _response = 'Health check response: $healthData';
      });

      // Then test available options
      final optionsData = await _apiService.get('/available-options/');
      setState(() {
        _response = 'Available options: $optionsData';
      });
    } on SocketException catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: Cannot reach server';
        _response = 'Error: ${e.message}\n\nPlease check:\n'
            '1. Your FastAPI server is running\n'
            '2. The IP address is correct (${ApiService.baseUrl})\n'
            '3. Your phone and computer are on the same network';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error occurred';
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Current API URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(ApiService.baseUrl),
            const SizedBox(height: 10),
            Text(
              'Status: $_connectionStatus',
              style: TextStyle(
                color: _connectionStatus.contains('Connected')
                    ? Colors.green
                    : _connectionStatus.contains('Error')
                        ? Colors.red
                        : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Connection'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_response),
            ),
          ],
        ),
      ),
    );
  }
} 