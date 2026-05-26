import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class WhisperService {
  static const _modelUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin';

  final String? baseDir;

  WhisperService({this.baseDir});

  Future<String> get _modelDir async {
    if (baseDir != null) return '$baseDir/whisper';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/whisper';
  }

  String get modelPath {
    if (baseDir != null) return '$baseDir/whisper/ggml-small.bin';
    throw StateError('baseDir이 설정되지 않은 경우 modelPath는 비동기로 사용하세요.');
  }

  Future<String> get modelPathAsync async {
    final dir = await _modelDir;
    return '$dir/ggml-small.bin';
  }

  Future<bool> isModelReady() async {
    final path = await modelPathAsync;
    return File(path).exists();
  }

  /// 모델 다운로드. 진행률 0.0~1.0 스트림 반환.
  Stream<double> downloadModel() async* {
    final dir = await _modelDir;
    await Directory(dir).create(recursive: true);
    final path = '$dir/ggml-small.bin';

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(request);
      final total = response.contentLength ?? 0;
      int received = 0;

      final file = File(path).openWrite();
      await for (final chunk in response.stream) {
        file.add(chunk);
        received += chunk.length;
        if (total > 0) yield received / total;
      }
      await file.close();
    } finally {
      client.close();
    }
  }

  /// WAV 파일을 한국어 텍스트로 변환.
  Future<String> transcribe(String filePath) async {
    final dir = await _modelDir;
    final whisper = Whisper(
      model: WhisperModel.small,
      modelDir: dir,
    );
    final result = await whisper.transcribe(
      transcribeRequest: TranscribeRequest(
        audio: filePath,
        language: 'ko',
        isTranslate: false,
      ),
    );
    return result.text.trim();
  }
}
