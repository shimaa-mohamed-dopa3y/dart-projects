import 'dart:typed_data';

class PatientModel {
  final String id;
  final String name;
  final String email;
  final String serialNumber;
  final List<PatientRecord> records;
  final DateTime lastActivity;
  final String? specialist;
  final String? status; // Assignment status: active/inactive
  final String?
  patientStatus; // Health status: stable, improving, needs attention
  final String? token; // Patient's authentication token

  const PatientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.serialNumber,
    required this.records,
    required this.lastActivity,
    this.specialist,
    this.status,
    this.patientStatus,
    this.token,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    List<PatientRecord> records = [];

    // Handle audiosGroupedPerDay
    if (json.containsKey('audiosGroupedPerDay') &&
        json['audiosGroupedPerDay'] is Map) {
      final audiosByDay = json['audiosGroupedPerDay'] as Map<String, dynamic>;
      audiosByDay.forEach((date, audioList) {
        if (audioList is List) {
          for (var audioData in audioList) {
            records.add(
              PatientRecord.fromJson({
                '_id': audioData['_id'],
                'audioUrl': audioData['_id'], // Use the file ID for API calls
                'timestamp': audioData['uploadedAt'],
                'emotion': audioData['emotion'],
              }),
            );
          }
        }
      });
    }

    // Handle imagesGroupedPerDay
    if (json.containsKey('imagesGroupedPerDay') &&
        json['imagesGroupedPerDay'] is Map) {
      final imagesByDay = json['imagesGroupedPerDay'] as Map<String, dynamic>;
      imagesByDay.forEach((date, imageList) {
        if (imageList is List) {
          for (var imageData in imageList) {
            // Extract emotion analysis from ai_analysis field
            String? emotionAnalysis;
            if (imageData.containsKey('ai_analysis') &&
                imageData['ai_analysis'] != null) {
              final aiAnalysis = imageData['ai_analysis'];
              emotionAnalysis = aiAnalysis['emotion_analysis']?.toString();
            }

            records.add(
              PatientRecord.fromJson({
                '_id': imageData['_id'],
                'imageUrl': imageData['_id'], // Use the file ID for API calls
                'timestamp':
                    imageData['uploaded_at'] ??
                    imageData['uploadedAt'], // Handle both field names
                'emotion':
                    emotionAnalysis ??
                    imageData['emotion'], // Use AI analysis or fallback
                'ai_analysis':
                    imageData['ai_analysis'], // Pass through the full AI analysis
              }),
            );
          }
        }
      });
    }

    // Sort all records by timestamp descending
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return PatientModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString() ?? '',
      records: records,
      lastActivity: _parseDateTime(json['lastActivity']) ?? DateTime.now(),
      specialist: json['specialist']?.toString(),
      status: json['status']?.toString(), // Assignment status
      patientStatus: json['patientStatus']?.toString(), // Health status
      token: json['token']?.toString(), // Patient's authentication token
    );
  }

  PatientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? serialNumber,
    List<PatientRecord>? records,
    DateTime? lastActivity,
    String? specialist,
    String? status,
    String? patientStatus,
    String? token,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      serialNumber: serialNumber ?? this.serialNumber,
      records: records ?? this.records,
      lastActivity: lastActivity ?? this.lastActivity,
      specialist: specialist ?? this.specialist,
      status: status ?? this.status,
      patientStatus: patientStatus ?? this.patientStatus,
      token: token ?? this.token,
    );
  }

  static DateTime? _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      if (dateStr is String) {
        return DateTime.parse(dateStr);
      } else if (dateStr is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateStr);
      }
    } catch (e) {}
    return null;
  }

  int get totalRecords => records.length;
  int get todayRecords =>
      records
          .where((record) => _isSameDay(record.timestamp, DateTime.now()))
          .length;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class PatientRecord {
  final String id;
  final String? imageUrl;
  final String? audioUrl;
  final Uint8List? audioData;
  final String? emotion;
  final DateTime timestamp;
  final Map<String, dynamic>? aiAnalysis; // Full AI analysis data

  const PatientRecord({
    required this.id,
    this.imageUrl,
    this.audioUrl,
    this.audioData,
    this.emotion,
    required this.timestamp,
    this.aiAnalysis,
  });

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      audioData:
          json['audioData'] != null
              ? Uint8List.fromList(List<int>.from(json['audioData']))
              : null,
      emotion: json['emotion']?.toString(),
      timestamp: _parseDateTime(json['timestamp']) ?? DateTime.now(),
      aiAnalysis: json['ai_analysis'] as Map<String, dynamic>?,
    );
  }

  static DateTime _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      if (dateStr is String) {
        return DateTime.parse(dateStr);
      } else if (dateStr is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateStr);
      }
    } catch (e) {}
    return DateTime.now();
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthIndex = timestamp.month - 1;
    if (monthIndex < 0 || monthIndex >= months.length) {
      return '${timestamp.day} ??? ${timestamp.year}';
    }

    return '${timestamp.day} ${months[monthIndex]} ${timestamp.year}';
  }

  // Helper method to get emotion display text
  String get emotionDisplay {
    if (emotion == null || emotion!.isEmpty) {
      return 'Processing...';
    }

    if (emotion!.toLowerCase().contains('no face')) {
      return '👤 No Face Detected';
    }

    // Return the actual emotion with an emoji
    switch (emotion!.toLowerCase()) {
      case 'happy':
        return '😊 Happy';
      case 'sad':
        return '😢 Sad';
      case 'angry':
        return '😠 Angry';
      case 'fear':
        return '😨 Fear';
      case 'surprise':
        return '😲 Surprise';
      case 'disgust':
        return '🤢 Disgust';
      case 'neutral':
        return '😐 Neutral';
      default:
        return emotion!;
    }
  }

  // Helper method to check if emotion analysis is available
  bool get hasEmotionAnalysis => emotion != null && emotion!.isNotEmpty;

  // Helper method to check if face was detected
  bool get faceDetected =>
      emotion != null && !emotion!.toLowerCase().contains('no face');
}
