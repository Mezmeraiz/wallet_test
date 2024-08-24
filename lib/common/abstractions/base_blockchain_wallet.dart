import 'package:meta/meta.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

abstract interface class IBlockchainWallet {
  String getAddress(TWCoinType coinType);

  Future<String> sendTransaction({
    required String toAddress,
    required String amount,
  });

  Future<double> getBalance();
}

abstract base class BaseBlockchainWallet implements IBlockchainWallet {
  final WalletRepository _walletRepository;

  const BaseBlockchainWallet({
    required WalletRepository walletRepository,
  }) : _walletRepository = walletRepository;

  @override
  @nonVirtual
  String getAddress(TWCoinType coinType) => _walletRepository.walletGetAddressForCoin(coinType);

  @override
  Future<double> getBalance();

  @override
  Future<String> sendTransaction({
    required String toAddress,
    required String amount,
  });
}
