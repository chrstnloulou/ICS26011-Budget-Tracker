import '../models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';


class AnalyticsController {
  // -----------------------------
  // STORED VALUES
  // -----------------------------
  double _walletAmount = 0.0;
  List<Transaction> allTransactions = [];

  // -----------------------------
  // SETTERS (CALLED FROM PAGE)
  // -----------------------------
  void setWallet(double amount) {
    _walletAmount = amount;
  }

  void setTransactions(List<Transaction> txs) {
    allTransactions = txs;
  }

  // -----------------------------
  // GETTERS FOR UI
  // -----------------------------
  double get walletAmount => _walletAmount;

  double get thisMonthExpense => getTotalSpentThisMonth();
  double get lastMonthExpense => getTotalSpentLastMonth();
  double get percentIncrease => getPercentDifference();

  // -----------------------------
  // TOTAL SPENT THIS MONTH
  // -----------------------------
  double getTotalSpentThisMonth() {
    final now = DateTime.now();
    return allTransactions
        .where((tx) =>
    tx.type == "expense" &&
        tx.date.month == now.month &&
        tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // -----------------------------
  // TOTAL SPENT LAST MONTH
  // -----------------------------
  double getTotalSpentLastMonth() {
    final now = DateTime.now();

    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;

    return allTransactions
        .where((tx) =>
    tx.type == "expense" &&
        tx.date.month == lastMonth &&
        tx.date.year == year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // -----------------------------
  // PERCENT DIFFERENCE
  // -----------------------------
  double getPercentDifference() {
    final last = getTotalSpentLastMonth();
    final now = getTotalSpentThisMonth();

    if (last == 0) return 0;

    return ((now - last) / last) * 100;
  }

  // -----------------------------
  // MONTH GRAPH DATA (Expense/day)
  // -----------------------------
  Map<int, double> getMonthlyData() {
    final now = DateTime.now();
    Map<int, double> dailyTotals = {};

    for (var tx in allTransactions) {
      if (tx.type != "expense") continue;
      if (tx.date.month != now.month || tx.date.year != now.year) continue;

      dailyTotals[tx.date.day] =
          (dailyTotals[tx.date.day] ?? 0) + tx.amount;
    }
    return dailyTotals;
  }

  // -----------------------------
  // YEAR GRAPH DATA (Expense/month)
  // -----------------------------
  Map<int, double> getYearlyData() {
    final now = DateTime.now();
    Map<int, double> monthTotals = {};

    for (var tx in allTransactions) {
      if (tx.type != "expense") continue;
      if (tx.date.year != now.year) continue;

      monthTotals[tx.date.month] =
          (monthTotals[tx.date.month] ?? 0) + tx.amount;
    }
    return monthTotals;
  }

  // -----------------------------
// CATEGORY TOTALS FOR PIE CHART
// -----------------------------
  Map<String, double> getCategoryTotals() {
    Map<String, double> totals = {};

    for (var tx in allTransactions) {
      if (tx.type != "expense") continue;

      totals[tx.category] =
          (totals[tx.category] ?? 0) + tx.amount;
    }

    return totals;
  }

// -----------------------------
// HIGHEST SPENT CATEGORY
// -----------------------------
  String getTopCategory() {
    final totals = getCategoryTotals();
    if (totals.isEmpty) return "No Expense";

    return totals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<FlSpot> getMonthlySpots() {
    final data = getMonthlyData();
    List<FlSpot> spots = [];

    for (int day = 1; day <= 31; day++) {
      final value = data[day] ?? 0.0;
      spots.add(FlSpot(day.toDouble(), value));
    }
    return spots;
  }
  List<FlSpot> getYearlySpots() {
    final data = getYearlyData();
    List<FlSpot> spots = [];

    for (int month = 1; month <= 12; month++) {
      final value = data[month] ?? 0.0;
      spots.add(FlSpot(month.toDouble(), value));
    }
    return spots;
  }

  double calculateInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    double maxY = spots.map((e) => e.y).fold(0, max);

    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;

    return maxY / 5;
  }

}
