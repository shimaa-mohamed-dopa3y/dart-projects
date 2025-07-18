class AudioModel {
  final String id;
  final String filename;
  final String originalName;
  final String mimetype;
  final int size;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioModel({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.mimetype,
    required this.size,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['_id'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? '',
      mimetype: json['mimetype'] ?? '',
      size: json['size'] ?? 0,
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'filename': filename,
      'originalName': originalName,
      'mimetype': mimetype,
      'size': size,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AudioModel(id: $id, filename: $filename, originalName: $originalName, size: $size)';
  }
}
