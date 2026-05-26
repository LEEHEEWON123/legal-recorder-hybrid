import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_recorder/services/hash_service.dart';

void main() {
  group('HashService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hash_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('동일한 파일에 대해 항상 같은 SHA-256 해시를 반환한다', () async {
      final file = File('${tempDir.path}/test.wav');
      await file.writeAsBytes([1, 2, 3, 4, 5]);

      final hash1 = await HashService.computeSha256(file.path);
      final hash2 = await HashService.computeSha256(file.path);

      expect(hash1, hash2);
      expect(hash1.length, 64); // SHA-256은 64자 hex
    });

    test('내용이 다른 파일은 다른 해시를 반환한다', () async {
      final file1 = File('${tempDir.path}/a.wav');
      final file2 = File('${tempDir.path}/b.wav');
      await file1.writeAsBytes([1, 2, 3]);
      await file2.writeAsBytes([4, 5, 6]);

      final hash1 = await HashService.computeSha256(file1.path);
      final hash2 = await HashService.computeSha256(file2.path);

      expect(hash1, isNot(equals(hash2)));
    });

    test('빈 파일의 SHA-256 해시는 알려진 값과 일치한다', () async {
      final file = File('${tempDir.path}/empty.wav');
      await file.writeAsBytes([]);

      final hash = await HashService.computeSha256(file.path);

      // 빈 데이터의 SHA-256 알려진 값
      expect(hash, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });
  });
}
