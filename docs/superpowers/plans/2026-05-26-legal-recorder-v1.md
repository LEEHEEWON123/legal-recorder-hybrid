# Legal Recorder v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** WAV 포맷 음성 녹음, SHA-256 해시 자동 생성, 파일 목록/공유 기능을 갖춘 Android용 법정 녹음 앱 구현

**Architecture:** setState 기반 단순 구조. 화면 2개(녹음/목록), 서비스 2개(RecordingService/HashService). 녹음 완료 시 SHA-256 자동 계산 후 JSON 메타데이터 파일로 함께 저장.

**Tech Stack:** Flutter (Android), record, audioplayers, path_provider, share_plus, crypto, permission_handler

---

## 파일 구조

```
lib/
├── main.dart                          # 앱 진입점, 테마, 하단 탭 네비게이션
├── models/
│   └── recording.dart                 # Recording 데이터 모델
├── services/
│   ├── hash_service.dart              # SHA-256 해시 계산
│   ├── recording_service.dart         # 녹음 시작/일시정지/정지/저장
│   └── recording_storage_service.dart # 파일 목록 로드/삭제/메타데이터 관리
├── screens/
│   ├── recording_screen.dart          # 녹음 화면 (타이머, 파형, 컨트롤)
│   └── recording_list_screen.dart     # 목록 화면 (검색, 리스트)
└── widgets/
    ├── waveform_painter.dart           # CustomPainter 기반 실시간 파형
    └── recording_list_item.dart        # 목록 카드 위젯

test/
├── models/
│   └── recording_test.dart
├── services/
│   ├── hash_service_test.dart
│   └── recording_storage_service_test.dart
└── widgets/
    └── recording_list_item_test.dart

android/app/src/main/AndroidManifest.xml  # 마이크/스토리지 권한
```

---

## Task 1: Flutter 프로젝트 생성 및 패키지 설정

**Files:**
- Create: `pubspec.yaml` (flutter create 후 수정)
- Create: `android/app/src/main/AndroidManifest.xml` (수정)

- [ ] **Step 1: Flutter 프로젝트 생성**

```bash
cd /Users/leeheewon/Documents/legal-recorder-hybrid
flutter create . --org com.legalrecorder --project-name legal_recorder --platforms android
```

Expected: Flutter 프로젝트 파일 생성됨

- [ ] **Step 2: pubspec.yaml 의존성 추가**

`pubspec.yaml`의 `dependencies` 섹션을 아래로 교체:

```yaml
dependencies:
  flutter:
    sdk: flutter
  record: ^5.1.2
  audioplayers: ^6.0.0
  path_provider: ^2.1.3
  share_plus: ^10.0.2
  crypto: ^3.0.3
  permission_handler: ^11.3.1
  intl: ^0.19.0
```

- [ ] **Step 3: 패키지 설치**

```bash
flutter pub get
```

Expected: `pub get` 성공, `pubspec.lock` 생성됨

- [ ] **Step 4: AndroidManifest.xml 권한 추가**

`android/app/src/main/AndroidManifest.xml`의 `<manifest>` 태그 바로 아래에 추가:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

`<activity>` 태그의 `android:exported="true"` 확인 (flutter create 기본 포함됨)

- [ ] **Step 5: minSdkVersion 설정**

`android/app/build.gradle`에서 `minSdkVersion`을 21로 설정:

```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
    ...
}
```

- [ ] **Step 6: 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "chore: flutter project scaffold with dependencies"
```

---

## Task 2: Recording 모델

**Files:**
- Create: `lib/models/recording.dart`
- Create: `test/models/recording_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/models/recording_test.dart`:

```dart
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
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/models/recording_test.dart
```

Expected: FAIL — `recording.dart` 없음

- [ ] **Step 3: Recording 모델 구현**

`lib/models/recording.dart`:

```dart
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
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/models/recording_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/recording.dart test/models/recording_test.dart
git commit -m "feat: add Recording model with toJson/fromJson and formattedDuration"
```

---

## Task 3: HashService (SHA-256)

**Files:**
- Create: `lib/services/hash_service.dart`
- Create: `test/services/hash_service_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/services/hash_service_test.dart`:

```dart
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
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/services/hash_service_test.dart
```

Expected: FAIL — `hash_service.dart` 없음

- [ ] **Step 3: HashService 구현**

`lib/services/hash_service.dart`:

```dart
import 'dart:io';
import 'package:crypto/crypto.dart';

class HashService {
  static Future<String> computeSha256(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/services/hash_service_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/hash_service.dart test/services/hash_service_test.dart
git commit -m "feat: add HashService with SHA-256 computation"
```

---

## Task 4: RecordingStorageService (메타데이터 저장/목록 관리)

**Files:**
- Create: `lib/services/recording_storage_service.dart`
- Create: `test/services/recording_storage_service_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/services/recording_storage_service_test.dart`:

```dart
import 'dart:io';
import 'dart:convert';
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
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/services/recording_storage_service_test.dart
```

Expected: FAIL — `recording_storage_service.dart` 없음

- [ ] **Step 3: RecordingStorageService 구현**

`lib/services/recording_storage_service.dart`:

```dart
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
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/services/recording_storage_service_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/recording_storage_service.dart test/services/recording_storage_service_test.dart
git commit -m "feat: add RecordingStorageService with JSON index file"
```

---

## Task 5: RecordingService (녹음 시작/정지)

**Files:**
- Create: `lib/services/recording_service.dart`

> 이 서비스는 실제 마이크 하드웨어 의존성으로 자동화 단위 테스트 불가. 통합 테스트(디바이스)로 검증한다.

- [ ] **Step 1: RecordingService 구현**

`lib/services/recording_service.dart`:

```dart
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recording.dart';
import 'hash_service.dart';
import 'recording_storage_service.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  late RecordingStorageService _storageService;
  String? _currentPath;
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

    _currentPath = path;
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
    _currentPath = null;
    _startTime = null;
    return recording;
  }

  Future<bool> isRecording() async => await _recorder.isRecording();
  Future<bool> isPaused() async => await _recorder.isPaused();

  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  void dispose() {
    _recorder.dispose();
  }
}
```

- [ ] **Step 2: 전체 단위 테스트 통과 확인**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add lib/services/recording_service.dart
git commit -m "feat: add RecordingService with WAV recording and SHA-256 on stop"
```

---

## Task 6: 앱 테마 및 메인 네비게이션 (main.dart)

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: main.dart 구현**

`lib/main.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'screens/recording_screen.dart';
import 'screens/recording_list_screen.dart';

void main() {
  runApp(const LegalRecorderApp());
}

class LegalRecorderApp extends StatelessWidget {
  const LegalRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '법정 녹음기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B5EA7),
          surface: Color(0xFF242424),
          onSurface: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFF7B5EA7),
          unselectedItemColor: Color(0xFF888888),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF888888)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          RecordingScreen(),
          RecordingListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_outlined),
            activeIcon: Icon(Icons.mic),
            label: '녹음',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: '목록',
          ),
        ],
      ),
    );
  }
}
```

> `RecordingScreen`과 `RecordingListScreen`은 Task 7, 8에서 생성. 지금은 임시 placeholder로 컴파일 확인.

- [ ] **Step 2: 임시 placeholder 화면 생성 (컴파일 확인용)**

`lib/screens/recording_screen.dart`:

```dart
import 'package:flutter/material.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('녹음 화면')));
  }
}
```

`lib/screens/recording_list_screen.dart`:

```dart
import 'package:flutter/material.dart';

class RecordingListScreen extends StatelessWidget {
  const RecordingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('목록 화면')));
  }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/screens/
git commit -m "feat: app theme, bottom nav, placeholder screens"
```

---

## Task 7: WaveformPainter 위젯

**Files:**
- Create: `lib/widgets/waveform_painter.dart`

- [ ] **Step 1: WaveformPainter 구현**

`lib/widgets/waveform_painter.dart`:

```dart
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes; // 0.0 ~ 1.0 정규화된 값
  final Color waveColor;
  final Color centerLineColor;

  const WaveformPainter({
    required this.amplitudes,
    this.waveColor = const Color(0xFF7B5EA7),
    this.centerLineColor = const Color(0xFFE05A5A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 중앙 세로선 (빨간색)
    final linePaint = Paint()
      ..color = centerLineColor
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    if (amplitudes.isEmpty) return;

    final barPaint = Paint()
      ..color = waveColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const barWidth = 3.0;
    const gap = 2.5;
    final totalBars = (size.width / (barWidth + gap)).floor();

    final display = amplitudes.length > totalBars
        ? amplitudes.sublist(amplitudes.length - totalBars)
        : amplitudes;

    for (int i = 0; i < display.length; i++) {
      final x = i * (barWidth + gap);
      final normalized = display[i].clamp(0.0, 1.0);
      final barHeight = (normalized * size.height * 0.75).clamp(4.0, size.height);
      final top = (size.height - barHeight) / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/waveform_painter.dart
git commit -m "feat: add WaveformPainter CustomPainter widget"
```

---

## Task 8: RecordingListItem 위젯

**Files:**
- Create: `lib/widgets/recording_list_item.dart`
- Create: `test/widgets/recording_list_item_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/widgets/recording_list_item_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_recorder/models/recording.dart';
import 'package:legal_recorder/widgets/recording_list_item.dart';

void main() {
  final testRecording = Recording(
    id: 'test-001',
    fileName: '음성 녹음 001',
    filePath: '/path/test.wav',
    createdAt: DateTime(2026, 5, 26, 10, 15),
    duration: const Duration(minutes: 2, seconds: 15),
    sha256Hash: 'abc123',
  );

  Widget buildWidget({
    VoidCallback? onShare,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: RecordingListItem(
          recording: testRecording,
          onShare: onShare ?? () {},
          onDelete: onDelete ?? () {},
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  testWidgets('파일명이 표시된다', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('음성 녹음 001'), findsOneWidget);
  });

  testWidgets('포맷된 duration이 표시된다', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('02:15'), findsOneWidget);
  });

  testWidgets('onTap 콜백이 탭 시 호출된다', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(buildWidget(onTap: () => tapped = true));
    await tester.tap(find.byType(RecordingListItem));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
flutter test test/widgets/recording_list_item_test.dart
```

Expected: FAIL — `recording_list_item.dart` 없음

- [ ] **Step 3: RecordingListItem 구현**

`lib/widgets/recording_list_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recording.dart';

class RecordingListItem extends StatelessWidget {
  final Recording recording;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.onShare,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy. MM. dd. HH:mm').format(recording.createdAt);

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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic, color: Color(0xFF7B5EA7), size: 20),
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
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            Text(
              recording.formattedDuration,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF888888), size: 20),
              color: const Color(0xFF2A2A2A),
              onSelected: (value) {
                if (value == 'share') onShare();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'share', child: Text('공유')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: Colors.redAccent)),
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

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/widgets/recording_list_item_test.dart
```

Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/recording_list_item.dart test/widgets/recording_list_item_test.dart
git commit -m "feat: add RecordingListItem widget with share/delete menu"
```

---

## Task 9: RecordingListScreen (목록 화면)

**Files:**
- Modify: `lib/screens/recording_list_screen.dart`

- [ ] **Step 1: RecordingListScreen 구현**

`lib/screens/recording_list_screen.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recording.dart';
import '../services/recording_storage_service.dart';
import '../services/recording_service.dart';
import '../widgets/recording_list_item.dart';
import 'package:path_provider/path_provider.dart';

class RecordingListScreen extends StatefulWidget {
  const RecordingListScreen({super.key});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  late RecordingStorageService _storageService;
  List<Recording> _all = [];
  List<Recording> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearch);
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _storageService = RecordingStorageService(baseDir: dir.path);
    await _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final recordings = await _storageService.loadAll();
    setState(() {
      _all = recordings;
      _filtered = recordings;
      _loading = false;
    });
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all
          .where((r) => r.fileName.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _shareRecording(Recording recording) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(recording.filePath)]),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('녹음 삭제'),
        content: Text('\'${recording.fileName}\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.delete(recording);
      await _loadRecordings();
    }
  }

  Future<void> _showDetailDialog(Recording recording) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: Text(recording.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('길이: ${recording.formattedDuration}'),
            const SizedBox(height: 8),
            const Text('SHA-256:',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
            SelectableText(
              recording.sha256Hash,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('녹음 목록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '녹음 파일 검색',
                prefixIcon: Icon(Icons.search, color: Color(0xFF888888)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '최근 녹음 (${_filtered.length})',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF888888)),
                ),
                const Spacer(),
                const Text('최신순',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('녹음 파일이 없습니다.',
                            style: TextStyle(color: Color(0xFF888888))))
                    : RefreshIndicator(
                        onRefresh: _loadRecordings,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, index) {
                            final r = _filtered[index];
                            return RecordingListItem(
                              recording: r,
                              onTap: () => _showDetailDialog(r),
                              onShare: () => _shareRecording(r),
                              onDelete: () => _deleteRecording(r),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/recording_list_screen.dart
git commit -m "feat: implement RecordingListScreen with search, share, delete"
```

---

## Task 10: RecordingScreen (녹음 화면)

**Files:**
- Modify: `lib/screens/recording_screen.dart`

- [ ] **Step 1: RecordingScreen 구현**

`lib/screens/recording_screen.dart` 전체 교체:

```dart
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/recording_service.dart';
import '../widgets/waveform_painter.dart';

enum RecordingState { idle, recording, paused }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final RecordingService _service = RecordingService();
  RecordingState _state = RecordingState.idle;
  Duration _elapsed = Duration.zero;
  List<double> _amplitudes = [];
  late Stream<Amplitude> _amplitudeStream;

  @override
  void initState() {
    super.initState();
    _amplitudeStream = _service.amplitudeStream;
  }

  String get _timerText {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (_elapsed.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$m:$s.$ms';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
        );
      }
      return;
    }

    await _service.startRecording();
    setState(() {
      _state = RecordingState.recording;
      _elapsed = Duration.zero;
      _amplitudes = [];
    });

    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _state == RecordingState.idle) return false;
      if (_state == RecordingState.recording) {
        setState(() => _elapsed += const Duration(milliseconds: 100));
      }
      return true;
    });
  }

  Future<void> _pauseRecording() async {
    await _service.pauseRecording();
    setState(() => _state = RecordingState.paused);
  }

  Future<void> _resumeRecording() async {
    await _service.resumeRecording();
    setState(() => _state = RecordingState.recording);
  }

  Future<void> _stopRecording() async {
    final nameController = TextEditingController();
    final fileName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('녹음 저장'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '파일 이름 (선택 사항)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (fileName == null) return;

    try {
      await _service.stopAndSave(fileName: fileName);
      setState(() {
        _state = RecordingState.idle;
        _elapsed = Duration.zero;
        _amplitudes = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음이 저장되었습니다. SHA-256 해시가 생성되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('음성 녹음',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 상태 표시
          Text(
            _state == RecordingState.recording
                ? '● 녹음 중'
                : _state == RecordingState.paused
                    ? '⏸ 일시정지'
                    : '표준 녹음',
            style: TextStyle(
              fontSize: 12,
              color: _state == RecordingState.recording
                  ? Colors.redAccent
                  : const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),

          // 타이머
          Text(
            _timerText,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w200,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // 파형
          SizedBox(
            height: 80,
            width: double.infinity,
            child: _state != RecordingState.idle
                ? StreamBuilder<Amplitude>(
                    stream: _amplitudeStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && _state == RecordingState.recording) {
                        final amp = snapshot.data!.current;
                        // dBFS → 0~1 정규화 (-60dB ~ 0dB)
                        final normalized = ((amp + 60) / 60).clamp(0.0, 1.0);
                        _amplitudes = [..._amplitudes, normalized];
                        if (_amplitudes.length > 200) {
                          _amplitudes = _amplitudes.sublist(_amplitudes.length - 200);
                        }
                      }
                      return CustomPaint(
                        painter: WaveformPainter(amplitudes: List.from(_amplitudes)),
                        size: Size.infinite,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 64),

          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 재생/재개 버튼
              _ControlButton(
                icon: Icons.play_arrow,
                size: 48,
                enabled: _state == RecordingState.paused,
                onTap: _state == RecordingState.paused ? _resumeRecording : null,
              ),
              const SizedBox(width: 24),

              // 메인 버튼 (녹음시작 / 일시정지)
              GestureDetector(
                onTap: _state == RecordingState.idle
                    ? _startRecording
                    : _state == RecordingState.recording
                        ? _pauseRecording
                        : _resumeRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _state == RecordingState.idle
                        ? Icons.mic
                        : _state == RecordingState.recording
                            ? Icons.pause
                            : Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // 정지 버튼
              _ControlButton(
                icon: Icons.stop,
                size: 48,
                enabled: _state != RecordingState.idle,
                onTap: _state != RecordingState.idle ? _stopRecording : null,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : const Color(0xFF444444),
          size: size * 0.5,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 전체 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: 전체 테스트 실행**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/screens/recording_screen.dart
git commit -m "feat: implement RecordingScreen with timer, waveform, record controls"
```

---

## Task 11: 최종 확인 및 릴리즈 APK 빌드

- [ ] **Step 1: 전체 테스트 통과 확인**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 2: 릴리즈 APK 빌드**

```bash
flutter build apk --release 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 3: 문서 MD 파일 업데이트 (STACK.md, STRUCTURE.md)**

`docs/STACK.md` 생성:

```markdown
# Tech Stack

| 역할 | 패키지 | 버전 |
|------|--------|------|
| 음성 녹음 | record | ^5.1.2 |
| 음성 재생 | audioplayers | ^6.0.0 |
| 파일 경로 | path_provider | ^2.1.3 |
| 파일 공유 | share_plus | ^10.0.2 |
| SHA-256 | crypto | ^3.0.3 |
| 권한 관리 | permission_handler | ^11.3.1 |
| 날짜 포맷 | intl | ^0.19.0 |

## 상태 관리
setState 기반. 별도 라이브러리 없음.

## 포맷
WAV (44100Hz, 1ch, 무손실)

## 해시
SHA-256 — 녹음 완료 시 자동 계산. 법정 제출용 무결성 증명.
```

`docs/STRUCTURE.md` 생성:

```markdown
# Folder Structure

```
lib/
├── main.dart                          # 앱 진입점, 테마, 하단 탭 네비
├── models/
│   └── recording.dart                 # Recording 데이터 모델
├── services/
│   ├── hash_service.dart              # SHA-256 해시 계산
│   ├── recording_service.dart         # 녹음 시작/정지/저장
│   └── recording_storage_service.dart # 파일 목록/메타데이터 JSON 관리
├── screens/
│   ├── recording_screen.dart          # 녹음 화면
│   └── recording_list_screen.dart     # 목록 화면
└── widgets/
    ├── waveform_painter.dart           # 실시간 파형 CustomPainter
    └── recording_list_item.dart        # 목록 카드 위젯

test/
├── models/recording_test.dart
├── services/
│   ├── hash_service_test.dart
│   └── recording_storage_service_test.dart
└── widgets/recording_list_item_test.dart
```
```

- [ ] **Step 4: 최종 Commit**

```bash
git add docs/STACK.md docs/STRUCTURE.md
git commit -m "docs: add STACK.md and STRUCTURE.md"
```
