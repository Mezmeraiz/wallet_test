import 'package:http_interceptor/http/http.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/domain/binance_wallet.dart';
import 'package:wallet_test/domain/bitcoin_wallet.dart';
import 'package:wallet_test/domain/ethereum_wallet.dart';
import 'package:wallet_test/domain/tron_wallet.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class WalletServiceFactory {
  final WalletRepository walletRepository;
  final InterceptedHttp http;

  WalletServiceFactory({
    required this.walletRepository,
    required this.http,
  });

  BitcoinWallet? _bitcoinWallet;

  EthereumWallet? _ethereumWallet;

  BinanceWallet? _binanceWallet;

  TronWallet? _tronWallet;

  BaseBlockchainWallet getService(String blockchain) => switch (CoinUtils.getCoinTypeFromBlockchain(blockchain)) {
        TWCoinType.TWCoinTypeBitcoin => _bitcoinWallet ??= BitcoinWallet(
            http: http,
            walletRepository: walletRepository,
          ),
        TWCoinType.TWCoinTypeEthereum => _ethereumWallet ??= EthereumWallet(
            http: http,
            walletRepository: walletRepository,
          ),
        TWCoinType.TWCoinTypeSmartChain => _binanceWallet ??= BinanceWallet(
            http: http,
            walletRepository: walletRepository,
          ),
        TWCoinType.TWCoinTypeTron => _tronWallet ??= TronWallet(
            http: http,
            walletRepository: walletRepository,
          ),
        _ => throw Exception('Unknown wallet type'),
      };
}
