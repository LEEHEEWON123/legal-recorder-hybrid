import 'dart:convert';
import 'dart:io';
import '../models/recording.dart';

class RecordingStorageService {
  final String baseDir;

  RecordingStorageService({required this.baseDir});

  String get _indexPath => '$baseDir/recordings_index.json';

  Future<List<Recording>> loadAll() async {
    final indexFile = File(_indexPath);
    if (!await indexFile.exists()) return [];

    final content = await indexFile.readAsString();
    final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
    final recordings = jsonList
        .map((e) => Recording.fromJson(e as Map<String, dynamic>))
        .toList();

    recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recordings;
  }

  Future<void> saveMetadata(Recording recording) async {
    final all = await loadAll();
    final updated = [recording, ...all.where((r) => r.id != recording.id)];
    await _writeIndex(updated);
  }

  Future<void> delete(Recording recording) async {
    final wavFile = File(recording.filePath);
    if (await wavFile.exists()) await wavFile.delete();

    final all = await loadAll();
    final updated = all.where((r) => r.id != recording.id).toList();
    await _writeIndex(updated);
  }

  Future<void> _writeIndex(List<Recording> recordings) async {
    final indexFile = File(_indexPath);
    final json = jsonEncode(recordings.map((r) => r.toJson()).toList());
    await indexFile.writeAsString(json);
  }
}
