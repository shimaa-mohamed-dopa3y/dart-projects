import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/api_service.dart';
import '../../data/models/user_model.dart';
import '../../core/providers/providers.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientDetailsScreen> createState() =>
      _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen>
    with TickerProviderStateMixin {
  String? _selectedStatus;
  bool _isSavingStatus = false;
  late PatientModel _currentPatient;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudioId;
  bool _isPlayingAudio = false;
  Map<String, Uint8List> _imageCache = {};
  bool _isLoadingAudio = false;
  String? _audioError;

  // Enhanced audio controls
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isSeeking = false;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  // UI enhancements
  late TabController _tabController;
  bool _showPersistentPlayer = false;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _selectedStatus = _currentPatient.patientStatus ?? 'stable';

    // Initialize animations
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Setup audio player listeners
    _setupAudioListeners();

    // Preload images for better UX
    for (final record in _currentPatient.records) {
      if (record.imageUrl != null) {
        _loadImage(_extractFileId(record.imageUrl!));
      }
    }

    // Refresh patient data to get latest records
    _refreshPatientData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _audioDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (!_isSeeking) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlayingAudio = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _audioPosition = Duration.zero;
          _currentlyPlayingAudioId = null;
          _showPersistentPlayer = false;
        }
      });
    });
  }

  Future<void> _playAudio(PatientRecord record) async {
    if (_isPlayingAudio) {
      await _stopAudio();
    }

    try {
      setState(() {
        _isLoadingAudio = true;
        _audioError = null;
        _showPersistentPlayer = true;
      });

      Uint8List audioBytes;

      // Check if we have audio data directly in the record
      if (record.audioData != null) {
        audioBytes = record.audioData!;
        print('🎵 Using audio data from record');
      } else if (record.audioUrl != null) {
        // Fallback to fetching from URL if no direct data
        print('🎵 Fetching audio from URL: ${record.audioUrl}');

        // Debug: Check what tokens we have available
        print('🔍 Patient token available: ${_currentPatient.token != null}');
        print(
          '🔍 Patient token: ${_currentPatient.token?.substring(0, 20)}...',
        );

        // Get current user's token as fallback
        final currentUser = ref.read(currentUserProvider);
        final currentUserToken = ref.read(apiServiceProvider).token;
        print('🔍 Current user token available: ${currentUserToken != null}');
        print(
          '🔍 Current user token: ${currentUserToken?.substring(0, 20)}...',
        );

        // Use patient token if available, otherwise use current user token
        final tokenToUse = _currentPatient.token ?? currentUserToken;
        print('🔑 Using token for audio: ${tokenToUse?.substring(0, 20)}...');

        audioBytes = await ref
            .read(apiServiceProvider)
            .displayAudio(record.audioUrl!, patientToken: tokenToUse);
      } else {
        throw Exception('No audio data available');
      }

      // Save audio to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_audio_${record.id}.mp3');
      await tempFile.writeAsBytes(audioBytes);

      // Play the audio
      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      setState(() {
        _isPlayingAudio = true;
        _currentlyPlayingAudioId = record.id;
        _isLoadingAudio = false;
      });

      // Start pulse animation
      _pulseAnimationController.repeat(reverse: true);

      print('✅ Audio playback started for record: ${record.id}');
    } catch (e) {
      print('❌ Error playing audio: $e');
      setState(() {
        _isLoadingAudio = false;
        _audioError = 'Failed to play audio: ${e.toString()}';
        _showPersistentPlayer = false;
      });
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    _pulseAnimationController.stop();
    _pulseAnimationController.reset();
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.resume();
    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _seekAudio(Duration position) async {
    setState(() {
      _isSeeking = true;
    });
    await _audioPlayer.seek(position);
    setState(() {
      _isSeeking = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentPatient.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: AppColors.primary),
            onPressed: _refreshPatientData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient Status Section
          _buildPatientStatusSection(),

          // Tab Bar
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primary.withOpacity(0.8),
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.document_text, size: 16),
                      SizedBox(width: 8),
                      Text('Records'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.gallery, size: 16),
                      SizedBox(width: 8),
                      Text('Photos'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRecordsTab(), _buildPhotosTab()],
            ),
          ),

          // Persistent Audio Player
          if (_showPersistentPlayer) _buildPersistentAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildPatientStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Status',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(Iconsax.arrow_down_1, color: AppColors.subtitle),
                    selectedItemBuilder: (context) {
                      return ['stable', 'improving', 'needs attention'].map((
                        String value,
                      ) {
                        return Text(
                          value.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items:
                        ['stable', 'improving', 'needs attention'].map((
                          status,
                        ) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSavingStatus ? null : _savePatientStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child:
                        _isSavingStatus
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (_currentPatient.records.isEmpty) {
      return _buildEmptyState(
        'No Records Yet',
        'Patient records will appear here',
      );
    }

    final groupedRecords = _groupRecordsByDate(_currentPatient.records);
    return _buildRecordsList(groupedRecords);
  }

  Widget _buildPhotosTab() {
    final photoRecords =
        _currentPatient.records
            .where((record) => record.imageUrl != null)
            .toList();

    if (photoRecords.isEmpty) {
      return _buildEmptyState(
        'No Photos Yet',
        'Patient photos will appear here',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: photoRecords.length,
      itemBuilder: (context, index) {
        final record = photoRecords[index];
        return _buildPhotoCard(record);
      },
    );
  }

  Widget _buildPhotoCard(PatientRecord record) {
    final imageId = _extractFileId(record.imageUrl!);

    return GestureDetector(
      onTap: () => _showPhotoDialog(record.imageUrl!),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              _imageCache.containsKey(imageId)
                  ? Image.memory(
                    _imageCache[imageId]!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPhotoPlaceholder();
                    },
                  )
                  : FutureBuilder(
                    future: _loadImage(imageId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildPhotoPlaceholder();
                    },
                  ),

              // Emotion badge
              if (record.hasEmotionAnalysis)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          record.faceDetected
                              ? AppColors.primary.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.emotionDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Time overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    record.formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentAudioPlayer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Slider(
            value:
                _audioDuration.inMilliseconds > 0
                    ? _audioPosition.inMilliseconds.toDouble()
                    : 0.0,
            max: _audioDuration.inMilliseconds.toDouble(),
            onChanged: (value) {
              _seekAudio(Duration(milliseconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),

          // Time and controls
          Row(
            children: [
              Text(
                _formatDuration(_audioPosition),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_isPlayingAudio) {
                    _pauseAudio();
                  } else {
                    _resumeAudio();
                  }
                },
                icon: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isPlayingAudio ? _pulseAnimation.value : 1.0,
                      child: Icon(
                        _isPlayingAudio ? Iconsax.pause : Iconsax.play,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(_audioDuration),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Stop button
          TextButton(
            onPressed: () {
              _stopAudio();
              setState(() {
                _showPersistentPlayer = false;
              });
            },
            child: Text(
              'Stop',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.document, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Map<String, List<PatientRecord>> _groupRecordsByDate(
    List<PatientRecord> records,
  ) {
    final grouped = <String, List<PatientRecord>>{};

    for (final record in records) {
      final date = record.formattedDate;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(record);
    }

    return grouped;
  }

  Widget _buildRecordsList(Map<String, List<PatientRecord>> groupedRecords) {
    final dates =
        groupedRecords.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Sort dates newest first

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final records = groupedRecords[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            ...records.map((record) => _buildRecordCard(record)),
            if (index < dates.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(PatientRecord record) {
    final audioId = record.id;
    final isPlaying = _isPlayingAudio && _currentlyPlayingAudioId == audioId;
    final isLoading = _isLoadingAudio && _currentlyPlayingAudioId == audioId;

    return GestureDetector(
      onTap: () {
        if (record.audioUrl != null || record.audioData != null) {
          if (isPlaying) {
            _stopAudio();
          } else {
            _playAudio(record);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isPlaying
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isPlaying
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.clock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    record.formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Play/Loading/Pause button
            if (record.audioUrl != null || record.audioData != null)
              isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(
                    isPlaying ? Iconsax.pause_circle : Iconsax.play_circle,
                    color: AppColors.primary,
                    size: 32,
                  ),

            const SizedBox(width: 8),

            // Emotion
            if (record.hasEmotionAnalysis)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      record.faceDetected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.emotionDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        record.faceDetected
                            ? AppColors.primary
                            : Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.camera, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          'Photo',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _savePatientStatus() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isSavingStatus = true;
    });

    try {
      await ref
          .read(apiServiceProvider)
          .updatePatientStatus(widget.patient.id, _selectedStatus!);

      // Refresh patient list and current patient data
      ref.invalidate(patientsProvider);
      _refreshPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingStatus = false;
        });
      }
    }
  }

  Future<void> _showPhotoDialog(String imageUrl) async {
    try {
      // Extract file ID from URL if it's a full URL
      String fileId = imageUrl;
      if (imageUrl.contains('/')) {
        fileId = imageUrl.split('/').last.split('?').first;
      }

      // Find the corresponding record to get emotion analysis
      PatientRecord? imageRecord;
      for (final record in _currentPatient.records) {
        if (record.imageUrl == imageUrl || record.id == fileId) {
          imageRecord = record;
          break;
        }
      }

      // Get the API service
      final apiService = ref.read(apiServiceProvider);

      // Use patient token if available, otherwise use current user token
      final tokenToUse = _currentPatient.token ?? apiService.token;
      print(
        '🔑 Using token for photo dialog: ${tokenToUse?.substring(0, 20)}...',
      );

      // Fetch image data
      final imageData = await apiService.displayImage(
        fileId,
        patientToken: tokenToUse,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.camera,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient Image',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                if (imageRecord != null)
                                  Text(
                                    imageRecord.formattedDate +
                                        ' at ' +
                                        imageRecord.formattedTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),

                    // Image
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageData,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Emotion Analysis Section
                    if (imageRecord != null && imageRecord.hasEmotionAnalysis)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              imageRecord.faceDetected
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                imageRecord.faceDetected
                                    ? AppColors.primary.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.scan,
                                  color:
                                      imageRecord.faceDetected
                                          ? AppColors.primary
                                          : Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Emotion Analysis',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        imageRecord.faceDetected
                                            ? AppColors.primary
                                            : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    imageRecord.faceDetected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                imageRecord.emotionDisplay,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      imageRecord.faceDetected
                                          ? AppColors.primary
                                          : Colors.orange.shade700,
                                ),
                              ),
                            ),

                            // Additional AI analysis details if available
                            if (imageRecord.aiAnalysis != null &&
                                imageRecord.aiAnalysis!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Analysis Details:',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...imageRecord.aiAnalysis!.entries
                                        .where(
                                          (entry) =>
                                              entry.key != 'emotion_analysis',
                                        )
                                        .map(
                                          (entry) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            child: Text(
                                              '• ${entry.key}: ${entry.value}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      print('❌ Error showing photo dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _extractFileId(String url) {
    // If it's already just an ID (no slashes or dots), return as is
    if (!url.contains('/') && !url.contains('.')) {
      return url;
    }

    // If it's a full URL, extract the file ID from the path
    // Expected format: /api/images/{fileId}?fileType=image
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    }

    // If we can't parse it, return the original string
    return url;
  }

  Future<void> _loadImage(String imageId) async {
    if (_imageCache.containsKey(imageId)) {
      return;
    }

    try {
      final apiService = ref.read(apiServiceProvider);

      // Use patient token if available, otherwise use current user token
      final tokenToUse = _currentPatient.token ?? apiService.token;
      print('🔑 Using token for image: ${tokenToUse?.substring(0, 20)}...');

      final imageData = await apiService.displayImage(
        imageId,
        patientToken: tokenToUse,
      );
      if (mounted) {
        setState(() {
          _imageCache[imageId] = imageData;
        });
      }
    } catch (e) {
      print('Failed to load image $imageId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();
      setState(() {
        _isPlayingAudio = false;
        _currentlyPlayingAudioId = null;
        _audioPosition = Duration.zero;
      });
    }
  }

  Future<void> _refreshPatientData() async {
    try {
      print('🔄 Refreshing patient data for: ${_currentPatient.name}');
      final apiService = ref.read(apiServiceProvider);

      // We get the raw map from the API service
      final patientData = await apiService.getPatientDetails(widget.patient.id);

      List<PatientRecord> records = [];

      // Manual parsing of records - fixed audio URL handling
      if (patientData['audiosGroupedPerDay'] is Map) {
        final audiosByDay =
            patientData['audiosGroupedPerDay'] as Map<String, dynamic>;
        audiosByDay.forEach((date, audioList) {
          if (audioList is List) {
            for (var audioData in audioList) {
              if (audioData is Map<String, dynamic>) {
                print('📄 Processing audio record: ${audioData['_id']}');
                print('📄 Audio filepath: ${audioData['filepath']}');

                // Extract emotion analysis from ai_analysis field
                String? emotionAnalysis;
                if (audioData.containsKey('ai_analysis') &&
                    audioData['ai_analysis'] != null) {
                  final aiAnalysis = audioData['ai_analysis'];
                  emotionAnalysis = aiAnalysis['emotion_analysis']?.toString();
                  print('📄 Audio emotion analysis: $emotionAnalysis');
                }

                records.add(
                  PatientRecord.fromJson({
                    '_id': audioData['_id'],
                    'audioUrl':
                        audioData['_id'], // Use the ID for the audioUrl - API expects ID
                    'timestamp': audioData['uploadedAt'],
                    'emotion':
                        emotionAnalysis ??
                        audioData['emotion'], // Use AI analysis or fallback
                    'ai_analysis':
                        audioData['ai_analysis'], // Pass through the full AI analysis
                  }),
                );
              }
            }
          }
        });
      }

      if (patientData['imagesGroupedPerDay'] is Map) {
        final imagesByDay =
            patientData['imagesGroupedPerDay'] as Map<String, dynamic>;
        imagesByDay.forEach((date, imageList) {
          if (imageList is List) {
            for (var imageData in imageList) {
              if (imageData is Map<String, dynamic>) {
                print('📄 Processing image record: ${imageData['_id']}');
                print('📄 Image filepath: ${imageData['filepath']}');

                // Extract emotion analysis from ai_analysis field
                String? emotionAnalysis;
                if (imageData.containsKey('ai_analysis') &&
                    imageData['ai_analysis'] != null) {
                  final aiAnalysis = imageData['ai_analysis'];
                  emotionAnalysis = aiAnalysis['emotion_analysis']?.toString();
                  print('📄 Image emotion analysis: $emotionAnalysis');
                  print('📄 Full AI analysis: ${imageData['ai_analysis']}');
                }

                records.add(
                  PatientRecord.fromJson({
                    '_id': imageData['_id'],
                    'imageUrl':
                        imageData['_id'], // Use the ID for consistency with API
                    'timestamp': imageData['uploadedAt'],
                    'emotion':
                        emotionAnalysis ??
                        imageData['emotion'], // Use AI analysis or fallback
                    'ai_analysis':
                        imageData['ai_analysis'], // Pass through the full AI analysis
                  }),
                );
              }
            }
          }
        });
      }

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ Patient data refreshed. Total records: ${records.length}');
      // Log audio records specifically
      final audioRecords = records.where((r) => r.audioUrl != null).toList();
      print('🎵 Audio records found: ${audioRecords.length}');
      for (var audioRecord in audioRecords) {
        print(
          '🎵 Audio record: ${audioRecord.id} - URL: ${audioRecord.audioUrl}',
        );
      }

      // Log image records with emotion analysis
      final imageRecords = records.where((r) => r.imageUrl != null).toList();
      print('🖼️ Image records found: ${imageRecords.length}');
      for (var imageRecord in imageRecords) {
        print(
          '🖼️ Image record: ${imageRecord.id} - Emotion: ${imageRecord.emotion}',
        );
      }

      setState(() {
        _currentPatient = _currentPatient.copyWith(
          records: records,
          patientStatus:
              patientData['patientStatus'] ?? _currentPatient.patientStatus,
          token: patientData['token'] ?? _currentPatient.token,
        );
        _selectedStatus = _currentPatient.patientStatus;
      });
    } catch (e) {
      print('❌ Error refreshing patient data: $e');
    }
  }
}
