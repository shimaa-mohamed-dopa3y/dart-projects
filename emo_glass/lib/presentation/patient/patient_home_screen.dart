import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';

import '../../core/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/widgets/accessibility_widgets.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'patient_settings_screen.dart';
import '../notification_center_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'doctor_browser_screen.dart';
import 'patient_profile_screen.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final _audioService = AudioService();
  FlutterTts? _flutterTts;
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;
  String? _recordingPath;
  bool _emotionDetectionEnabled = true;
  bool _isUploading = false;
  DateTime? _recordingStartTime;
  String? _lastEmotionResult;
  bool _isProcessingEmotion = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initRecorder();
    AccessibilityWidgets.announceScreenChange('Patient Home');

    // Check and update patient status if they have no assigned doctor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPatientStatus();
      _startEmotionDetectionPolling();
    });
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();

      // Configure TTS settings
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.8);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      // Set voice if available
      try {
        final voices = await _flutterTts!.getVoices;
        print('📢 Available TTS voices: $voices');

        // Try to set a preferred voice
        if (voices != null && voices.isNotEmpty) {
          final englishVoices =
              voices
                  .where(
                    (voice) =>
                        voice['locale']?.toString().startsWith('en') == true,
                  )
                  .toList();

          if (englishVoices.isNotEmpty) {
            await _flutterTts!.setVoice(englishVoices.first);
            print('📢 Set TTS voice: ${englishVoices.first}');
          }
        }
      } catch (e) {
        print('⚠️ Could not set TTS voice: $e');
      }

      // Test TTS initialization
      print('📢 TTS initialized successfully');
      await _flutterTts!.speak(
        'Welcome to your Emo Glasses home screen. You can start voice recording or toggle emotion detection.',
      );
    } catch (e) {
      print('❌ TTS initialization failed: $e');
      // Create a fallback TTS instance
      try {
        _flutterTts = FlutterTts();
        await _flutterTts!.setLanguage('en-US');
        print('📢 Fallback TTS created');
      } catch (fallbackError) {
        print('❌ Fallback TTS also failed: $fallbackError');
      }
    }
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      await _flutterTts!.speak(
        'Microphone permission is required for voice recording',
      );
      return;
    }

    await _recorder.openRecorder();
  }

  // Start polling for new emotion detection results
  void _startEmotionDetectionPolling() {
    if (_emotionDetectionEnabled) {
      // Poll every 5 seconds for new emotion results
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _emotionDetectionEnabled) {
          _checkForNewEmotionResults();
          _startEmotionDetectionPolling(); // Continue polling
        }
      });
    }
  }

  // Check for new emotion detection results from glasses
  Future<void> _checkForNewEmotionResults() async {
    if (!_emotionDetectionEnabled || _isProcessingEmotion) return;

    try {
      setState(() {
        _isProcessingEmotion = true;
      });

      final apiService = ref.read(apiServiceProvider);

      // Use the new endpoint: GET /api/patients/latest-emotion
      final emotionData = await apiService.getLatestEmotion();

      if (emotionData != null) {
        String? emotionAnalysis;

        // Try to extract emotion_analysis from different possible locations
        if (emotionData['emotion_analysis'] != null) {
          // Direct emotion_analysis field
          emotionAnalysis = emotionData['emotion_analysis'].toString();
        } else if (emotionData['image'] != null &&
            emotionData['image']['ai_analysis'] != null &&
            emotionData['image']['ai_analysis']['emotion_analysis'] != null) {
          // Nested in image.ai_analysis.emotion_analysis
          emotionAnalysis =
              emotionData['image']['ai_analysis']['emotion_analysis']
                  .toString();
        }

        print('🧠 Extracted emotion analysis: $emotionAnalysis');

        if (emotionAnalysis != null && emotionAnalysis.isNotEmpty) {
          // Always process the emotion - announce every second regardless if it's the same
          print('🧠 Announcing emotion: $emotionAnalysis');
          await _processEmotionResult(emotionAnalysis);
          _lastEmotionResult = emotionAnalysis;
        } else {
          print('🧠 No emotion analysis found in response');
        }
      } else {
        print('🧠 No emotion data received');
      }
    } catch (e) {
      print('Error checking emotion results: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingEmotion = false;
        });
      }
    }
  }

  // Process emotion result and convert to speech
  Future<void> _processEmotionResult(String emotionResult) async {
    try {
      print('🧠 Processing emotion result: $emotionResult');

      if (_flutterTts == null) {
        print('❌ TTS not initialized, attempting to reinitialize...');
        await _initTts();

        if (_flutterTts == null) {
          print('❌ TTS still not available after reinitializing');
          return;
        }
      }

      await AccessibilityWidgets.announceInfo('New emotion detected');

      // Convert emotion result to user-friendly text
      String emotionText = _convertEmotionToText(emotionResult);
      print('🧠 Converted emotion text: $emotionText');

      // Create different announcement based on emotion type
      String announcement;
      if (emotionResult.toLowerCase() == 'no face detected') {
        announcement =
            'I am $emotionText. Please ensure your glasses are positioned correctly.';
      } else {
        announcement =
            'Emotion detected: The person in your field of view appears to be $emotionText.';
      }

      print('📢 TTS announcement: $announcement');

      // Stop any current speech before starting new one
      await _flutterTts!.stop();

      // Wait a moment for stop to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Announce the emotion result with enhanced speech
      print('📢 Starting TTS speech...');
      final result = await _flutterTts!.speak(announcement);
      print('📢 TTS speak result: $result');

      // Also test a simple speak to ensure TTS is working
      if (result != 1) {
        print('⚠️ TTS speak may have failed, trying alternative...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts!.speak('Emotion detected: $emotionText');
      }

      // Also show a visual notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emotion detected: $emotionText'),
            backgroundColor:
                emotionResult.toLowerCase() == 'no face detected'
                    ? Colors.orange
                    : Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      print(
        '✅ Emotion result processed: $emotionText (original: $emotionResult)',
      );
    } catch (e) {
      print('❌ Error processing emotion result: $e');

      // Try a simple TTS test
      try {
        if (_flutterTts != null) {
          await _flutterTts!.speak('Emotion detection error');
        }
      } catch (ttsError) {
        print('❌ TTS error during fallback: $ttsError');
      }

      await AccessibilityWidgets.announceError(
        'Failed to process emotion result',
      );
    }
  }

  // Convert emotion to user-friendly text
  String _convertEmotionToText(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
      case 'excited':
        return 'happy and joyful';
      case 'sad':
      case 'sadness':
      case 'depressed':
        return 'sad or upset';
      case 'angry':
      case 'anger':
      case 'mad':
      case 'frustrated':
        return 'angry or frustrated';
      case 'surprised':
      case 'shock':
      case 'amazed':
        return 'surprised or amazed';
      case 'fear':
      case 'scared':
      case 'afraid':
        return 'fearful or scared';
      case 'disgust':
      case 'disgusted':
        return 'disgusted or displeased';
      case 'neutral':
      case 'calm':
        return 'calm and neutral';
      case 'no face detected':
        return 'unable to detect any face in the current view';
      default:
        return emotion.toLowerCase();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await AccessibilityWidgets.announceInfo('Starting voice recording');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/recording_$timestamp.aac';

      await _recorder.startRecorder(
        toFile: _recordingPath!,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
      });

      await AccessibilityWidgets.announceSuccess(
        'Recording started. Tap again to stop.',
      );
    } catch (e) {
      await AccessibilityWidgets.announceError('Failed to start recording');
      print('Recording error: $e');

      // Try alternative codec if the first one fails
      try {
        print('🔄 Trying alternative codec...');
        _recordingPath =
            '${(await getApplicationDocumentsDirectory()).path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.startRecorder(
          toFile: _recordingPath!,
          codec: Codec.pcm16WAV,
          sampleRate: 44100,
          numChannels: 1,
        );

        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
        });

        await AccessibilityWidgets.announceSuccess(
          'Recording started with alternative codec. Tap again to stop.',
        );
      } catch (e2) {
        print('❌ Alternative codec also failed: $e2');
        await AccessibilityWidgets.announceError('Recording failed completely');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      final recordingPath = await _recorder.stopRecorder();
      final recordingDuration =
          _recordingStartTime != null
              ? DateTime.now().difference(_recordingStartTime!).inSeconds
              : 0;

      _isRecording = false;
      _recordingStartTime = null;
      setState(() {});

      if (recordingPath != null) {
        print('🎵 Recording stopped. Duration: ${recordingDuration} seconds');

        // Check if recording was too short
        if (recordingDuration < 1) {
          await AccessibilityWidgets.announceError(
            'Recording too short. Please record for at least 1 second.',
          );
          print('❌ Recording too short: ${recordingDuration} seconds');
          return;
        }

        await AccessibilityWidgets.announceSuccess(
          'Recording saved and uploading',
        );
        print('Recording saved to: $recordingPath');

        // Always upload the recording
        await _uploadRecording(recordingPath);
      }
    }
  }

  Future<void> _uploadRecording(String recordingPath) async {
    if (!mounted) {
      print('❌ Widget not mounted, skipping upload');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final audioFile = File(recordingPath);

      // Verify file exists and has content
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found');
      }

      final fileSize = await audioFile.length();
      print('📤 File size: ${fileSize} bytes');

      if (fileSize < 1000) {
        print('❌ Audio file too small: ${fileSize} bytes');
        throw Exception(
          'Audio file too small (${fileSize} bytes) - likely corrupted or empty',
        );
      }

      print('📤 Uploading audio file: ${audioFile.path}');
      print('📤 File size: ${fileSize} bytes');

      // Pass the recording start time to ensure correct timestamp
      final recordingTime = _recordingStartTime ?? DateTime.now();
      print('📤 Recording started at: ${recordingTime.toIso8601String()}');

      final result = await apiService.uploadAudio(
        audioFile,
        recordingTime: recordingTime,
      );
      print('✅ Audio upload result: $result');

      // Check if upload was successful
      if (result['success'] == true || result['message'] != null) {
        await AccessibilityWidgets.announceSuccess(
          'Audio uploaded successfully to backend',
        );

        // Trigger data refresh so patient appears in specialist's records
        ref.invalidate(patientsProvider);

        // Also refresh the current user profile to get updated records
        ref.invalidate(authProvider);

        // Show success message to user
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Audio uploaded to healthcare provider'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } else {
        throw Exception('Upload response indicates failure');
      }
    } catch (e) {
      print('❌ Failed to upload audio: $e');
      await AccessibilityWidgets.announceError(
        'Failed to upload audio to backend',
      );

      // Show error message to user
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Upload failed: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _uploadRecording(recordingPath),
                ),
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _toggleEmotionDetection() async {
    setState(() {
      _emotionDetectionEnabled = !_emotionDetectionEnabled;
    });

    final status = _emotionDetectionEnabled ? 'enabled' : 'disabled';
    await _audioService.announceSwitchState(
      'Emotion detection',
      _emotionDetectionEnabled,
    );

    // Start or stop polling based on toggle state
    if (_emotionDetectionEnabled) {
      print('🧠 Starting emotion detection polling...');
      _startEmotionDetectionPolling();
    } else {
      print('🧠 Stopping emotion detection polling...');
      // Stop any current TTS speech when disabling
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
      // Reset processing state
      setState(() {
        _isProcessingEmotion = false;
      });
      await AccessibilityWidgets.announceInfo('Emotion detection stopped');
    }
  }

  Future<void> _handleEmergency() async {
    await AccessibilityWidgets.announceWarning(
      'Emergency mode activated. Calling for help.',
    );

    // Load emergency number from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final emergencyNumber = prefs.getString('emergency_number') ?? '911';

    final telUrl = 'tel:$emergencyNumber';
    if (await canLaunchUrl(Uri.parse(telUrl))) {
      await launchUrl(Uri.parse(telUrl));
    } else {
      await AccessibilityWidgets.announceError(
        'Could not call emergency number. Please dial manually.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AccessibilityWidgets.announceInfo('Logging out');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(fontSize: 16.sp, color: AppColors.text),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _audioService.announceButtonPress('Cancel logout');
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _audioService.announceButtonPress('Confirm logout');
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _checkPatientStatus() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.role == 'patient') {
      try {
        final hasAssignedDoctor =
            currentUser.assignedDoctor != null &&
            currentUser.assignedDoctor!.isNotEmpty;
        final currentStatus = currentUser.status?.toLowerCase();
        bool needsUpdate = false;
        String correctStatus = '';

        if (hasAssignedDoctor && currentStatus != 'active') {
          needsUpdate = true;
          correctStatus = 'active';
          print(
            'Patient has assigned doctor but status is $currentStatus - fixing to active',
          );
        } else if (!hasAssignedDoctor && currentStatus != 'inactive') {
          needsUpdate = true;
          correctStatus = 'inactive';
          print(
            'Patient has no assigned doctor but status is $currentStatus - fixing to inactive',
          );
        }

        if (needsUpdate) {
          await ref
              .read(patientStatusManagerProvider)
              .ensurePatientStatus(currentUser.id, currentUser.assignedDoctor);
          print(
            '✅ Patient status validated and fixed for: ${currentUser.name}',
          );
        } else {
          print('✅ Patient status is already correct for: ${currentUser.name}');
        }
      } catch (e) {
        print('Failed to check patient status: $e');
      }
    }
  }

  // Debug method to test audio upload and retrieval flow
  Future<void> _testAudioFlow() async {
    try {
      await AccessibilityWidgets.announceInfo('Testing audio upload flow');

      final apiService = ref.read(apiServiceProvider);
      final testResult = await apiService.testCompleteAudioFlow();

      if (testResult['success'] == true) {
        await AccessibilityWidgets.announceSuccess(
          'Audio flow test completed successfully',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Audio flow test passed: ${testResult['message']}',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception(testResult['error'] ?? 'Unknown error');
      }
    } catch (e) {
      await AccessibilityWidgets.announceError('Audio flow test failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Audio flow test failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          Semantics(
            label: 'Browse Doctors',
            button: true,
            child: IconButton(
              icon: Icon(Icons.people),
              tooltip: 'Browse Doctors',
              onPressed: () async {
                await _audioService.announceButtonPress('Browse Doctors');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorBrowserScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Notifications',
            button: true,
            child: IconButton(
              icon: Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: () async {
                await _audioService.announceButtonPress('Notifications');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationCenterScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Settings',
            button: true,
            child: IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () async {
                await _audioService.announceButtonPress('Settings');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientSettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Welcome back,',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    if (user?.name != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          user!.name,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Centered and styled Voice Recording section
                    Text(
                      'Voice Recording',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Semantics(
                      label:
                          _isRecording
                              ? 'Stop voice recording'
                              : 'Start voice recording',
                      button: true,
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          width: 200.r,
                          height: 200.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (_isRecording
                                      ? AppColors.error
                                      : AppColors.primary)
                                  .withOpacity(0.1),
                              width: 15.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 120.r,
                              height: 120.r,
                              decoration: BoxDecoration(
                                color:
                                    _isRecording
                                        ? AppColors.error.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color:
                                    _isRecording
                                        ? AppColors.error
                                        : AppColors.primary,
                                size: 60.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      _isRecording ? 'Recording...' : 'Tap to start recording',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Emotion Detection Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emotion Detection',
                                      style: GoogleFonts.inter(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _emotionDetectionEnabled
                                          ? 'Detection is active'
                                          : 'Detection is paused',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isProcessingEmotion)
                                SizedBox(
                                  width: 24.w,
                                  height: 24.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                Semantics(
                                  label:
                                      _emotionDetectionEnabled
                                          ? 'Disable emotion detection'
                                          : 'Enable emotion detection',
                                  toggled: _emotionDetectionEnabled,
                                  child: Switch(
                                    value: _emotionDetectionEnabled,
                                    onChanged:
                                        (value) => _toggleEmotionDetection(),
                                    activeColor: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_isUploading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Uploading...'),
                    ],

                    const SizedBox(height: 60),

                    Semantics(
                      label: 'Emergency button - Call for help',
                      button: true,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 40),
                        child: ElevatedButton(
                          onPressed: _handleEmergency,
                          style: AppTheme.emergencyButtonStyle,
                          child: Text(
                            'Emergency',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
