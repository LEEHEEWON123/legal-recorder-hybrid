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
        await for (final progress in widget.whisperService.downloadModel()) {
          setState(() => _downloadProgress = progress);
        }
      }

      setState(() => _state = _State.transcribing);
      final text = await widget.whisperService.transcribe(widget.filePath);
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
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
