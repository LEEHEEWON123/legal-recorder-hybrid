# Whisper STT 로컬 변환 기능 설계

**작성일:** 2026-05-26  
**목표:** 목록 화면에서 녹음 파일을 로컬 Whisper 모델로 텍스트 변환

---

## 개요

목록 화면의 점 3개 메뉴에 "텍스트 변환" 항목을 추가한다. 탭 시 다이얼로그가 열리며 로컬 Whisper 모델로 WAV 파일을 한국어 텍스트로 변환한다. 변환 결과는 다이얼로그에 표시되고 클립보드 복사가 가능하다.

---

## 스택

- **패키지:** `whisper_flutter_new`
- **모델:** `ggml-small.bin` (약 460MB, 한국어 적정 정확도)
- **모델 저장:** 앱 내부 디렉터리 (`getApplicationDocumentsDirectory`)
- **모델 다운로드:** 첫 변환 시도 시 자동 다운로드 (Hugging Face 공개 URL)

---

## UX 흐름

```
목록 아이템 → 점 3개 메뉴 → "텍스트 변환" 탭
→ TranscriptionDialog 오픈
→ 모델 미존재 시: "모델 다운로드 중..." 표시 (진행률 포함)
→ 모델 존재 시: "변환 중..." 로딩 표시
→ 변환 완료: 텍스트 결과 + 복사 버튼
→ 실패 시: 오류 메시지 표시
```

---

## 컴포넌트

### 1. `WhisperService` (신규)
`lib/services/whisper_service.dart`

- 역할: 모델 다운로드 및 STT 변환 담당
- 인터페이스:
  - `Future<bool> isModelReady()` — 모델 파일 존재 여부
  - `Stream<double> downloadModel()` — 모델 다운로드 (진행률 0.0~1.0)
  - `Future<String> transcribe(String filePath)` — WAV → 텍스트 변환

### 2. `TranscriptionDialog` (신규)
`lib/widgets/transcription_dialog.dart`

- 역할: 변환 상태(다운로드/변환중/완료/오류) UI 표시
- 상태:
  - `downloading` — 모델 다운로드 중 (진행률 표시)
  - `transcribing` — 변환 중 (로딩 스피너)
  - `done` — 결과 텍스트 + 복사 버튼
  - `error` — 오류 메시지

### 3. `RecordingListItem` (수정)
- 점 3개 메뉴에 `텍스트 변환` 항목 추가
- `onTranscribe` 콜백 추가

### 4. `RecordingListScreen` (수정)
- `_transcribeRecording(Recording)` 메서드 추가
- `TranscriptionDialog` 호출

---

## 모델 다운로드

- URL: Hugging Face `ggerganov/whisper.cpp` 공개 저장소의 `ggml-small.bin`
- 저장 경로: `{appDocDir}/whisper/ggml-small.bin`
- 다운로드 패키지: `http` (기존 패키지 활용)
- 460MB 대용량이므로 진행률 표시 필수

---

## 나중에 교체 시 (Whisper API)

`WhisperService.transcribe()` 내부만 교체하면 되므로 UI/UX 변경 없음.

---

## 추가할 패키지

```yaml
whisper_flutter_new: ^1.0.0
```
