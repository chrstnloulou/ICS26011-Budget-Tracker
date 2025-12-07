import 'package:flutter/material.dart';
import 'package:mobprogproj/views/analytics_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/analytics_controller.dart';
import '../models/transaction_model.dart';
import 'package:flutter/services.dart';



class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}
final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_PH');


class _WalletPageState extends State<WalletPage> {
  int _selectedIndex = 0;
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsPage()),
      );
    }
    else if (index == 3) {
      // Exit (optional)
      SystemNavigator.pop();
    }

  }

  void _showAddTransactionDialog(BuildContext context, WalletController controller) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'Other';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Add Transaction',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),

                    // Dropdown for type
                    DropdownButtonFormField<String>(
                      value: type,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      ],
                      onChanged: (val) => type = val!,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: category,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.black,
                      items: const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                        DropdownMenuItem(value: 'Work', child: Text('Work')),
                        DropdownMenuItem(value: 'Subscription', child: Text('Subscription')),
                        DropdownMenuItem(value: 'Commute', child: Text('Commute')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) => category = val!,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Date picker (now updates live)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedDate.toLocal()}".split(' ')[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    final transaction = Transaction(
                      title: titleController.text,
                      amount: double.tryParse(amountController.text) ?? 0,
                      date: selectedDate,
                      type: type,
                      category: category,
                    );
                    controller.addTransaction(transaction);
                    Navigator.pop(context);
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final walletController = Provider.of<WalletController>(context, listen: false);

        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Sort By",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _buildSortOption(
                  label: "Date (Newest First)",
                  onTap: () {
                    walletController.sortTransactions(SortType.dateNewest);
                    Navigator.pop(context);
                  },
                ),

                _buildSortOption(
                  label: "Date (Oldest First)",
                  onTap: () {
                    walletController.sortTransactions(SortType.dateOldest);
                    Navigator.pop(context);
                  },
                ),

                _buildSortOption(
                  label: "Amount (High → Low)",
                  onTap: () {
                    walletController.sortTransactions(SortType.amountHigh);
                    Navigator.pop(context);
                  },
                ),

                _buildSortOption(
                  label: "Amount (Low → High)",
                  onTap: () {
                    walletController.sortTransactions(SortType.amountLow);
                    Navigator.pop(context);
                  },
                ),

                _buildSortOption(
                  label: "Category (A → Z)",
                  onTap: () {
                    walletController.sortTransactions(SortType.categoryAZ);
                    Navigator.pop(context);
                  },
                ),

                _buildSortOption(
                  label: "Category (Z → A)",
                  onTap: () {
                    walletController.sortTransactions(SortType.categoryZA);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildSortOption({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final walletController = Provider.of<WalletController>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top AppBar Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Budget',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  // 🔹 App Logo as Profile Circle
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 16),

            // 💰 Total Balance Container
            Consumer<WalletController>(
              builder: (context, controller, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance:',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '₱${currencyFormat.format(controller.wallet.totalBalance)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              '${controller.percentIncrease.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: controller.percentIncrease >= 0 ? Colors.red : Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             SizedBox(width: 4),
                             Text(
                              'Since last month',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 📜 History Header
            // 📜 History Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 🔽 SORT DROPDOWN BUTTON
                      TextButton.icon(
                        onPressed: () {
                          _showSortMenu(context);
                        },
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                        label: const Text(
                          'Sort',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  // ➕ ADD + ❌ DELETE on the right
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _showAddTransactionDialog(context, walletController);
                        },
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          if (_selectedItems.isEmpty) return;

                          final controller =
                          Provider.of<WalletController>(context, listen: false);

                          final sorted = _selectedItems.toList()
                            ..sort((a, b) => b.compareTo(a));

                          for (var i in sorted) {
                            controller.deleteTransaction(i);
                          }

                          setState(() => _selectedItems.clear());
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            // 🧾 Scrollable Transaction List (Live updates)
            Expanded(
              child: Consumer<WalletController>(
                builder: (context, controller, child) {
                  final transactions = controller.transactions;

                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  return AnimatedList(
                    key: controller.listKey,
                    initialItemCount: transactions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index, animation) {
                      final tx = transactions[index];
                      final dateText = DateFormat('MMM d, yyyy').format(tx.date);

                      // same category color logic you already have
                      IconData categoryIcon;
                      Color categoryColor;
                      switch (tx.category.toLowerCase()) {
                        case 'food':
                          categoryIcon = Icons.fastfood;
                          categoryColor = Colors.orangeAccent;
                          break;
                        case 'shopping':
                          categoryIcon = Icons.shopping_bag;
                          categoryColor = Colors.purpleAccent;
                          break;
                        case 'bills':
                          categoryIcon = Icons.receipt_long;
                          categoryColor = Colors.indigo;
                          break;
                        case 'work':
                          categoryIcon = Icons.work;
                          categoryColor = Colors.teal;
                          break;
                        case 'subscription':
                          categoryIcon = Icons.subscriptions;
                          categoryColor = Colors.amber;
                          break;
                        case 'commute':
                          categoryIcon = Icons.directions_bus;
                          categoryColor = Colors.lightBlueAccent;
                          break;
                        default:
                          categoryIcon = Icons.category;
                          categoryColor = Colors.grey;
                      }

                      // wrap your card in animation
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selectedItems.contains(index)) {
                                  _selectedItems.remove(index);
                                } else {
                                  _selectedItems.add(index);
                                }
                              });
                            },
                            child: Card(
                              color: _selectedItems.contains(index)
                                  ? Colors.greenAccent.withOpacity(0.95)
                                  : Colors.white,
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: _selectedItems.contains(index) ? 4 : 2,
                              child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: tx.type == 'income' ? Colors.green[100] : Colors.red[100],
                                  child: Icon(
                                    Icons.attach_money,
                                    color: tx.type == 'income' ? Colors.green[700] : Colors.red[700],
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(categoryIcon, size: 16, color: categoryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            tx.category,
                                            style: TextStyle(
                                              color: categoryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateText,
                                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  (tx.type == 'income' ? '+₱' : '-₱') + currencyFormat.format(tx.amount),
                                  style: TextStyle(
                                    color: tx.type == 'income' ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                           ),
                          ),
                      );
                    },
                  );
                },
              ),
            ),


          ],
        ),
      ),

      // 🔻 Bottom Navigation Bar
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
