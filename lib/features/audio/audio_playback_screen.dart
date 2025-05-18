import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class AudioPlaybackScreen extends StatefulWidget {
  final File processedAudioFile;
  final File? originalAudioFile;

  const AudioPlaybackScreen({
    super.key,
    required this.processedAudioFile,
    this.originalAudioFile,
  });

  @override
  State<AudioPlaybackScreen> createState() => _AudioPlaybackScreenState();
}

class _AudioPlaybackScreenState extends State<AudioPlaybackScreen> {
  final AudioPlayer _ownRecordingPlayer = AudioPlayer();
  final AudioPlayer _convertedRecordingPlayer = AudioPlayer();

  bool _isOwnRecordingPlaying = false;
  bool _isConvertedRecordingPlaying = false;

  Duration _ownRecordingDuration = Duration.zero;
  Duration _ownRecordingPosition = Duration.zero;
  Duration _convertedRecordingDuration = Duration.zero;
  Duration _convertedRecordingPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    // Setup listeners for both players
    _ownRecordingPlayer.playerStateStream.listen((state) {
      setState(() {
        _isOwnRecordingPlaying = state.playing;
      });
    });

    _convertedRecordingPlayer.playerStateStream.listen((state) {
      setState(() {
        _isConvertedRecordingPlaying = state.playing;
      });
    });

    // Position and duration listeners for own recording
    _ownRecordingPlayer.positionStream.listen((position) {
      setState(() {
        _ownRecordingPosition = position;
      });
    });

    _ownRecordingPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _ownRecordingDuration = duration;
        });
      }
    });

    // Position and duration listeners for converted recording
    _convertedRecordingPlayer.positionStream.listen((position) {
      setState(() {
        _convertedRecordingPosition = position;
      });
    });

    _convertedRecordingPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _convertedRecordingDuration = duration;
        });
      }
    });

    try {
      // Load the original recording if available
      if (widget.originalAudioFile != null) {
        await _ownRecordingPlayer.setFilePath(widget.originalAudioFile!.path);
      }

      // Load the processed audio file
      await _convertedRecordingPlayer.setFilePath(widget.processedAudioFile.path);
    } catch (e) {
      print('Error loading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audio files: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _ownRecordingPlayer.dispose();
    _convertedRecordingPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Playback")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Own Recording Player
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.spatial_audio_off),
                        SizedBox(width: 8),
                        Text(
                          "Original Voice",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _ownRecordingPosition.inSeconds.toDouble(),
                      min: 0,
                      max:
                          _ownRecordingDuration.inSeconds.toDouble() > 0
                              ? _ownRecordingDuration.inSeconds.toDouble()
                              : 1.0,
                      onChanged: (value) {
                        _ownRecordingPlayer.seek(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_ownRecordingPosition)),
                          Text(_formatDuration(_ownRecordingDuration)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.replay_10),
                          onPressed: () {
                            _ownRecordingPlayer.seek(
                              _ownRecordingPosition -
                                  const Duration(seconds: 10),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isOwnRecordingPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                          ),
                          iconSize: 48,
                          onPressed: () {
                            if (_isOwnRecordingPlaying) {
                              _ownRecordingPlayer.pause();
                            } else {
                              _ownRecordingPlayer.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.forward_10),
                          onPressed: () {
                            _ownRecordingPlayer.seek(
                              _ownRecordingPosition +
                                  const Duration(seconds: 10),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Converted Recording Player
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.multitrack_audio),
                        SizedBox(width: 8),
                        Text(
                          "Converted Voice",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _convertedRecordingPosition.inSeconds.toDouble(),
                      min: 0,
                      max:
                          _convertedRecordingDuration.inSeconds.toDouble() > 0
                              ? _convertedRecordingDuration.inSeconds.toDouble()
                              : 1.0,
                      onChanged: (value) {
                        _convertedRecordingPlayer.seek(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_convertedRecordingPosition)),
                          Text(_formatDuration(_convertedRecordingDuration)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.replay_10),
                          onPressed: () {
                            _convertedRecordingPlayer.seek(
                              _convertedRecordingPosition -
                                  const Duration(seconds: 10),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isConvertedRecordingPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                          ),
                          iconSize: 48,
                          onPressed: () {
                            if (_isConvertedRecordingPlaying) {
                              _convertedRecordingPlayer.pause();
                            } else {
                              _convertedRecordingPlayer.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.forward_10),
                          onPressed: () {
                            _convertedRecordingPlayer.seek(
                              _convertedRecordingPosition +
                                  const Duration(seconds: 10),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
