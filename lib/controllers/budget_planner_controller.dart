import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BudgetPlannerController extends ChangeNotifier {
  /// categories (must match your app)
  final List<String> categories = [
    "Shopping",
    "Food",
    "Bills",
    "Commute",
    "Subscription",
    "Work",
    "Other",
  ];

  /// user-entered monthly saving goal (₱)
  double monthlyGoal = 2000.0;

  /// allocations per category (₱)
  /// initialized to equal split of monthlyGoal
  final Map<String, double> allocations = {};

  BudgetPlannerController({double? initialGoal}) {
    monthlyGoal = initialGoal ?? monthlyGoal;
    _initAllocations();
  }

  void _initAllocations() {
    final equal = monthlyGoal / categories.length;
    allocations.clear();
    for (var c in categories) allocations[c] = equal;
    notifyListeners();
  }

  void setMonthlyGoal(double value) {
    monthlyGoal = value;
    // scale current allocations proportionally to new goal
    final currentSum = totalAllocated;
    if (currentSum <= 0) {
      _initAllocations();
      return;
    }
    final scale = monthlyGoal / currentSum;
    for (var k in allocations.keys.toList()) {
      allocations[k] = (allocations[k]! * scale).clamp(0.0, monthlyGoal);
    }
    notifyListeners();
  }

  double get totalAllocated =>
      allocations.values.fold(0.0, (a, b) => a + b);

  double get remaining => (monthlyGoal - totalAllocated).clamp(0.0, double.infinity);

  /// Called when user drags a single slider.
  /// We set `allocations[key] = newValue`. If the sum exceeds monthlyGoal,
  /// reduce the other categories proportionally.
  void adjustAllocation(String key, double newValue) {
    newValue = newValue.clamp(0.0, monthlyGoal);
    allocations[key] = newValue;

    double sum = totalAllocated;
    if (sum <= monthlyGoal) {
      notifyListeners();
      return;
    }

    // We need to reduce other categories by `excess`.
    double excess = sum - monthlyGoal;

    // collect keys for others
    final otherKeys = allocations.keys.where((k) => k != key).toList();

    // If others are all zero, cap the changed value
    final othersSum =
    otherKeys.fold(0.0, (s, k) => s + allocations[k]!);

    if (othersSum <= 0.0001) {
      // cannot take from others -> cap the changed key
      allocations[key] = allocations[key]! - excess;
      if (allocations[key]! < 0) allocations[key] = 0;
      notifyListeners();
      return;
    }

    // Reduce others proportionally to their current amounts
    for (var k in otherKeys) {
      final current = allocations[k]!;
      // portion of the available other-sum
      final reduction = (current / othersSum) * excess;
      allocations[k] = (current - reduction).clamp(0.0, double.infinity);
    }

    // final safety clamp to fix rounding
    double finalSum = totalAllocated;
    if (finalSum > monthlyGoal) {
      // tiny numeric fix: reduce the changed key a bit
      allocations[key] = (allocations[key]! - (finalSum - monthlyGoal)).clamp(0.0, double.infinity);
    }

    notifyListeners();
  }

  /// quick helper to set allocations to percentages
  void setAllocationPercent(String key, double percent) {
    final value = (monthlyGoal * percent / 100.0);
    adjustAllocation(key, value);
  }

  /// Reset to equal split
  void resetAllocations() {
    _initAllocations();
    notifyListeners();
  }

  Future<void> savePlan() async {
    final prefs = await SharedPreferences.getInstance();

    // Save goal
    await prefs.setDouble('monthlyGoal', monthlyGoal);

    // Save allocations
    for (var cat in categories) {
      await prefs.setDouble('alloc_$cat', allocations[cat] ?? 0.0);
    }
  }

  Future<void> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();

    // load goal
    monthlyGoal = prefs.getDouble('monthlyGoal') ?? monthlyGoal;

    // load allocations
    for (var cat in categories) {
      allocations[cat] = prefs.getDouble('alloc_$cat') ?? 0.0;
    }

    notifyListeners();
  }



}
