class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final String type; // "income" or "expense"
  final String category;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
    };
  }

  // Convert JSON map → Transaction
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      category: json['category'],
    );
  }
}
