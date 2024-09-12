import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/send_transaction_screen.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class CoinDetailScreen extends StatelessWidget {
  final Coin coin;
  final TWCoinType coinType;

  CoinDetailScreen({super.key, required this.coin}) : coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);

  @override
  Widget build(BuildContext context) {
    final address = DependencyScope.of(context).walletRepository.walletGetAddressForCoin(coinType);

    return Scaffold(
      appBar: AppBar(
        title: Text(Utils.getCoinName(coinType)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder(
                future: DependencyScope.of(context).serviceFactory.getService(coin.blockchain).getBalance(coin: coin),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final balance = snapshot.data ?? '?';
                  return Text(
                    'Balance: $balance ${coin.name}',
                    style: const TextStyle(fontSize: 24),
                  );
                },
              ),
              const SizedBox(height: 32),
              QrImageView(
                data: address,
                size: 200,
              ),
              const SizedBox(height: 24),
              Text(
                address,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () => _openBitcoinScreen(context, coinType),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBitcoinScreen(BuildContext context, TWCoinType coinType) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendTransactionScreen(
            coin: coin,
          ),
        ),
      );
}
