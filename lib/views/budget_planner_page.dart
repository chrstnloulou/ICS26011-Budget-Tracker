import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../controllers/budget_planner_controller.dart';


import '../controllers/budget_planner_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/transaction_model.dart';

final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_PH');

class BudgetPlannerPage extends StatefulWidget {
  const BudgetPlannerPage({super.key});

  @override
  State<BudgetPlannerPage> createState() => _BudgetPlannerPageState();
}

class _BudgetPlannerPageState extends State<BudgetPlannerPage> with SingleTickerProviderStateMixin {
  late BudgetPlannerController _ctrl;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = BudgetPlannerController(initialGoal: 2000.0);
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.forward();


    _ctrl.loadPlan();

  }
  int _selectedIndex = 2;

  final Set<int> _selectedItems = {};

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Go to Wallet Page
      Navigator.pushReplacementNamed(context, '/wallet');
    }
    else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/budget');
    }
    else if (index == 1) {
      // Go to Analytics Page
      Navigator.pushReplacementNamed(context, '/analytics');
    }
    else if (index == 3) {
      SystemNavigator.pop();
    }
  }


  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, double> _currentMonthSpent(List<Transaction> txs) {
    final now = DateTime.now();
    final Map<String, double> totals = {};
    for (var tx in txs) {
      if (tx.type != 'expense') continue;
      if (tx.date.month != now.month || tx.date.year != now.year) continue;
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }
    // ensure all categories present (0 if none)
    for (var c in _ctrl.categories) {
      totals[c] = totals[c] ?? 0.0;
    }
    return totals;
  }
  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  @override
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_new, size: 28),
          ),

          const Text(
            "Budget Planner",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Image.asset('assets/logo.png', height: 35),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Provider.of<WalletController>(context);
    final txs = walletCtrl.transactions;
    final spent = _currentMonthSpent(txs);

    return Scaffold(
      backgroundColor: Colors.black,

      // NEW — TOP BAR
      body: Column(
        children: [
          _buildTopBar(context),

          Expanded(
            child: ChangeNotifierProvider<BudgetPlannerController>.value(
              value: _ctrl,
              child: Consumer<BudgetPlannerController>(
                builder: (context, ctrl, _) {
                  final percentSaved = (ctrl.monthlyGoal <= 0)
                      ? 0.0
                      : (ctrl.totalAllocated / ctrl.monthlyGoal)
                      .clamp(0.0, 1.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        // Goal input card
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Monthly Saving Goal",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: TextEditingController(
                                  text: ctrl.monthlyGoal.toStringAsFixed(0),
                                ),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Enter goal amount (₱)',
                                  prefixIcon: Icon(Icons.savings),
                                  border: UnderlineInputBorder(),
                                ),
                                onSubmitted: (v) {
                                  final parsed = double.tryParse(v.replaceAll(',', '')) ?? ctrl.monthlyGoal;
                                  ctrl.setMonthlyGoal(parsed);
                                },
                              ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Allocated: ${currencyFormat.format(ctrl.totalAllocated)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    "Remaining: ${currencyFormat.format(ctrl.remaining)}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),


                        // ... YOUR REMAINING CARDS STAY THE SAME ...
                        // sliders card
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Category Allocations",
                                  style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ...ctrl.categories.map((cat) {
                                final alloc = ctrl.allocations[cat] ?? 0;
                                final spentThisCat = spent[cat] ?? 0.0;
                                final maxSlider = ctrl.monthlyGoal;

                                // CATEGORY COLORS
                                final categoryColors = {
                                  "Bills": Colors.blueAccent,
                                  "Commute": Colors.lightBlue,
                                  "Subscription": Colors.yellow.shade700,
                                  "Work": Colors.teal,
                                  "Other": Colors.grey,
                                  "Food": Colors.orange,
                                  "Shopping": Colors.purple,
                                };

                                final color = categoryColors[cat] ?? Colors.black;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cat,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: color,
                                              ),
                                            ),
                                          ),

                                          // RIGHT-SIDE PESO VALUE
                                          Text(
                                            "₱${currencyFormat.format(alloc)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // SLIDER WITH CUSTOM COLORS
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: color,
                                          thumbColor: color,
                                          inactiveTrackColor: color.withOpacity(0.3),
                                          overlayColor: color.withOpacity(0.15),
                                          trackHeight: 6,
                                        ),
                                        child: Slider(
                                          value: alloc.clamp(0.0, maxSlider),
                                          min: 0,
                                          max: maxSlider,
                                          divisions: 100,
                                          label: "₱${currencyFormat.format(alloc)}",
                                          onChanged: (v) {
                                            ctrl.adjustAllocation(cat, v);
                                          },
                                        ),
                                      ),

                                      Text(
                                        "Spent: ₱${currencyFormat.format(spentThisCat)}",
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black),
                                    onPressed: () =>
                                        ctrl.resetAllocations(),
                                    child: const Text("Reset",
                                        style:
                                        TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white),
                                    onPressed: () async {
                                      await ctrl.savePlan();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Plan saved successfully!")));
                                    },
                                    child: const Text("Save Plan"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Summary card — unchanged
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Plan Summary",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Fancy rows
                              _summaryRow("Goal", "₱${currencyFormat.format(ctrl.monthlyGoal)}"),
                              const SizedBox(height: 8),
                              _summaryRow("Allocated", "₱${currencyFormat.format(ctrl.totalAllocated)}"),
                              const SizedBox(height: 16),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: percentSaved,
                                  minHeight: 14,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    percentSaved >= 0.9 ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    percentSaved >= 1
                                        ? "Fully allocated 🎉"
                                        : "Allocation ${(percentSaved * 100).toStringAsFixed(0)}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ctrl.remaining <= 0
                                        ? "No remaining"
                                        : "Remaining ₱${currencyFormat.format(ctrl.remaining)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ctrl.remaining <= 0 ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              _summaryRow(
                                "Wallet Balance",
                                "₱${currencyFormat.format(walletCtrl.wallet.totalBalance)}",
                              ),
                              const SizedBox(height: 8),

                              Text(
                                ctrl.monthlyGoal > walletCtrl.wallet.totalBalance
                                    ? "⚠️ Goal exceeds your balance."
                                    : "👍 Goal looks reachable!",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: ctrl.monthlyGoal > walletCtrl.wallet.totalBalance
                                      ? Colors.red
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,

        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Exit',
          ),
        ],
      ),
    );
  }

}
