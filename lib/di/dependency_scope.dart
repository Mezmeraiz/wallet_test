import 'package:flutter/material.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:wallet_test/common/factory/wallet_service_factory.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/domain/bitcoin_wallet.dart';
import 'package:wallet_test/domain/ethereum_wallet.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required super.child,
    required this.libraryStorage,
    required this.walletRepository,
    required this.core,
    required this.http,
    required this.serviceFactory,
  });

  final LibraryStorage libraryStorage;
  final WalletRepository walletRepository;
  final TrustWalletCore core;
  final InterceptedHttp http;
  final WalletServiceFactory serviceFactory;

  // BitcoinWallet? _bitcoinWallet;
  //
  // EthereumWallet? _ethereumWallet;
  //
  // BitcoinWallet get bitcoinWallet => _bitcoinWallet ??= BitcoinWallet(
  //       http: http,
  //       walletRepository: walletRepository,
  //     );
  //
  // EthereumWallet get ethereumWallet => _ethereumWallet ??= EthereumWallet(
  //       http: http,
  //       walletRepository: walletRepository,
  //     );
  //
  // IBlockchainWallet getService(Coin coin) {
  //   final blockchainWallet = switch (CoinUtils.getCoinTypeFromBlockchain(coin.blockchain)) {
  //     TWCoinType.TWCoinTypeBitcoin => BitcoinWallet(
  //       http: http,
  //       walletRepository: walletRepository,
  //     ),
  //     TWCoinType.TWCoinTypeEthereum => EthereumWallet(
  //       http: http,
  //       walletRepository: walletRepository,
  //     ),
  //     _ => throw Exception('Unknown wallet type'),
  //   };
  //
  //   return blockchainWallet;
  // }

  static DependencyScope of(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<DependencyScope>()!.widget as DependencyScope;

  @override
  bool updateShouldNotify(DependencyScope oldWidget) => false;
}
