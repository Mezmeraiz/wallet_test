import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_test/common/utils.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/feature/bitcoin_transaction_screen.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class CoinDetailScreen extends StatelessWidget {
  final TWCoinType coinType;

  const CoinDetailScreen({super.key, required this.coinType});

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
              if (coinType == TWCoinType.TWCoinTypeBitcoin) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _openBitcoinScreen(context),
                  child: const Text('Send'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openBitcoinScreen(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BitcoinTransactionScreen(),
        ),
      );
}
