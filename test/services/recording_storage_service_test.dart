import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_recorder/models/recording.dart';
import 'package:legal_recorder/services/recording_storage_service.dart';

void main() {
  group('RecordingStorageService', () {
    late Directory tempDir;
    late RecordingStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('storage_test_');
      service = RecordingStorageService(baseDir: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saveMetadata 후 loadAll이 저장된 Recording을 반환한다', () async {
      final recording = Recording(
        id: 'test-001',
        fileName: '음성 녹음 001',
        filePath: '${tempDir.path}/test.wav',
        createdAt: DateTime(2026, 5, 26),
        duration: const Duration(seconds: 60),
        sha256Hash: 'abc123',
      );

      await service.saveMetadata(recording);
      final all = await service.loadAll();

      expect(all.length, 1);
      expect(all.first.id, 'test-001');
      expect(all.first.sha256Hash, 'abc123');
    });

    test('delete 후 loadAll에서 해당 항목이 제거된다', () async {
      final recording = Recording(
        id: 'del-001',
        fileName: '삭제 테스트',
        filePath: '${tempDir.path}/del.wav',
        createdAt: DateTime(2026, 5, 26),
        duration: const Duration(seconds: 30),
        sha256Hash: 'hashvalue',
      );

      // 더미 wav 파일 생성
      await File(recording.filePath).writeAsBytes([]);
      await service.saveMetadata(recording);
      await service.delete(recording);
      final all = await service.loadAll();

      expect(all, isEmpty);
    });

    test('loadAll은 최신순(createdAt 내림차순)으로 반환한다', () async {
      final older = Recording(
        id: 'old',
        fileName: '오래된 녹음',
        filePath: '${tempDir.path}/old.wav',
        createdAt: DateTime(2026, 5, 20),
        duration: const Duration(seconds: 10),
        sha256Hash: 'hash1',
      );
      final newer = Recording(
        id: 'new',
        fileName: '최신 녹음',
        filePath: '${tempDir.path}/new.wav',
        createdAt: DateTime(2026, 5, 26),
        duration: const Duration(seconds: 10),
        sha256Hash: 'hash2',
      );

      await service.saveMetadata(older);
      await service.saveMetadata(newer);
      final all = await service.loadAll();

      expect(all.first.id, 'new');
      expect(all.last.id, 'old');
    });
  });
}
