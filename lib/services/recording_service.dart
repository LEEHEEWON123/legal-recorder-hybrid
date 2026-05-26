import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recording.dart';
import 'hash_service.dart';
import 'recording_storage_service.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  late RecordingStorageService _storageService;
  DateTime? _startTime;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _storageService = RecordingStorageService(baseDir: dir.path);
    _initialized = true;
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    await _ensureInit();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/recording_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _startTime = DateTime.now();
  }

  Future<void> pauseRecording() async {
    await _recorder.pause();
  }

  Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  /// 녹음 정지 후 SHA-256 계산하여 Recording 저장. 저장된 Recording 반환.
  Future<Recording> stopAndSave({required String fileName}) async {
    await _ensureInit();
    final path = await _recorder.stop();
    if (path == null) throw StateError('녹음 파일 경로가 없습니다.');

    final startTime = _startTime ?? DateTime.now();
    final duration = DateTime.now().difference(startTime);
    final hash = await HashService.computeSha256(path);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final recording = Recording(
      id: id,
      fileName: fileName.isEmpty ? '음성 녹음 $id' : fileName,
      filePath: path,
      createdAt: startTime,
      duration: duration,
      sha256Hash: hash,
    );

    await _storageService.saveMetadata(recording);
    _startTime = null;
    return recording;
  }

  Future<bool> isRecording() async => await _recorder.isRecording();
  Future<bool> isPaused() async => await _recorder.isPaused();

  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  void dispose() {
    _recorder.dispose();
    _initialized = false;
  }
}
