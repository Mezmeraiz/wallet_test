// import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
//
// abstract interface class WalletService {
//   Future<double> getBalance();
//
//   Future<String> sendTransaction({
//     required String toAddress,
//     required String amount,
//   });
// }

// class WalletServiceImpl implements WalletService {
//   final IBlockchainWallet _blockchainWallet;
//
//   const WalletServiceImpl({
//     required IBlockchainWallet blockchainWallet,
//   }) : _blockchainWallet = blockchainWallet;
//
//   @override
//   Future<double> getBalance() => _blockchainWallet.getBalance();
//
//   @override
//   Future<String> sendTransaction({
//     required String toAddress,
//     required String amount,
//   }) =>
//       _blockchainWallet.sendTransaction(
//         toAddress: toAddress,
//         amount: amount,
//       );
// }
