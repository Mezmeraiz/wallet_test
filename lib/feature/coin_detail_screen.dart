import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/di/dependency_scope.dart';

class CoinDetailScreen extends StatelessWidget {
  final TWCoinType coinType;

  const CoinDetailScreen({super.key, required this.coinType});

  @override
  Widget build(BuildContext context) {
    final address = DependencyScope.of(context).walletRepository.walletGetAddressForCoin(coinType);
    return Scaffold(
      appBar: AppBar(
        title: Text(coinType.name),
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
            ],
          ),
        ),
      ),
    );
  }
}
