import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../services/audio_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  String? _selectedVoiceType;
  String _selectedLanguage = 'English';
  bool _isRecording = false;
  bool _isProcessing = false;
  File? _recordedFile;
  final AudioService _audioService = AudioService();
  String _statusMessage = '';
  late final AudioRecorder _audioRecorder;

  @override
  void initState() {
    super.initState();
    _selectedVoiceType = 'male';
    _audioRecorder = AudioRecorder();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    try {
      final health = await _audioService.checkHealth();
      setState(() {
        _statusMessage = 'Server status: ${health['status']}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Server error: $e';
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        // Configure recording settings
        final config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 128000,
        );
        
        await _audioRecorder.start(config, path: filePath);
        
        setState(() {
          _isRecording = true;
          _recordedFile = File(filePath);
          _statusMessage = 'Recording...';
        });
      } else {
        setState(() {
          _statusMessage = 'Permission to record audio was denied';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFile = File(path!);
        _statusMessage = 'Processing audio...';
        _isProcessing = true;
      });

      if (_recordedFile != null) {
        final processedFile = await _audioService.processAudio(
          audioFile: _recordedFile!,
          gender: _selectedVoiceType!,
          language: _selectedLanguage.toLowerCase(),
        );

        if (mounted) {
          context.push('/audio_playback', extra: {
            'processedAudioFile': processedFile,
            'originalAudioFile': _recordedFile,
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF64CCC5),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.menu))],
      ),
      backgroundColor: const Color(0xFF64CCC5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Hello User!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error')
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1E293B),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20),
                      // Waveform Visualizer Placeholder
                      Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black,
                        ),
                        child: const Center(
                          child: Text(
                            'Waveform Visualizer',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            GestureDetector(
                              onTap: _isRecording ? null : _startRecording,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording ? Colors.grey : Colors.black,
                                ),
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _isRecording ? _stopRecording : null,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording ? Colors.black : Colors.grey,
                                ),
                                child: Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bottom Section
            Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(context, 'Male', 'male'),
                    _buildFilterChip(context, 'Female', 'female'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                    color: const Color(0xFF1E293B),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: <String>['English', 'Thai'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      }
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF1E293B),
                    underline: Container(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedVoiceType == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: colorScheme.onPrimary,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _selectedVoiceType = value;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
