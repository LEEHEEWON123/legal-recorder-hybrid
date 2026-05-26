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
