import 'package:flutter/material.dart';

class SignalBadge extends StatelessWidget {
  final String signal;
  final String strength;

  const SignalBadge({super.key, required this.signal, required this.strength});

  Color get badgeColor {
    if (signal == 'BUY') return const Color(0xFF00C896);
    if (signal == 'SELL') return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: badgeColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            signal,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            strength,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
