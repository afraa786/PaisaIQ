import 'package:flutter/material.dart';
import '../data/models/ohlc_model.dart';
import '../utils/theme.dart';

class CandlestickChart extends StatefulWidget {
  const CandlestickChart({
    super.key,
    required this.candles,
    this.height = 220,
  });

  final List<OhlcModel> candles;
  final double height;

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('No chart data', style: TextStyle(color: kGray2, fontSize: 12)),
        ),
      );
    }

    final candles = widget.candles.length > 60
        ? widget.candles.sublist(widget.candles.length - 60)
        : widget.candles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hovered candle info
        SizedBox(
          height: 20,
          child: _hoveredIndex != null && _hoveredIndex! < candles.length
              ? _HoverInfo(candle: candles[_hoveredIndex!])
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: widget.height,
          child: MouseRegion(
            onHover: (event) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localX = event.localPosition.dx;
              final candleWidth = box.size.width / candles.length;
              final idx = (localX / candleWidth).floor().clamp(0, candles.length - 1);
              if (idx != _hoveredIndex) setState(() => _hoveredIndex = idx);
            },
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CandlePainter(
                candles: candles,
                hoveredIndex: _hoveredIndex,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverInfo extends StatelessWidget {
  const _HoverInfo({required this.candle});
  final OhlcModel candle;

  @override
  Widget build(BuildContext context) {
    final color = candle.isBullish ? kGreen : kRed;
    return Row(
      children: [
        _tag('O', candle.open, color),
        const SizedBox(width: 12),
        _tag('H', candle.high, color),
        const SizedBox(width: 12),
        _tag('L', candle.low, color),
        const SizedBox(width: 12),
        _tag('C', candle.close, color),
      ],
    );
  }

  Widget _tag(String label, double val, Color color) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(color: kGray2, fontSize: 11)),
            TextSpan(
                text: val >= 1000
                    ? '\$${val.toStringAsFixed(0)}'
                    : '\$${val.toStringAsFixed(4)}',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.candles, this.hoveredIndex});

  final List<OhlcModel> candles;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final allHigh = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final allLow  = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range   = allHigh - allLow;
    if (range == 0) return;

    final candleWidth = size.width / candles.length;
    final bodyWidth   = (candleWidth * 0.55).clamp(2.0, 12.0);
    final wickWidth   = 1.0;

    double toY(double price) =>
        size.height - ((price - allLow) / range) * size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < candles.length; i++) {
      final c       = candles[i];
      final cx      = i * candleWidth + candleWidth / 2;
      final isUp    = c.isBullish;
      final color   = isUp ? kGreen : kRed;
      final hovered = i == hoveredIndex;

      final bodyTop    = toY(isUp ? c.close : c.open);
      final bodyBottom = toY(isUp ? c.open  : c.close);
      final bodyH      = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      final paint = Paint()
        ..color = hovered ? color.withAlpha(220) : color
        ..style = hovered ? PaintingStyle.fill : PaintingStyle.fill;

      // Wick
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = wickWidth;
      canvas.drawLine(
          Offset(cx, toY(c.high)), Offset(cx, toY(c.low)), wickPaint);

      // Body
      canvas.drawRect(
        Rect.fromLTWH(cx - bodyWidth / 2, bodyTop, bodyWidth, bodyH),
        paint,
      );

      // Hover crosshair
      if (hovered) {
        final crossPaint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 0.5;
        canvas.drawLine(
            Offset(cx, 0), Offset(cx, size.height), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.candles != candles || old.hoveredIndex != hoveredIndex;
}
