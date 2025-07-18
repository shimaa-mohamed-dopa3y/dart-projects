import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/audio_player_widget.dart';
import '../../core/widgets/image_display_widget.dart';
import '../../core/widgets/accessibility_widgets.dart';
import '../../data/services/api_service.dart';
import '../../data/models/audio_model.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientMediaGalleryScreen extends ConsumerStatefulWidget {
  const PatientMediaGalleryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientMediaGalleryScreen> createState() =>
      _PatientMediaGalleryScreenState();
}

class _PatientMediaGalleryScreenState
    extends ConsumerState<PatientMediaGalleryScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<AudioModel> _audioFiles = [];
  List<String> _imageIds = []; // You can expand this to include image metadata

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Load audio files and images
      // Note: You'll need to implement these methods in your API service
      // based on your backend endpoints
      await _loadAudioFiles();
      await _loadImages();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAudioFiles() async {
    try {
      // This is a placeholder - you'll need to implement the actual API call
      // based on your backend endpoints for fetching user's audio files
      print('🎵 Loading audio files...');

      // For now, we'll use a mock list - replace with actual API call
      // final response = await _apiService.getUserAudioFiles();
      // _audioFiles = (response['audioFiles'] as List)
      //     .map((json) => AudioModel.fromJson(json))
      //     .toList();

      // Mock data for testing
      _audioFiles = [
        AudioModel(
          id: '6851cf816927eebe7066ad5b',
          filename: 'recording_1750267090976.mp3',
          originalName: 'Voice Recording',
          mimetype: 'audio/mpeg',
          size: 1024000,
          userId: 'current_user_id',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
    } catch (e) {
      print('❌ Error loading audio files: $e');
      throw Exception('Failed to load audio files: $e');
    }
  }

  Future<void> _loadImages() async {
    try {
      // This is a placeholder - you'll need to implement the actual API call
      // based on your backend endpoints for fetching user's images
      print('🖼️ Loading images...');

      // For now, we'll use a mock list - replace with actual API call
      // final response = await _apiService.getUserImages();
      // _imageIds = (response['images'] as List)
      //     .map((json) => json['_id'] as String)
      //     .toList();

      // Mock data for testing
      _imageIds = [
        '6851cf816927eebe7066ad5b', // Replace with actual image IDs
      ];
    } catch (e) {
      print('❌ Error loading images: $e');
      throw Exception('Failed to load images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Media Gallery',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.text),
            onPressed: _loadMedia,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(icon: Icon(Icons.mic), text: 'Audio Files'),
            Tab(icon: Icon(Icons.image), text: 'Images'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.mainGradient),
        child: TabBarView(
          controller: _tabController,
          children: [_buildAudioTab(), _buildImagesTab()],
        ),
      ),
    );
  }

  Widget _buildAudioTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_audioFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mic_off,
        title: 'No Audio Files',
        message: 'You haven\'t recorded any audio files yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedia,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _audioFiles.length,
        itemBuilder: (context, index) {
          final audio = _audioFiles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: AudioPlayerWidget(
              audioId: audio.id,
              title: audio.originalName,
              height: 80,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagesTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_imageIds.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_not_supported,
        title: 'No Images',
        message: 'No images have been uploaded yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedia,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _imageIds.length,
        itemBuilder: (context, index) {
          final imageId = _imageIds[index];
          return ImageDisplayWidget(
            imageId: imageId,
            title: 'Image ${index + 1}',
            borderRadius: BorderRadius.circular(12),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading media...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load media',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMedia,
            style: AppTheme.primaryButtonStyle,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
 