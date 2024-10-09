import 'package:flutter/material.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/coin_list_screen.dart';
import 'package:wallet_test/feature/transaction_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  void _loadInfo() {
    var ethService = DependencyScope.of(context).serviceFactory.getService('Ethereum');
    ethService.loadCoinInfo([]);
  }

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CoinListScreen(),
    const TransactionListScreen(),
    const Center(child: Text('Profile Page', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _loadInfo,
                child: const Text('Test'),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.currency_bitcoin), label: 'Coins'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Transactions'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      );
}
