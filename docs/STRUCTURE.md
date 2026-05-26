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
