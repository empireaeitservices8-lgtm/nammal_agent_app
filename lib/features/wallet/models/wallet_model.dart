class WalletModel {
  final int balance;
  final String currency;

  WalletModel({
    this.balance = 0,
    this.currency = 'Coins',
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: json['balance'] is int
          ? json['balance']
          : int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'Coins',
    );
  }
}

class CoinPackageModel {
  final String id;
  final int coins;
  final double price;
  final String? discountText;

  CoinPackageModel({
    required this.id,
    required this.coins,
    required this.price,
    this.discountText,
  });
}
