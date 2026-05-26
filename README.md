# legal-recorder-hybrid

법정 제출용 음성 녹음 앱. WAV 포맷으로 녹음하고 SHA-256 해시를 자동 생성해 무결성을 증명합니다.

## 요구사항

- Flutter 3.x 이상
- Android SDK (minSdk 21 이상)
- Android 기기 또는 에뮬레이터

## 설치

```bash
git clone https://github.com/<your-repo>/legal-recorder-hybrid.git
cd legal-recorder-hybrid
flutter pub get
```

## 실행

```bash
# 연결된 기기 목록 확인
flutter devices

# 디버그 모드로 실행
flutter run

# 특정 기기 지정
flutter run -d <device-id>
```

## 빌드

```bash
# 디버그 APK
flutter build apk --debug

# 릴리즈 APK
flutter build apk --release
```

빌드 결과물: `build/app/outputs/flutter-apk/app-release.apk`

## 테스트

```bash
flutter test
```

## 주요 기능

- WAV 포맷 녹음 (무손실)
- 녹음 일시정지 / 재개
- 녹음 완료 시 SHA-256 해시 자동 계산
- 녹음 목록 조회 및 검색
- 파일 공유 (이메일, 메신저 등)

## 문서

- [기술 스택](docs/STACK.md)
- [폴더 구조](docs/STRUCTURE.md)
