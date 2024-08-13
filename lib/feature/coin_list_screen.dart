import 'package:flutter/material.dart';
import 'package:wallet_test/common/utils.dart';
import 'package:wallet_test/feature/coin_detail_screen.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class CoinListScreen extends StatelessWidget {
  const CoinListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Crypto Currencies'),
        ),
        body: ListView.builder(
          itemCount: TWCoinType.values.length,
          itemBuilder: (context, index) {
            final coinType = TWCoinType.values[index];
            return ListTile(
              title: Text(Utils.getCoinName(coinType)),
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
