import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_recorder/services/whisper_service.dart';

void main() {
  group('WhisperService', () {
    late Directory tempDir;
    late WhisperService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('whisper_test_');
      service = WhisperService(baseDir: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('모델 파일이 없으면 isModelReady가 false를 반환한다', () async {
      final result = await service.isModelReady();
      expect(result, false);
    });

    test('모델 파일이 있으면 isModelReady가 true를 반환한다', () async {
      final modelDir = Directory('${tempDir.path}/whisper');
      await modelDir.create(recursive: true);
      final modelFile = File('${tempDir.path}/whisper/ggml-small.bin');
      await modelFile.writeAsBytes([1, 2, 3]);

      final result = await service.isModelReady();
      expect(result, true);
    });

    test('modelPath가 올바른 경로를 반환한다', () {
      expect(
        service.modelPath,
        '${tempDir.path}/whisper/ggml-small.bin',
      );
    });
  });
}
