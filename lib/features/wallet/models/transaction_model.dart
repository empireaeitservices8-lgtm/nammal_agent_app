class TransactionModel {
  final String id;
  final String title;
  final int coins;
  final bool isCredit;
  final DateTime date;
  final String status;

  TransactionModel({
    required this.id,
    required this.title,
    required this.coins,
    required this.isCredit,
    required this.date,
    this.status = 'Completed',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['description'] ?? 'Transaction',
      coins: (json['coins'] ?? json['amount'] ?? 0) is int
          ? (json['coins'] ?? json['amount'] ?? 0)
          : int.tryParse((json['coins'] ?? json['amount'] ?? 0).toString()) ?? 0,
      isCredit: json['type'] == 'credit' || (json['is_credit'] ?? true),
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'Completed',
    );
  }
}
