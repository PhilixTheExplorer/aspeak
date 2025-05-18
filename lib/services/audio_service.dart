import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:aspeak/core/env/environment.dart';

class AudioService {
  final String baseUrl = Environment.apiBaseUrl;

  // Get available options
  Future<Map<String, List<String>>> getAvailableOptions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/available-options/'));
      if (response.statusCode == 200) {
        return Map<String, List<String>>.from(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(response.body as Map),
          ),
        );
      } else {
        throw Exception('Failed to get available options');
      }
    } catch (e) {
      throw Exception('Failed to get available options: $e');
    }
  }

  // Process audio file
  Future<File> processAudio({
    required File audioFile,
    required String gender,
    required String language,
  }) async {
    try {
      print('Starting audio processing...');
      print('Audio file path: ${audioFile.path}');
      print('Gender: $gender');
      print('Language: $language');

      // Verify file exists and is readable
      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist at path: ${audioFile.path}');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process-audio/'),
      );

      print('Created multipart request');

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      // Add form fields
      request.fields['gender'] = gender;
      request.fields['language'] = language;

      print('Sending request to server...');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Received response from server');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Save the response to a temporary file
        final tempDir = Directory.systemTemp;
        final outputFile = File(
          path.join(
            tempDir.path,
            'processed_${path.basename(audioFile.path)}',
          ),
        );

        print('Saving processed audio to: ${outputFile.path}');
        await outputFile.writeAsBytes(response.bodyBytes);

        if (await outputFile.exists()) {
          print('Successfully saved processed audio file');
          return outputFile;
        } else {
          throw Exception('Failed to save processed audio file');
        }
      } else {
        throw Exception('Server returned error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error processing audio: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to process audio: $e');
    }
  }
}