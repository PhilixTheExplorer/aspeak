import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiExampleScreen extends StatefulWidget {
  const ApiExampleScreen({super.key});

  @override
  State<ApiExampleScreen> createState() => _ApiExampleScreenState();
}

class _ApiExampleScreenState extends State<ApiExampleScreen> {
  final ApiService _apiService = ApiService();
  String _response = 'No data yet';

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.get('/your-endpoint');
      setState(() {
        _response = data.toString();
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  Future<void> _sendData() async {
    try {
      final data = await _apiService.post('/your-endpoint', {
        'key': 'value',
        // Add your data here
      });
      setState(() {
        _response = data.toString();
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_response),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('GET Request'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendData,
              child: const Text('POST Request'),
            ),
          ],
        ),
      ),
    );
  }
} 