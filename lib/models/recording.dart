class Recording {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final Duration duration;
  final String sha256Hash;

  const Recording({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.duration,
    required this.sha256Hash,
  });

  String get formattedDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'sha256Hash': sha256Hash,
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        filePath: json['filePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        duration: Duration(milliseconds: json['durationMs'] as int),
        sha256Hash: json['sha256Hash'] as String,
      );
}
