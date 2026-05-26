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

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.onPlay,
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
