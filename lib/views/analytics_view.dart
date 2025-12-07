import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


import '../controllers/analytics_controller.dart';
import '../controllers/wallet_controller.dart';
import '../views/wallet_page.dart';
import '../views/budget_planner_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}
final NumberFormat pesoFormat = NumberFormat('#,##0.00', 'en_PH');

int touchedIndex = -1;

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsController controller = AnalyticsController();

  String selectedMode = "Month"; // Month or Year
  int _selectedIndex = 1;

  double getCleanInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    double maxY =
    spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Want around 5 horizontal lines always
    double rough = maxY / 5;

    // Nice, rounded intervals
    List<double> niceSteps = [
      10, 20, 50, 100,
      200, 500, 1000,
      2000, 5000, 10000,
      20000, 50000
    ];

    for (double n in niceSteps) {
      if (rough <= n) return n;
    }

    return rough; // fallback
  }

  String formatNumber(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    }
    return value.toInt().toString();
  }
  String valueText(double value) {
    if (selectedMode == "Year") {
      const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
      int idx = value.toInt();
      if (idx < 1 || idx > 12) return "";
      return months[idx - 1];
    }
    return value.toInt().toString();
  }

  final Map<String, Color> pieColors = {
    "Shopping": Colors.purple,
    "Food": Colors.orange,
    "Bills": Colors.blue,
    "Commute": Colors.lightBlue,
    "Subscription": Colors.yellow,
    "Work": Colors.teal,
    "Others": Colors.grey,
  };




  LineChartData monthChartData() {
    final spots = controller.getMonthlySpots();

    if (spots.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
      );
    }

    double interval = controller.calculateInterval(spots);

    String formatNumber(double value) {
      if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
      return value.toInt().toString();
    }

    return LineChartData(
      minX: spots.first.x,
      maxX: spots.last.x,
      minY: 0,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: interval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.6),
          strokeWidth: 0.7,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.3),
          strokeWidth: 0.5,
        ),
      ),

      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: selectedMode == "Month" ? 25 : 1,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  valueText(value),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),

        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: interval,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                formatNumber(value),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.32,
          barWidth: 3,
          color: Colors.orange.shade700,
          dotData: FlDotData(
            show: true,
            getDotPainter: (a, b, c, d) => FlDotCirclePainter(
              radius: 4,
              color: Colors.orange.shade700,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade400.withOpacity(0.35),
                Colors.orange.shade200.withOpacity(0.12),
                Colors.orange.shade100.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }


  LineChartData yearChartData() {
    final spots = controller.getYearlySpots();

    if (spots.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
      );
    }

    double interval = controller.calculateInterval(spots);

    const monthNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

    String formatNumber(double value) {
      if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
      return value.toInt().toString();
    }

    return LineChartData(
      minX: 1,
      maxX: 12,
      minY: 0,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: interval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.6),
          strokeWidth: 0.7,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.shade300.withOpacity(0.3),
          strokeWidth: 0.5,
        ),
      ),

      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int idx = value.toInt() - 1;
              if (idx < 0 || idx > 11) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthNames[idx],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),

        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: interval,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                formatNumber(value),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.32,
          barWidth: 3,
          color: Colors.orange.shade700,
          dotData: FlDotData(
            show: true,
            getDotPainter: (a, b, c, d) => FlDotCirclePainter(
              radius: 4,
              color: Colors.orange.shade700,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade400.withOpacity(0.35),
                Colors.orange.shade200.withOpacity(0.12),
                Colors.orange.shade100.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }



  @override
  void initState() {
    super.initState();

    /// WAIT for widget to mount before accessing Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final walletCtrl = context.read<WalletController>();

    // Load wallet balance from WalletController
    controller.setWallet(walletCtrl.walletBalance);

    // Load transactions for analytics
    controller.setTransactions(walletCtrl.transactions);

    setState(() {});
  }

  // --------------------------- NAV HANDLER ---------------------------

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WalletPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BudgetPlannerPage()),
      );
    } else if (index == 2) {
      // already here
    } else if (index == 3) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

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

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),

              _buildTotalSpentContainer(),
              const SizedBox(height: 12),

              _buildToggleBar(),
              const SizedBox(height: 12),

              _buildLineGraphSection(),
              const SizedBox(height: 12),

              _buildPieChartSection(),
              const SizedBox(height: 12),

              _buildWalletSection(),
              const SizedBox(height: 12),


            ],
          ),
        ),
      ),
    );
  }

  // --------------------------- UI SECTIONS ---------------------------

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WalletPage()),
              );
            },
            child: const Icon(Icons.arrow_back_ios_new, size: 28),
          ),

          const Text(
            "Total Spent Analysis",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Image.asset('assets/logo.png', height: 35),
        ],
      ),
    );
  }

  Widget _buildTotalSpentContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag, color: Colors.red.shade400, size: 38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Expense (This Month)",
                  style: TextStyle(fontSize: 14, color: Colors.red)),
              Text(
                '₱${pesoFormat.format(controller.thisMonthExpense)}',
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Row(
      children: [
        const SizedBox(width: 20),
        _toggleOption("Month"),
        const SizedBox(width: 10),
        _toggleOption("Year"),
      ],
    );
  }

  Widget _toggleOption(String label) {
    bool selected = selectedMode == label;

    return GestureDetector(
      onTap: () => setState(() => selectedMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.grey.shade700 : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLineGraphSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Last Month:", style: TextStyle(fontSize: 12)),
                  Text(
                    '₱${pesoFormat.format(controller.lastMonthExpense)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              ColoredBox(
                color: controller.percentIncrease >= 0
                    ? Colors.red
                    : Colors.green,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Text(
                    "${controller.percentIncrease.toStringAsFixed(2)}%",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("This Month:", style: TextStyle(fontSize: 12)),
                  Text(
                    '₱${pesoFormat.format(controller.thisMonthExpense)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              selectedMode == "Month"
                  ? monthChartData()
                  : yearChartData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    final categoryTotals = controller.getCategoryTotals();
    final topCategory = controller.getTopCategory();

    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text("No expenses to analyze"),
        ),
      );
    }

    // Compute total
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    // Resolve colors
    final Map<String, Color> resolvedColors = {};
    final Map<Color, int> usedCount = {};

    for (var entry in categoryTotals.entries) {
      final baseColor = pieColors[entry.key] ?? Colors.grey;

      if (!usedCount.containsKey(baseColor)) {
        usedCount[baseColor] = 0;
      } else {
        usedCount[baseColor] = usedCount[baseColor]! + 1;
      }

      final shadeFactor = usedCount[baseColor]!;
      resolvedColors[entry.key] =
          baseColor.withOpacity(1 - (shadeFactor * 0.15));
    }

    // Build sections
    final sections = categoryTotals.entries.map((e) {
      final percent = (e.value / total) * 100;
      final color = resolvedColors[e.key]!;

      return PieChartSectionData(
        color: color,
        value: e.value,
        radius: 65,
        title: "${percent.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        titlePositionPercentageOffset: 0.63,
      );
    }).toList();

    //------------------------------------
    // RESPONSIVE BREAKPOINT
    //------------------------------------
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 500; // Tablet mode
    final double chartSize = isWide
        ? 220                          // tablet size
        : screenWidth * 0.55;          // responsive phone size


    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 3),
          )
        ],
      ),

      child: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 📌 PIE CHART (tablets)
          SizedBox(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 45,
                sectionsSpace: 3,
                startDegreeOffset: 270,
                sections: sections,
              ),
            ),
          ),

          const SizedBox(width: 32),

          // 📌 LEGEND (tablets)
          Expanded(child: _buildPieLegend(categoryTotals, resolvedColors, topCategory)),
        ],
      )

      // ---------------------------
      // 📌 STACKED MODE (phones)
      // ---------------------------
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 45,
                  sectionsSpace: 3,
                  startDegreeOffset: 270,
                  sections: sections,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildPieLegend(categoryTotals, resolvedColors, topCategory),
        ],
      ),
    );
  }

//------------------------------------
// Separate LEGEND widget (cleaner)
//------------------------------------
  Widget _buildPieLegend(
      Map<String, double> totals,
      Map<String, Color> colors,
      String topCategory,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...totals.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors[e.key],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${e.key}  (₱${pesoFormat.format(e.value)})",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        const Text("Highest Category:", style: TextStyle(fontSize: 14)),
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            topCategory,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildWalletSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Wallet", style: TextStyle(fontSize: 18)),
            Text(
              "₱${pesoFormat.format(controller.walletAmount)}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
