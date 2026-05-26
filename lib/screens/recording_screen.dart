import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/recording_service.dart';
import '../widgets/waveform_painter.dart';
import '../widgets/banner_ad_widget.dart';

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
  Stream<Amplitude>? _amplitudeStream;

  @override
  void initState() {
    super.initState();
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
      _amplitudeStream = _service.amplitudeStream;
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
        _amplitudeStream = null;
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
            child: _state != RecordingState.idle && _amplitudeStream != null
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
                        color: Colors.white.withValues(alpha: 0.2),
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
          const BannerAdWidget(),
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
