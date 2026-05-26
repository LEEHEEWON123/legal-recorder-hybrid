import 'package:flutter_test/flutter_test.dart';
import 'package:legal_recorder/models/recording.dart';

void main() {
  group('Recording', () {
    test('생성 시 모든 필드가 올바르게 설정된다', () {
      final now = DateTime(2026, 5, 26, 10, 0, 0);
      final recording = Recording(
        id: 'test-id-001',
        fileName: '음성 녹음 001',
        filePath: '/data/user/0/com.legalrecorder/files/recording_001.wav',
        createdAt: now,
        duration: const Duration(minutes: 5, seconds: 17),
        sha256Hash: 'abc123def456',
      );

      expect(recording.id, 'test-id-001');
      expect(recording.fileName, '음성 녹음 001');
      expect(recording.duration.inSeconds, 317);
      expect(recording.sha256Hash, 'abc123def456');
    });

    test('formattedDuration이 MM:SS 형식으로 반환된다', () {
      final recording = Recording(
        id: 'id',
        fileName: 'test',
        filePath: '/path/test.wav',
        createdAt: DateTime.now(),
        duration: const Duration(minutes: 5, seconds: 7),
        sha256Hash: 'hash',
      );

      expect(recording.formattedDuration, '05:07');
    });

    test('toJson/fromJson 왕복 변환이 동일한 데이터를 반환한다', () {
      final original = Recording(
        id: 'id-001',
        fileName: '녹음 파일',
        filePath: '/path/file.wav',
        createdAt: DateTime(2026, 5, 26),
        duration: const Duration(seconds: 90),
        sha256Hash: 'sha256hashvalue',
      );

      final json = original.toJson();
      final restored = Recording.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fileName, original.fileName);
      expect(restored.duration, original.duration);
      expect(restored.sha256Hash, original.sha256Hash);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
