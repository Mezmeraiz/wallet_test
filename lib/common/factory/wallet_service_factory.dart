import 'package:flutter/material.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/services/wallet_service.dart';
import 'package:wallet_test/di/dependency_scope.dart';
import 'package:wallet_test/domain/bitcoin_wallet.dart';
import 'package:wallet_test/domain/ethereum_wallet.dart';

abstract class WalletServiceFactory {
  static WalletService getService<T extends IBlockchainWallet>(BuildContext context) {
    final http = DependencyScope.of(context).http;
    final walletRepository = DependencyScope.of(context).walletRepository;

    final blockchainWallet = switch (T) {
      const (BitcoinWallet) => BitcoinWallet(
          http: http,
          walletRepository: walletRepository,
        ),
      const (EthereumWallet) => EthereumWallet(
          http: http,
          walletRepository: walletRepository,
        ),
      _ => throw Exception('Unknown wallet type'),
    };

    return WalletServiceImpl(blockchainWallet: blockchainWallet);
  }
}
