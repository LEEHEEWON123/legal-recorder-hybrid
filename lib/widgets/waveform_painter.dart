import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes; // 0.0 ~ 1.0 정규화된 값
  final Color waveColor;
  final Color centerLineColor;

  const WaveformPainter({
    required this.amplitudes,
    this.waveColor = const Color(0xFF7B5EA7),
    this.centerLineColor = const Color(0xFFE05A5A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 중앙 세로선 (빨간색)
    final linePaint = Paint()
      ..color = centerLineColor
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    if (amplitudes.isEmpty) return;

    final barPaint = Paint()
      ..color = waveColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const barWidth = 3.0;
    const gap = 2.5;
    final totalBars = (size.width / (barWidth + gap)).floor();

    final display = amplitudes.length > totalBars
        ? amplitudes.sublist(amplitudes.length - totalBars)
        : amplitudes;

    for (int i = 0; i < display.length; i++) {
      final x = i * (barWidth + gap);
      final normalized = display[i].clamp(0.0, 1.0);
      final barHeight = (normalized * size.height * 0.75).clamp(4.0, size.height);
      final top = (size.height - barHeight) / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes;
}
