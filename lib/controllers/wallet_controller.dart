import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

enum SortType { dateNewest, dateOldest, amountHigh, amountLow, categoryAZ, categoryZA }

class WalletController extends ChangeNotifier {
  final WalletModel _wallet = WalletModel();

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  WalletModel get wallet => _wallet;
  List<Transaction> get transactions => _wallet.transactions;

  SortType _sortType = SortType.dateNewest;
  SortType get sortType => _sortType;

  double get walletBalance => _wallet.totalBalance;


  // ----------------------------------------------------------
  // LOAD DATA (called on app start)
  // ----------------------------------------------------------
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load balance
    _wallet.totalBalance = prefs.getDouble('totalBalance') ?? 0.0;

    // Load sort type
    _sortType = SortType.values[prefs.getInt('sortType') ?? 0];

    // Load transactions
    final jsonString = prefs.getString('transactions');
    if (jsonString != null) {
      final List decodedList = jsonDecode(jsonString);
      _wallet.transactions = decodedList
          .map((item) => Transaction.fromJson(item))
          .toList();
    }

    notifyListeners();
  }

  // ----------------------------------------------------------
  // SAVE DATA
  // ----------------------------------------------------------
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save balance
    await prefs.setDouble('totalBalance', _wallet.totalBalance);

    // Save sort type
    await prefs.setInt('sortType', _sortType.index);

    // Save transaction list
    final jsonList = _wallet.transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(jsonList));
  }

  // ----------------------------------------------------------
  // ADD TRANSACTION (with autosave)
  // ----------------------------------------------------------
  void addTransaction(Transaction transaction) {
    _wallet.transactions.insert(0, transaction);

    listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 300),
    );

    if (transaction.type == "income") {
      _wallet.totalBalance += transaction.amount;
    } else {
      _wallet.totalBalance -= transaction.amount;
    }

    saveData();
    notifyListeners();
  }

  // ----------------------------------------------------------
  // DELETE TRANSACTION (with autosave)
  // ----------------------------------------------------------
  void deleteTransaction(int index) {
    final transaction = _wallet.transactions[index];

    if (transaction.type == "income") {
      _wallet.totalBalance -= transaction.amount;
    } else {
      _wallet.totalBalance += transaction.amount;
    }

    listKey.currentState?.removeItem(
      index,
          (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            transaction.title,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    _wallet.transactions.removeAt(index);

    saveData();
    notifyListeners();
  }

  void deleteTransactionByObject(Transaction tx) {
    final index = _wallet.transactions.indexOf(tx);
    if (index == -1) return;

    deleteTransaction(index);
  }

  // ----------------------------------------------------------
  // SORT + autosave
  // ----------------------------------------------------------
  void sortTransactions(SortType type) {
    _sortType = type;

    switch (type) {
      case SortType.dateNewest:
        transactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortType.dateOldest:
        transactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortType.amountHigh:
        transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortType.amountLow:
        transactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortType.categoryAZ:
        transactions.sort((a, b) => a.category.compareTo(b.category));
        break;
      case SortType.categoryZA:
        transactions.sort((a, b) => b.category.compareTo(a.category));
        break;
    }

    saveData();
    notifyListeners();
  }

  // ----------------------------------------------------------
// ANALYTICS VALUES FOR WALLET PAGE
// ----------------------------------------------------------

  double get thisMonthExpense {
    final now = DateTime.now();
    return _wallet.transactions
        .where((tx) =>
    tx.type == "expense" &&
        tx.date.month == now.month &&
        tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get lastMonthExpense {
    final now = DateTime.now();

    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;

    return _wallet.transactions
        .where((tx) =>
    tx.type == "expense" &&
        tx.date.month == lastMonth &&
        tx.date.year == year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get percentIncrease {
    final last = lastMonthExpense;
    final now = thisMonthExpense;

    if (last == 0) return 0;

    return ((now - last) / last) * 100;
  }


}
