import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../services/audio_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:aspeak/features/auth/auth_view_model.dart';
import 'package:go_router/go_router.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String? _selectedVoiceType;
  String _selectedLanguage = 'English';
  bool _isRecording = false;
  bool _isProcessing = false;
  File? _recordedFile;
  final AudioService _audioService = AudioService();
  String _statusMessage = '';
  late final AudioRecorder _audioRecorder;
  List<double> _amplitudes = List.filled(40, 0.0);
  Timer? _amplitudeTimer;
  double _maxAmplitude = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedVoiceType = 'male';
    _audioRecorder = AudioRecorder();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  void _signOut(BuildContext context) async {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    await viewModel.signOut();
    context.go('/auth');
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

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
          _amplitudes = List.filled(40, 0.0);
          _maxAmplitude = 0.0;
        });

        // Start amplitude monitoring with higher frequency
        _amplitudeTimer =
            Timer.periodic(const Duration(milliseconds: 20), (timer) async {
          if (_isRecording) {
            final amplitude = await _audioRecorder.getAmplitude();
            // Update max amplitude for dynamic scaling
            _maxAmplitude =
                math.max(_maxAmplitude, amplitude.current.toDouble());

            // Calculate normalized amplitude with dynamic scaling
            final normalizedAmplitude =
                amplitude.current / (_maxAmplitude * 0.8);

            setState(() {
              _amplitudes.removeAt(0);
              _amplitudes.add(normalizedAmplitude.clamp(0.0, 1.0));
            });
          }
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
      _amplitudeTimer?.cancel();
      final path = await _audioRecorder.stop();
      final originalFile = File(path!);

      setState(() {
        _isRecording = false;
        _recordedFile = originalFile;
        _statusMessage = 'Processing audio...';
        _isProcessing = true;
        _amplitudes = List.filled(40, 0.0);
        _maxAmplitude = 0.0;
      });

      if (_recordedFile != null) {
        final processedFile = await _audioService.processAudio(
          audioFile: _recordedFile!,
          gender: _selectedVoiceType!,
          language: _selectedLanguage.toLowerCase(),
        );

        if (mounted) {
          // Reset state before navigation
          setState(() {
            _isProcessing = false;
            _statusMessage = '';
          });

          context.push('/audio_playback', extra: {
            'processedAudioFile': processedFile,
            'originalAudioFile': originalFile,
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildRecordingAnimation() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black,
      ),
      child: Center(
        child: _isRecording
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(_animation.value),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : const Text(
                'Press record to start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Get the currently logged in user from the AuthViewModel
    final authViewModel = Provider.of<AuthViewModel>(context);
    final String welcomeText = authViewModel.user?.email != null
        ? 'Hello ${authViewModel.user!.email.split('@')[0]}!'
        : 'Hello User!';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF64CCC5),
        actions: [
          IconButton(onPressed: () => _signOut(context), icon: Icon(Icons.logout))
        ],
      ),
      backgroundColor: const Color(0xFF64CCC5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              welcomeText,
              style: const TextStyle(
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
                      // Recording Animation
                      _buildRecordingAnimation(),
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
                                  color:
                                      _isRecording ? Colors.grey : Colors.black,
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
                                  color:
                                      _isRecording ? Colors.black : Colors.grey,
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
    _amplitudeTimer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    final barWidth = width / amplitudes.length;

    // Draw the waveform
    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth;
      final amplitude = amplitudes[i] * (height / 2);

      if (i == 0) {
        path.moveTo(x, centerY + amplitude);
      } else {
        path.lineTo(x, centerY + amplitude);
      }
    }

    // Draw the mirror waveform
    for (int i = amplitudes.length - 1; i >= 0; i--) {
      final x = i * barWidth;
      final amplitude = amplitudes[i] * (height / 2);
      path.lineTo(x, centerY - amplitude);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}
