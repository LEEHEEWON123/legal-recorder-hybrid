import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/recording.dart';
import '../services/recording_storage_service.dart';
import '../services/whisper_service.dart';
import '../widgets/recording_list_item.dart';
import '../widgets/transcription_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:path_provider/path_provider.dart';

class RecordingListScreen extends StatefulWidget {
  const RecordingListScreen({super.key});

  @override
  State<RecordingListScreen> createState() => RecordingListScreenState();
}

class RecordingListScreenState extends State<RecordingListScreen> {
  late RecordingStorageService _storageService;
  List<Recording> _all = [];
  List<Recording> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;
  final WhisperService _whisperService = WhisperService();

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearch);
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _playingId = null);
    });
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _storageService = RecordingStorageService(baseDir: dir.path);
    await _loadRecordings();
  }

  Future<void> reload() => _loadRecordings();

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

  Future<void> _togglePlay(Recording recording) async {
    if (_playingId == recording.id) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(recording.filePath));
      setState(() => _playingId = recording.id);
    }
  }

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

  Future<void> _shareRecording(Recording recording) async {
    await Share.shareXFiles([XFile(recording.filePath)]);
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
    _audioPlayer.dispose();
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
                              isPlaying: _playingId == r.id,
                              onTap: () => _showDetailDialog(r),
                              onPlay: () => _togglePlay(r),
                              onShare: () => _shareRecording(r),
                              onDelete: () => _deleteRecording(r),
                              onTranscribe: () => _transcribeRecording(r),
                            );
                          },
                        ),
                      ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
