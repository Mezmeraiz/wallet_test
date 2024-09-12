// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:wallet_test/data/model/coin.dart';
// import 'package:wallet_test/di/dependency_scope.dart';
// import 'package:wallet_test/ffi_impl/generated_bindings.dart';
//
// class TokenDetailScreen extends StatelessWidget {
//   final Coin coin;
//
//   const TokenDetailScreen({super.key, required this.coin});
//
//   @override
//   Widget build(BuildContext context) {
//     // final address =
//     //     DependencyScope.of(context).walletRepository.walletGetAddressForCoin(_getCoinTypeFromMapKey(tokenInfo.key));
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(coin.name),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             FutureBuilder(
//               future: DependencyScope.of(context).coinService.getBalance(coin),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const CircularProgressIndicator();
//                 }
//
//                 final balance = snapshot.data ?? '?';
//                 return Text(
//                   'Balance: $balance ETH',
//                   style: const TextStyle(fontSize: 24),
//                 );
//               },
//             ),
//             // const SizedBox(height: 32),
//             // QrImageView(
//             //   data: address,
//             //   size: 200,
//             // ),
//             // const SizedBox(height: 24),
//             // Text(
//             //   address,
//             //   style: const TextStyle(fontSize: 24),
//             //   textAlign: TextAlign.center,
//             // ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               //onPressed: () => _openBittokenScreen(context, tokenType),
//               child: const Text('Send'),
//             ),
//           ]),
//         ),
//       ),
//     );
//   }
//
//   // void _openBittokenScreen(BuildContext context, TWTokenType tokenType) => Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => BittokenTransactionScreen(
//   //           tokenType: tokenType,
//   //         ),
//   //       ),
//   //     );
// }
