class AlertModel {
  final String id;
  final String coinId;
  final String condition;
  final double targetPrice;
  final String email;

  AlertModel({
    required this.id,
    required this.coinId,
    required this.condition,
    required this.targetPrice,
    required this.email,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] as String,
        coinId: json['coinId'] as String,
        condition: json['condition'] as String,
        targetPrice: (json['targetPrice'] as num).toDouble(),
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coinId': coinId,
        'condition': condition,
        'targetPrice': targetPrice,
        'email': email,
      };
}
