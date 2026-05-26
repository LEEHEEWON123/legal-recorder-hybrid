# Whisper STT 로컬 변환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 목록 화면 점 3개 메뉴에 "텍스트 변환" 항목을 추가하고, 탭 시 로컬 Whisper 모델로 WAV 파일을 한국어 텍스트로 변환해 다이얼로그에 표시한다.

**Architecture:** WhisperService가 모델 다운로드와 변환을 담당한다. TranscriptionDialog가 다운로드/변환/완료/오류 상태를 표시한다. RecordingListItem의 팝업 메뉴에서 트리거한다.

**Tech Stack:** Flutter (Android), whisper_flutter_new ^1.0.1, http (기존), path_provider (기존)

---

## 파일 구조

```
lib/
├── services/
│   └── whisper_service.dart         # 신규 — 모델 다운로드 + STT 변환
├── widgets/
│   ├── transcription_dialog.dart    # 신규 — 변환 상태 다이얼로그
│   └── recording_list_item.dart     # 수정 — onTranscribe 콜백 추가
└── screens/
    └── recording_list_screen.dart   # 수정 — _transcribeRecording 메서드 추가

test/
└── services/
    └── whisper_service_test.dart    # 신규 — isModelReady 테스트
```

---

## Task 1: 패키지 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml에 whisper_flutter_new 추가**

`pubspec.yaml`의 `dependencies` 섹션에 추가:

```yaml
dependencies:
  flutter:
    sdk: flutter
  record: ^6.2.1
  audioplayers: ^6.0.0
  path_provider: ^2.1.3
  share_plus: ^10.0.2
  crypto: ^3.0.3
  permission_handler: ^11.3.1
  intl: ^0.19.0
  http: ^1.2.0
  whisper_flutter_new: ^1.0.1
```

- [ ] **Step 2: 패키지 설치**

```bash
flutter pub get
```

Expected: `Got dependencies!` 출력, 오류 없음

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add whisper_flutter_new and http packages"
```

---

## Task 2: WhisperService 구현

**Files:**
- Create: `lib/services/whisper_service.dart`
- Create: `test/services/whisper_service_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/services/whisper_service_test.dart`:

```dart
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
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/services/whisper_service_test.dart
```

Expected: FAIL — `whisper_service.dart` 없음

- [ ] **Step 3: WhisperService 구현**

`lib/services/whisper_service.dart`:

```dart
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
    final path = await modelPathAsync;
    final whisper = Whisper(
      model: WhisperModel.custom,
      modelPath: path,
    );
    final result = await whisper.transcribe(
      transcribeRequest: TranscribeRequest(
        audio: filePath,
        lang: 'ko',
        isTranslate: false,
      ),
    );
    return result.text?.trim() ?? '';
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/services/whisper_service_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/whisper_service.dart test/services/whisper_service_test.dart
git commit -m "feat: add WhisperService with model download and transcription"
```

---

## Task 3: TranscriptionDialog 위젯 구현

**Files:**
- Create: `lib/widgets/transcription_dialog.dart`

- [ ] **Step 1: TranscriptionDialog 구현**

`lib/widgets/transcription_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/whisper_service.dart';

enum _State { downloading, transcribing, done, error }

class TranscriptionDialog extends StatefulWidget {
  final String filePath;
  final WhisperService whisperService;

  const TranscriptionDialog({
    super.key,
    required this.filePath,
    required this.whisperService,
  });

  @override
  State<TranscriptionDialog> createState() => _TranscriptionDialogState();
}

class _TranscriptionDialogState extends State<TranscriptionDialog> {
  _State _state = _State.transcribing;
  double _downloadProgress = 0;
  String _result = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final ready = await widget.whisperService.isModelReady();
      if (!ready) {
        setState(() => _state = _State.downloading);
        await for (final progress
            in widget.whisperService.downloadModel()) {
          setState(() => _downloadProgress = progress);
        }
      }

      setState(() => _state = _State.transcribing);
      final text =
          await widget.whisperService.transcribe(widget.filePath);
      setState(() {
        _state = _State.done;
        _result = text.isEmpty ? '(변환된 텍스트가 없습니다)' : text;
      });
    } catch (e) {
      setState(() {
        _state = _State.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: const Text('텍스트 변환'),
      content: _buildContent(),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _State.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('모델 다운로드 중...'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        );
      case _State.transcribing:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('변환 중...'),
          ],
        );
      case _State.done:
        return SingleChildScrollView(
          child: SelectableText(
            _result,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        );
      case _State.error:
        return Text(
          '오류: $_errorMessage',
          style: const TextStyle(color: Colors.redAccent),
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_state == _State.done) {
      return [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _result));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('클립보드에 복사되었습니다.')),
            );
          },
          child: const Text('복사'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ];
    }
    if (_state == _State.error) {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ];
    }
    return [];
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/transcription_dialog.dart
git commit -m "feat: add TranscriptionDialog widget"
```

---

## Task 4: RecordingListItem에 onTranscribe 추가

**Files:**
- Modify: `lib/widgets/recording_list_item.dart`

- [ ] **Step 1: onTranscribe 콜백 및 메뉴 항목 추가**

`lib/widgets/recording_list_item.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recording.dart';

class RecordingListItem extends StatelessWidget {
  final Recording recording;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onTranscribe;

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
    required this.onTap,
    required this.onTranscribe,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy. MM. dd. HH:mm').format(recording.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFF7B5EA7)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            Text(
              recording.formattedDuration,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: Color(0xFF888888), size: 20),
              color: const Color(0xFF2A2A2A),
              onSelected: (value) {
                if (value == 'transcribe') onTranscribe();
                if (value == 'share') onShare();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'transcribe',
                  child: Text('텍스트 변환'),
                ),
                const PopupMenuItem(value: 'share', child: Text('공유')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 전체 테스트 실행**

```bash
flutter test
```

Expected: All tests PASS (RecordingListItem 테스트는 onTranscribe 추가로 컴파일 오류 → 다음 Step에서 수정)

- [ ] **Step 3: recording_list_item_test.dart 업데이트**

`test/widgets/recording_list_item_test.dart`에서 `RecordingListItem` 생성 부분에 `onTranscribe` 추가:

```dart
RecordingListItem(
  recording: recording,
  isPlaying: false,
  onPlay: () {},
  onShare: () {},
  onDelete: () {},
  onTap: () {},
  onTranscribe: () {},
)
```

- [ ] **Step 4: 전체 테스트 실행 → 통과 확인**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/recording_list_item.dart test/widgets/recording_list_item_test.dart
git commit -m "feat: add onTranscribe callback and menu item to RecordingListItem"
```

---

## Task 5: RecordingListScreen에 변환 연결

**Files:**
- Modify: `lib/screens/recording_list_screen.dart`

- [ ] **Step 1: WhisperService 및 TranscriptionDialog import 추가**

`lib/screens/recording_list_screen.dart` 상단 import 수정:

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/recording.dart';
import '../services/recording_storage_service.dart';
import '../services/whisper_service.dart';
import '../widgets/recording_list_item.dart';
import '../widgets/transcription_dialog.dart';
import 'package:path_provider/path_provider.dart';
```

- [ ] **Step 2: WhisperService 필드 및 _transcribeRecording 메서드 추가**

`RecordingListScreenState` 클래스에 필드 추가 (기존 `_audioPlayer` 선언 아래):

```dart
final WhisperService _whisperService = WhisperService();
```

`_shareRecording` 메서드 위에 추가:

```dart
void _transcribeRecording(Recording recording) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => TranscriptionDialog(
      filePath: recording.filePath,
      whisperService: _whisperService,
    ),
  );
}
```

- [ ] **Step 3: RecordingListItem에 onTranscribe 연결**

`ListView.builder` 내 `RecordingListItem` 호출 수정:

```dart
return RecordingListItem(
  recording: r,
  isPlaying: _playingId == r.id,
  onTap: () => _showDetailDialog(r),
  onPlay: () => _togglePlay(r),
  onShare: () => _shareRecording(r),
  onDelete: () => _deleteRecording(r),
  onTranscribe: () => _transcribeRecording(r),
);
```

- [ ] **Step 4: 전체 테스트 실행 → 통과 확인**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/recording_list_screen.dart
git commit -m "feat: connect TranscriptionDialog to RecordingListScreen"
```

---

## Task 6: 빌드 확인

- [ ] **Step 1: 디버그 APK 빌드**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 2: 빌드 실패 시 — whisper_flutter_new API 확인**

패키지 API가 다를 경우 아래 명령으로 실제 API 확인:

```bash
cat ~/.pub-cache/hosted/pub.dev/whisper_flutter_new-1.0.1/lib/whisper_flutter_new.dart | head -80
```

`Whisper`, `TranscribeRequest`, `WhisperModel` 클래스 시그니처 확인 후 `lib/services/whisper_service.dart`의 `transcribe()` 메서드 수정.
