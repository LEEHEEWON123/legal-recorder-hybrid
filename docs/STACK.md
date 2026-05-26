# Tech Stack

| 역할 | 패키지 | 버전 |
|------|--------|------|
| 음성 녹음 | record | ^6.2.1 |
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
