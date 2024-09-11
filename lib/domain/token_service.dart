import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/utils.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Ethereum.pb.dart' as ethereum;
import 'package:web3dart/crypto.dart';

// const String _url = 'https://rpc.ankr.com/eth';
const String _url = 'https://rpc.ankr.com/eth_holesky';

class TokenService {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  TokenService({
    required InterceptedHttp http,
    required WalletRepository walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  Future<double> getTokenBalance(MapEntry<String, String> tokenInfo) async {
    final coinType = _getCoinTypeFromMapKey(tokenInfo.key);
    final tokenAddress = tokenInfo.value;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    final Uint8List list = keccakUtf8('balanceOf(address)');
    final hexString = hex.encode(list);
    final methodHex = hexString.substring(0, 8);
    final data = '0x${methodHex}000000000000000000000000${coinAddress.substring(2)}';

    final param = {
      "to": tokenAddress, // Адрес контракта USDT
      "data": data,
    };

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        param,
        'latest',
      ],
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
        var result = Result.fromJson(jsonDecode(response.body)).result;

        // Убираем "0x" из начала строки
        result = result.replaceFirst('0x', '');

        // Преобразуем hex-значение в десятичное
        BigInt balance = BigInt.parse(result, radix: 16);

        // Так как USDT использует 6 десятичных знаков, делим баланс на 10^6
        final usdtBalance = balance / BigInt.from(10).pow(6);

        return usdtBalance;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendTransaction({
    required MapEntry<String, String> tokenInfo,
    required String toAddress,
    required BigInt amount,
  }) async {
    final coinType = _getCoinTypeFromMapKey(tokenInfo.key);
    final tokenAddress = tokenInfo.value;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    //final addressEth = getAddress(TWCoinType.TWCoinTypeEthereum);
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
          'params': [coinAddress, 'latest'],
          // TODO: get response ID
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;

        final nonce = _bigIntToUint8List(BigInt.parse(nonceResult.substring(2), radix: 16));

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
          final gasPrice = _bigIntToUint8List(BigInt.parse(gasPriceResult));
          final gasLimit = _intToUint8List(60000);

          final erc20Transfer = ethereum.Transaction_ERC20Transfer(
            to: toAddress,
            amount: _bigIntToUint8List(amount), // Закодированное количество токенов
          );

          final transaction = ethereum.Transaction(
            erc20Transfer: erc20Transfer, // Указываем поле erc20Transfer
          );

          final chainId = _bigIntToUint8List(BigInt.parse('0x4268'));

          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: tokenAddress,
            transaction: transaction,
            privateKey: privateKeyEth,
            nonce: nonce,
          );

          TWCoinType coin = TWCoinType.TWCoinTypeEthereum;
          final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
          final signingOutput = ethereum.SigningOutput.fromBuffer(sign);
          final rawTx = Utils.bytesToHex(signingOutput.encoded);

          return _sendRawTransaction(rawTx);
        } else {
          throw Exception('Failed to send transaction ${gasPriceResponse.reasonPhrase}');
        }
      } else {
        throw Exception('Failed to send transaction ${nonceResponse.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _sendRawTransaction(String rawTx) async {
    final response = await _http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_sendRawTransaction',
        'params': ['0x$rawTx'],
        'id': 1,
      }),
    );

    return Result.fromJson(jsonDecode(response.body)).result;
  }

  TWCoinType _getCoinTypeFromMapKey(String key) {
    // Маппинг между именами ключей и значениями TWCoinType
    final Map<String, TWCoinType> keyToEnumValue = {
      'Ethereum': TWCoinType.TWCoinTypeEthereum,
      'BNB Smart Chain (BEP20)': TWCoinType.TWCoinTypeSmartChain,
      'Solana': TWCoinType.TWCoinTypeSolana,
      'Algorand': TWCoinType.TWCoinTypeAlgorand,
      'Polygon': TWCoinType.TWCoinTypePolygon,
      'Avalanche C-Chain': TWCoinType.TWCoinTypeAvalancheCChain,
      'Tron20': TWCoinType.TWCoinTypeTron,
      'Harmony': TWCoinType.TWCoinTypeHarmony,
      'Zilliqa': TWCoinType.TWCoinTypeZilliqa,
      'Moonbeam': TWCoinType.TWCoinTypeMoonbeam,
      'Arbitrum': TWCoinType.TWCoinTypeArbitrum,
      'Fantom': TWCoinType.TWCoinTypeFantom,
      'Optimism': TWCoinType.TWCoinTypeOptimism,
      'Polygon zkEVM': TWCoinType.TWCoinTypePolygonzkEVM,
      'Cronos': TWCoinType.TWCoinTypeCronosChain,
      'Aurora': TWCoinType.TWCoinTypeAurora,
      'Tezos': TWCoinType.TWCoinTypeTezos,
      'Waves': TWCoinType.TWCoinTypeWaves,
      'IoTeX': TWCoinType.TWCoinTypeIoTeX,
      'Near': TWCoinType.TWCoinTypeNEAR,
      'Secret': TWCoinType.TWCoinTypeSecret,
      'Syscoin': TWCoinType.TWCoinTypeSyscoin,
      'Celo': TWCoinType.TWCoinTypeCelo,
      'Neon EVM': TWCoinType.TWCoinTypeNeon,
    };

    // Возвращаем соответствующий enum, если ключ найден
    return keyToEnumValue[key]!;
  }

  Uint8List _bigIntToUint8List(BigInt bigInt) {
    int byteLength = (bigInt.bitLength + 7) >> 3;
    final bytes = Uint8List(byteLength);

    BigInt mask = BigInt.from(0xff);

    for (int i = 0; i < byteLength; i++) {
      // Приведение BigInt к int перед присвоением в массив Uint8List
      bytes[byteLength - i - 1] = (bigInt & mask).toInt();
      bigInt = bigInt >> 8;
    }

    return bytes;
  }

  Uint8List _intToUint8List(int value) {
    // Определяем количество байт, необходимых для представления int
    int byteLength = (value.bitLength + 7) >> 3;

    // Создаем Uint8List с нужной длиной
    final bytes = Uint8List(byteLength);

    // Заполняем массив байтами из числа
    for (int i = 0; i < byteLength; i++) {
      bytes[byteLength - i - 1] = (value >> (8 * i)) & 0xff;
    }

    return bytes;
  }
}
