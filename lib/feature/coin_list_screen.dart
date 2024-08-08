import 'package:flutter/material.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/feature/coin_detail_screen.dart';

class CoinListScreen extends StatelessWidget {
  const CoinListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Currencies'),
      ),
      body: ListView.builder(
        itemCount: TWCoinType.values.length,
        itemBuilder: (context, index) {
          final coinType = TWCoinType.values[index];
          return ListTile(
            title: Text(coinType.name),
            subtitle: Text('ID: ${coinType.name}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoinDetailScreen(coinType: coinType),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
