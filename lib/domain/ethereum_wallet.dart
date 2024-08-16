import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Ethereum.pb.dart' as ethereum;
import 'package:fixnum/fixnum.dart' as fixnum;

// const String _url = 'https://rpc.ankr.com/eth';
const String _url = 'https://rpc.ankr.com/eth_holesky';

/// Minimum gas limit for a simple transaction
const _gasLimit = 21000;

final class EthereumWallet extends BaseBlockchainWallet {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  EthereumWallet({
    required InterceptedHttp http,
    required super.walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  @override
  Future<double> getBalance() async {
    final addressEth = getAddress(TWCoinType.TWCoinTypeEthereum);

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [addressEth, 'latest'],
      // TODO: get response ID
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = Result.fromJson(jsonDecode(response.body)).result;

        final balanceWei = BigInt.parse(result.substring(2), radix: 16);

        // In Ethereum, the smallest unit of the currency is called wei.
        // One ether (ETH) is equal to ten to the power of eighteen wei.
        // Therefore, to convert a balance from wei to ether, you need to divide it by ten to the power of eighteen.
        final balanceEth = balanceWei / BigInt.from(10).pow(18);

        return balanceEth;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> sendTransaction({required String toAddress, required String amount}) async {
    final addressEth = getAddress(TWCoinType.TWCoinTypeEthereum);
    final privateKeyEth = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeEthereum).toList();

    try {
      // Receive nonce
      final nonceResponse = await _http.post(
        Uri.parse(_url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [addressEth, 'latest'],
          // TODO: get response ID
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;

        // Allows to overwrite your own pending transactions that use the same nonce.
        final nonce = BigInt.parse(nonceResult.substring(2), radix: 16);
        print(nonce);

        // Returns the current price per gas in wei.
        final gasPriceResponse = await _http.post(
          Uri.parse(_url),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
          },
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'eth_gasPrice',
            'params': [],
            'id': 1,
          }),
        );

        if (gasPriceResponse.statusCode == 200) {
          final gasPriceResult = Result.fromJson(jsonDecode(gasPriceResponse.body)).result;
          final gasPrice = BigInt.parse(gasPriceResult.substring(2), radix: 16);

          final double amountDouble = double.parse(amount);

          // Минимальный gas limit для простой транзакции
          // 1 ETH in Wei
          final amountInWei = BigInt.from(amountDouble * 1e18);

          final transaction = ethereum.Transaction(
            transfer: ethereum.Transaction_Transfer(
              amount: [amountInWei.toInt()],
            ),
          );

          final signedTransaction = ethereum.SigningInput(
            chainId: [
              TWEthereumChainID.TWEthereumChainIDEthereum.value,
            ],
            gasPrice: [
              gasPrice.toInt(),
            ],
            gasLimit: [_gasLimit],
            toAddress: toAddress,
            transaction: transaction,
          );

          // // Создание и подписывание транзакции
          // final transaction = EthereumTransaction(
          //   nonce: nonce,
          //   gasPrice: gasPrice,
          //   gasLimit: BigInt.from(gasLimit),
          //   to: toAddress,
          //   value: amountInWei,
          //   data: [],
          // );

          // // Подписывание транзакции приватным ключом
          // final signedTransaction = Signer.signTransaction(transaction, ethPrivateKey, ChainId.mainnet);

          // // Отправка подписанной транзакции через JSON-RPC
          final sendTransactionResponse = await _http.post(
            Uri.parse(_url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_sendRawTransaction',
              'params': ['0x${signedTransaction.toString()}'],
              'id': 1,
            }),
          );

          final txHash = jsonDecode(sendTransactionResponse.body)["result"];
          if (kDebugMode) {
            print('Transaction hash: $txHash');
          }
        } else {
          throw Exception('Failed to send transaction ${gasPriceResponse.reasonPhrase}');
        }
      } else {
        throw Exception('Failed to send transaction ${nonceResponse.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }

    // logger.d("mnemonic: ${widget.wallet.mnemonic()}");
    // logger.d("address: ${widget.wallet.getAddressForCoin(TWCoinType.TWCoinTypeEthereum)}");
    // final publicKey = widget.wallet.getKeyForCoin(TWCoinType.TWCoinTypeEthereum).getPublicKeySecp256k1(false);
    // AnyAddress anyAddress = AnyAddress.createWithPublicKey(publicKey, TWCoinType.TWCoinTypeEthereum);
    // logger.d("address from any address: ${anyAddress.description()}");
    // print(widget.wallet.mnemonic());
    // String privateKeyhex = hex.encode(widget.wallet.getKeyForCoin(TWCoinType.TWCoinTypeEthereum).data());
    // logger.d("privateKeyhex: $privateKeyhex");
    // logger.d("seed = ${hex.encode(widget.wallet.seed())}");
    // final keystore = StoredKey.importPrivateKey(widget.wallet.getKeyForCoin(TWCoinType.TWCoinTypeEthereum).data(), "name", "password", TWCoinType.TWCoinTypeEthereum);
    // logger.d("keystore: ${keystore?.exportJson()}");

    return '';
  }
}
