import 'package:flutter/material.dart';

class CoinListTile extends StatelessWidget {
  final String name;
  final String symbol;
  final double priceUsd;
  final double priceInr;
  final double change24h;
  final VoidCallback? onTap;

  const CoinListTile({
    super.key,
    required this.name,
    required this.symbol,
    required this.priceUsd,
    required this.priceInr,
    required this.change24h,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0B141E),
              child: Text(initial, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(symbol.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${priceUsd.toStringAsFixed(priceUsd < 1 ? 6 : 2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹${priceInr.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: change24h >= 0 ? const Color(0xFF07301D) : const Color(0xFF3D1014),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                style: TextStyle(color: change24h >= 0 ? const Color(0xFF00C896) : Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
