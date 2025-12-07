import 'package:flutter/material.dart';
import 'package:mobprogproj/views/analytics_view.dart';
import 'package:mobprogproj/views/budget_planner_page.dart';
import 'package:provider/provider.dart';
import 'controllers/wallet_controller.dart';
import 'views/start_page.dart';
import 'views/wallet_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WalletController();
  await controller.loadData();

  runApp(
    ChangeNotifierProvider(
      create: (_) => controller,
      child: const BudgetBuddyApp(),
    ),
  );
}


class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Buddy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/wallet' : (context) => const WalletPage(),
        '/analytics' : (context) => const AnalyticsPage(),
        '/budget' : (context) => const BudgetPlannerPage(),
      },
    );
  }
}
