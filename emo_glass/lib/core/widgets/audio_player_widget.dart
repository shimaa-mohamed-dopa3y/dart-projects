import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../data/services/api_service.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioId;
  final String? title;
  final bool showControls;
  final double height;
  final String? patientToken;
  final Function()? onError;

  const AudioPlayerWidget({
    Key? key,
    required this.audioId,
    this.title,
    this.showControls = true,
    this.height = 80,
    this.patientToken,
    this.onError,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _audioPlayer;
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isLoaded = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _audioPlayer = AudioPlayer();

      // Listen to player state changes
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      // Listen to duration changes
      _audioPlayer!.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to position changes
      _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen to completion
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize audio player: $e';
      });
      widget.onError?.call();
    }
  }

  Future<void> _loadAudio() async {
    try {
      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print('🎵 Loading audio with ID: ${widget.audioId}');

      // Download audio file from API
      final audioBytes = await _apiService.displayAudio(
        widget.audioId,
        patientToken: widget.patientToken,
      );

      // Validate file size
      if (audioBytes.length < 100) {
        throw Exception(
          'Audio file is too small (${audioBytes.length} bytes) - likely corrupted',
        );
      }

      // Save to temporary file with proper extension
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'audio_${widget.audioId}.wav'; // Use .wav extension since files are WAV
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(audioBytes);
      _localFilePath = file.path;

      print('🎵 Audio saved to: $_localFilePath');
      print('🎵 File size: ${audioBytes.length} bytes');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Auto-play after loading
        await _playAudio();
      }
    } catch (e) {
      print('❌ Error loading audio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      widget.onError?.call();
    }
  }

  Future<void> _playAudio() async {
    try {
      if (_localFilePath == null) {
        print('❌ No local file path available');
        return;
      }

      print('🎵 Playing audio from: $_localFilePath');

      // Check if file exists and has content
      final file = File(_localFilePath!);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize < 100) {
        throw Exception(
          'Audio file is too small ($fileSize bytes) - likely corrupted',
        );
      }

      // Create new audio player instance
      _audioPlayer = AudioPlayer();

      // Set up event listeners
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer!.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Play the audio with proper source
      await _audioPlayer!.play(DeviceFileSource(_localFilePath!));

      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('❌ Error playing audio: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to play audio: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer?.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('❌ Error pausing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer?.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  void _seekTo(Duration position) {
    _audioPlayer?.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and status
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? 'Audio Player',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: 8),

          // Controls and progress
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap:
                    _isLoading
                        ? null
                        : () {
                          if (_isPlaying) {
                            _pauseAudio();
                          } else {
                            if (_localFilePath == null) {
                              _loadAudio();
                            } else {
                              _playAudio();
                            }
                          }
                        },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        _isLoading
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_empty
                        : _isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Progress bar
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value:
                            _duration.inMilliseconds > 0
                                ? _position.inMilliseconds /
                                    _duration.inMilliseconds
                                : 0.0,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds:
                                (value * _duration.inMilliseconds).round(),
                          );
                          _seekTo(newPosition);
                        },
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),

                    // Time display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8),

              // Stop button
              GestureDetector(
                onTap: _isLoading ? null : _stopAudio,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.stop, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),

          // Error message
          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
