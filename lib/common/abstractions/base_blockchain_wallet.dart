import 'package:meta/meta.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

abstract interface class IBlockchainWallet {
  Future<void> loadCoinInfo(List<Coin> coin);

  Future<String> sendTransaction({
    required Coin coin,
    required String toAddress,
    required String amount,
  });

  Future<double> getBalance({
    required Coin coin,
  });

  Future<void> getTransactions();
}

abstract base class BaseBlockchainWallet implements IBlockchainWallet {
  final WalletRepository _walletRepository;

  const BaseBlockchainWallet({
    required WalletRepository walletRepository,
  }) : _walletRepository = walletRepository;

  String getAddress(TWCoinType coinType) => _walletRepository.walletGetAddressForCoin(coinType);
}
