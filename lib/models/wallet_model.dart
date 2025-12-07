import 'transaction_model.dart';

class WalletModel {
  double totalBalance;
  List<Transaction> transactions;

  WalletModel({
    this.totalBalance = 0.0,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];
}
