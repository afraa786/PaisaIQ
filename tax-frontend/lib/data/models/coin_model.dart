import 'package:alpharedge_flutter/data/models/coin_signal_model.dart';
import 'package:alpharedge_flutter/data/models/price_snapshot_model.dart';

class CoinModel {
  final String id;
  final String coinId;
  final String symbol;
  final String name;
  final bool isActive;
  final String createdAt;
  final PriceSnapshotModel priceSnapshot;
  final CoinSignalModel signal;

  CoinModel({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.priceSnapshot,
    required this.signal,
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) => CoinModel(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        isActive: json['isActive'] as bool,
        createdAt: json['createdAt'] as String,
        priceSnapshot: PriceSnapshotModel.fromJson(json['priceSnapshot'] as Map<String, dynamic>),
        signal: CoinSignalModel.fromJson(json['signal'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'symbol': symbol,
        'name': name,
        'isActive': isActive,
        'createdAt': createdAt,
        'priceSnapshot': priceSnapshot.toJson(),
        'signal': signal.toJson(),
      };
}
