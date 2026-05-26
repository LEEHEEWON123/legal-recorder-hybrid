import 'dart:io';
import 'package:crypto/crypto.dart';

class HashService {
  static Future<String> computeSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found for hashing', filePath);
    }
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
