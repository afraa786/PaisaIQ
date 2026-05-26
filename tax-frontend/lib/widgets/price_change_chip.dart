import 'package:flutter/material.dart';

class PriceChangeChip extends StatelessWidget {
  final double change;

  const PriceChangeChip({super.key, required this.change});

  Color get backgroundColor => change >= 0 ? const Color(0xFF0A3A24) : const Color(0xFF4B161F);
  Color get textColor => change >= 0 ? const Color(0xFF00C896) : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
