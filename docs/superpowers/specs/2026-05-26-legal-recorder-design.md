# Legal Recorder — 1차 개발 설계 문서

## 앱 개요

법정 제출용 음성 녹음 앱. 백엔드 없이 Flutter 프론트엔드만으로 동작.  
Android Play Store 배포 대상.

---

## 핵심 기능 (1차)

| 기능 | 설명 |
|------|------|
| 음성 녹음 | WAV 포맷, 앱 내에서만 녹음 |
| SHA-256 해시 | 녹음 완료 시 자동 생성 — 법적 무결성 증명용 |
| 파일 저장 | 앱 내부 스토리지에 저장 |
| 파일 목록 | 녹음 파일 리스트, 검색 기능 |
| 파일 공유 | share_plus 사용 |

---

## 화면 구성

### 하단 네비게이션
- 녹음 탭 / 목록 탭 (설정 없음)

### 녹음 화면 (`recording_screen.dart`)
- 경과 시간 타이머 표시
- 실시간 파형 시각화 (CustomPainter)
- 컨트롤: 재생 / 일시정지 / 정지
- 녹음 완료 시 SHA-256 해시 자동 계산 후 저장

### 목록 화면 (`recording_list_screen.dart`)
- 검색 바 (파일명 검색)
- 녹음 파일 카드: 파일명 / 날짜 / 녹음 시간
- 카드 탭 → 재생 / 공유 / 삭제 액션
- 필터 탭 없음

---

## 아키텍처

```
lib/
├── main.dart
├── screens/
│   ├── recording_screen.dart
│   └── recording_list_screen.dart
├── widgets/
│   ├── waveform_painter.dart        # CustomPainter 기반 파형
│   └── recording_list_item.dart     # 목록 카드 위젯
├── models/
│   └── recording.dart               # 파일명, 경로, 날짜, 해시, 길이
└── services/
    ├── recording_service.dart       # 녹음 시작/정지/저장
    └── hash_service.dart            # SHA-256 해시 생성
```

---

## 상태 관리

setState 기반. 별도 상태관리 라이브러리 없음.

---

## 패키지

| 역할 | 패키지 |
|------|--------|
| 녹음 | `record` |
| 재생 | `audioplayers` |
| 파일 경로 | `path_provider` |
| 공유 | `share_plus` |
| SHA-256 | `crypto` |
| 권한 | `permission_handler` |

---

## 데이터 모델

```dart
class Recording {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final Duration duration;
  final String sha256Hash;
}
```

---

## 디자인

다크 테마. 제공된 목업 디자인 그대로 적용.  
컬러: 배경 #1A1A1A 계열, 포인트 보라색 계열.

---

## Android 권한

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
