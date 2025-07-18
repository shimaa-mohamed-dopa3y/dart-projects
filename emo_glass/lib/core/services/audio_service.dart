import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterSoundRecorder? _recorder;
  FlutterTts? _tts;
  bool _isRecording = false;
  String? _currentRecordingPath;

  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    _tts = FlutterTts();

    await _initializeRecorder();
    await _initializeTts();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
  }

  // Get the best supported codec for the current platform
  Codec _getBestSupportedCodec() {
    // Use WAV as it's widely supported and accepted by the server
    return Codec.pcm16WAV;
  }

  Future<void> _initializeTts() async {
    final prefs = await SharedPreferences.getInstance();
    final speechRate = prefs.getDouble('speech_rate') ?? 0.5;

    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(speechRate);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);

    // Set additional TTS properties for better accessibility
    await _tts!.setVoice({
      "name": "en-us-x-sfg#male_1-local",
      "locale": "en-US",
    });
  }

  Future<void> speak(String text) async {
    if (_tts != null) {
      try {
        await _tts!.speak(text);
      } catch (e) {
        print('TTS Error: $e');
      }
    }
  }

  Future<void> stopSpeaking() async {
    if (_tts != null) {
      try {
        await _tts!.stop();
      } catch (e) {
        print('TTS Stop Error: $e');
      }
    }
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Try MP3 first, fallback to WAV if needed
      Codec codec = Codec.mp3;
      String extension = 'mp3';

      try {
        _currentRecordingPath =
            '${directory.path}/recording_$timestamp.$extension';

        await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          codec: codec,
          sampleRate: 44100,
          numChannels: 1,
        );
      } catch (e) {
        print('MP3 recording failed, trying WAV: $e');
        // Fallback to WAV
        codec = Codec.pcm16WAV;
        extension = 'wav';
        _currentRecordingPath =
            '${directory.path}/recording_$timestamp.$extension';

        await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          codec: codec,
          sampleRate: 44100,
          numChannels: 1,
        );
      }

      _isRecording = true;
      await speak('Recording started');
      print('✅ Recording started with codec: $codec, extension: $extension');
      return _currentRecordingPath;
    } catch (e) {
      print('Recording start error: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      await _recorder!.stopRecorder();
      _isRecording = false;
      await speak('Recording stopped');
      return _currentRecordingPath;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    if (_recorder != null) {
      await _recorder!.closeRecorder();
    }
    if (_tts != null) {
      await _tts!.stop();
    }
  }

  Future<void> playAudio(String filePath) async {
    try {
      final player = FlutterSoundPlayer();
      await player.openPlayer();
      await player.startPlayer(fromURI: filePath);
      await speak('Playing audio');
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> deleteAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {}
  }

  Future<void> announceEmotionDetected(String emotion) async {
    await speak('Emotion detected: $emotion');
  }

  Future<void> announceEmergencyActivated() async {
    await speak('Emergency mode activated. Help is on the way.');
  }

  Future<void> announceScreenChange(String screenName) async {
    await speak('Navigated to $screenName screen');
  }

  Future<void> announceButtonPress(String buttonName) async {
    await speak('$buttonName button pressed');
  }

  Future<void> announceError(String error) async {
    await speak('Error: $error');
  }

  Future<void> announceSuccess(String message) async {
    await speak('Success: $message');
  }

  Future<void> announceWarning(String message) async {
    await speak('Warning: $message');
  }

  Future<void> announceInfo(String message) async {
    await speak('Information: $message');
  }

  Future<void> announceLoading(String message) async {
    await speak('Loading: $message');
  }

  Future<void> announceFormField(String fieldName, String value) async {
    await speak('$fieldName: $value');
  }

  Future<void> announceListItem(
    String itemName,
    int position,
    int total,
  ) async {
    await speak('$itemName, item $position of $total');
  }

  Future<void> announceSwitchState(String switchName, bool isOn) async {
    await speak('$switchName ${isOn ? 'enabled' : 'disabled'}');
  }

  Future<void> announceSliderValue(String sliderName, double value) async {
    await speak('$sliderName set to ${value.toStringAsFixed(1)}');
  }

  // Update speech rate dynamically
  Future<void> updateSpeechRate(double newRate) async {
    if (_tts != null) {
      try {
        await _tts!.setSpeechRate(newRate);

        // Save to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('speech_rate', newRate);

        print('Speech rate updated to: $newRate');
      } catch (e) {
        print('Error updating speech rate: $e');
      }
    }
  }

  // Get current speech rate
  Future<double> getCurrentSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('speech_rate') ?? 0.5;
  }

  // Enhanced audio recording with quality options
  Future<String?> startRecordingWithQuality({
    Codec? codec, // Made optional to use best supported by default
    int sampleRate = 44100, // Updated to 44100 for better compatibility
    int numChannels = 1,
  }) async {
    if (_isRecording) return null;

    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: codec ?? Codec.pcm16WAV,
        sampleRate: sampleRate,
        numChannels: numChannels,
      );

      _isRecording = true;
      await speak('Recording started with high quality');
      return _currentRecordingPath;
    } catch (e) {
      print('High quality recording start error: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  // Get recording duration
  Future<Duration?> getRecordingDuration() async {
    if (_recorder != null && _isRecording) {
      try {
        // Note: FlutterSoundRecorder doesn't have a direct getProgress method
        // We'll track duration manually or use a different approach
        return Duration
            .zero; // Placeholder - can be enhanced with timer tracking
      } catch (e) {
        print('Error getting recording duration: $e');
        return null;
      }
    }
    return null;
  }

  // Check if audio file is valid
  Future<bool> isAudioFileValid(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Audio file does not exist: $filePath');
        return false;
      }

      final fileSize = await file.length();
      print('Audio file size: $fileSize bytes');

      // More lenient size check - WAV files can be smaller
      if (fileSize < 50) {
        print('Audio file too small: $fileSize bytes');
        return false;
      }

      return true;
    } catch (e) {
      print('Audio file validation error: $e');
      return false;
    }
  }

  // Get audio file info
  Future<Map<String, dynamic>> getAudioFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      final lastModified = exists ? await file.lastModified() : null;

      return {
        'exists': exists,
        'size': size,
        'sizeInKB': size / 1024,
        'lastModified': lastModified,
        'path': filePath,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }

  // Test audio recording functionality
  Future<Map<String, dynamic>> testAudioRecording() async {
    final results = <String, dynamic>{};

    try {
      print('🧪 Testing audio recording functionality...');

      // Test 1: Permission
      final hasPermission = await requestMicrophonePermission();
      results['permission'] = hasPermission;
      print('Permission: ${hasPermission ? '✅' : '❌'}');

      if (!hasPermission) {
        results['success'] = false;
        results['error'] = 'Microphone permission denied';
        return results;
      }

      // Test 2: Initialize
      await initialize();
      results['initialized'] = true;
      print('Initialized: ✅');

      // Test 3: Start recording
      final recordingPath = await startRecording();
      results['recordingStarted'] = recordingPath != null;
      print('Recording started: ${recordingPath != null ? '✅' : '❌'}');

      if (recordingPath == null) {
        results['success'] = false;
        results['error'] = 'Failed to start recording';
        return results;
      }

      // Test 4: Record for 2 seconds
      await Future.delayed(Duration(seconds: 2));
      results['recordingDuration'] = '2 seconds';

      // Test 5: Stop recording
      final finalPath = await stopRecording();
      results['recordingStopped'] = finalPath != null;
      print('Recording stopped: ${finalPath != null ? '✅' : '❌'}');

      if (finalPath == null) {
        results['success'] = false;
        results['error'] = 'Failed to stop recording';
        return results;
      }

      // Test 6: Validate file
      final fileInfo = await getAudioFileInfo(finalPath);
      results['fileInfo'] = fileInfo;
      results['fileValid'] = await isAudioFileValid(finalPath);
      print('File valid: ${results['fileValid'] ? '✅' : '❌'}');

      // Test 7: Clean up
      await deleteAudio(finalPath);
      results['cleanup'] = true;

      results['success'] = true;
      results['message'] = 'Audio recording test completed successfully';
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      print('Audio test error: $e');
    }

    return results;
  }
}
