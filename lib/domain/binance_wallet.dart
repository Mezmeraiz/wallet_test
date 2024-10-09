import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http/intercepted_http.dart';
import 'package:wallet_test/common/abstractions/base_blockchain_wallet.dart';
import 'package:wallet_test/common/utils/coin_utils.dart';
import 'package:wallet_test/common/utils/utils.dart';
import 'package:wallet_test/data/model/coin.dart';
import 'package:wallet_test/data/model/coin_type.dart';
import 'package:wallet_test/data/model/result.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';
import 'package:wallet_test/protobuf/Ethereum.pb.dart' as ethereum;
import 'package:web3dart/crypto.dart';

const String _testUrl = 'https://rpc.ankr.com/bsc';
//const String _testUrl = 'https://rpc.ankr.com/bsc_testnet_chapel';

final class BinanceWallet extends BaseBlockchainWallet {
  final InterceptedHttp _http;
  final WalletRepository _walletRepository;

  BinanceWallet({
    required InterceptedHttp http,
    required super.walletRepository,
  })  : _http = http,
        _walletRepository = walletRepository;

  @override
  Future<double> getBalance({
    required Coin coin,
  }) =>
      switch (coin.type) {
        CoinType.coin => _getCoinBalance(coin),
        CoinType.token => _getTokenBalance(coin),
      };

  Future<double> _getCoinBalance(
    Coin coin,
  ) async {
    final addressEth = getAddress(CoinUtils.getCoinTypeFromBlockchain(coin.blockchain));

    final payload = {
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [addressEth, 'latest'],
      // TODO: get response ID
      'id': 1,
    };

    try {
      final response = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = Result.fromJson(jsonDecode(response.body)).result;

        final balance = BigInt.parse(result.substring(2), radix: 16);

        final balanceEth = balance / BigInt.from(10).pow(coin.decimals);

        return balanceEth;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<double> _getTokenBalance(Coin coin) async {
    final coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);
    final contractAddress = coin.contractAddress;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    final Uint8List list = keccakUtf8('balanceOf(address)');
    final hexString = hex.encode(list);
    final methodHex = hexString.substring(0, 8);
    final data = '0x${methodHex}000000000000000000000000${coinAddress.substring(2)}';

    final param = {
      'to': contractAddress, // Адрес контракта USDT
      'data': data,
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
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      var responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        var result = Result.fromJson(jsonDecode(response.body)).result;

        // Убираем "0x" из начала строки
        result = result.replaceFirst('0x', '');

        result = result.isEmpty ? '0' : result;

        // Преобразуем hex-значение в десятичное
        BigInt balance = BigInt.parse(result, radix: 16);

        final tokenBalance = balance / BigInt.from(10).pow(coin.decimals);

        return tokenBalance;
      } else {
        throw Exception('Failed to load balance ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _sendTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    // Переводим значение в минимальную единицу (обычно Wei)
    final amountInWei = Utils.valueToMinUnit(double.parse(amount), coin.decimals);

    // Получаем адрес и приватный ключ для BSC
    final addressBsc = getAddress(TWCoinType.TWCoinTypeSmartChain);
    final privateKeyBsc = _walletRepository.getKeyForCoin(TWCoinType.TWCoinTypeSmartChain).toList();

    try {
      // Получение nonce
      final nonceResponse = await _http.post(
        Uri.parse(_testUrl),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionCount',
          'params': [addressBsc, 'latest'],
          'id': 1,
        }),
      );

      if (nonceResponse.statusCode == 200) {
        final nonceResult = Result.fromJson(jsonDecode(nonceResponse.body)).result;
        final nonce = _bigIntToUint8List(BigInt.parse(nonceResult.substring(2), radix: 16));

        // Получение текущей цены газа
        final gasPriceResponse = await _http.post(
          Uri.parse(_testUrl),
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
          final gasLimit = _intToUint8List(21000);

          // Формирование транзакции
          final transaction = ethereum.Transaction(
            transfer: ethereum.Transaction_Transfer(
              amount: _bigIntToUint8List(amountInWei),
            ),
          );

          // Указываем chainId для Binance Smart Chain (Mainnet: 56, Testnet: 97)
          final chainId = _bigIntToUint8List(BigInt.from(97)); // TestNet BSC

          // Подписываем транзакцию
          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: toAddress,
            transaction: transaction,
            privateKey: privateKeyBsc,
            nonce: nonce,
          );

          // Указываем тип монеты для BSC
          TWCoinType coin = TWCoinType.TWCoinTypeSmartChain;
          final sign = _walletRepository.sign(signedTransaction.writeToBuffer(), coin);
          final signingOutput = ethereum.SigningOutput.fromBuffer(sign);
          final rawTx = Utils.bytesToHex(signingOutput.encoded);

          // Отправка сырой транзакции в сеть
          return _sendRawTransaction(rawTx, true);
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

  Future<String> _sendTokenTransaction(
    Coin coin,
    String toAddress,
    String amount,
  ) async {
    final amountInMinUnits = BigInt.from(double.parse(amount) * BigInt.from(10).pow(coin.decimals).toInt());
    final coinType = CoinUtils.getCoinTypeFromBlockchain(coin.blockchain);
    final contractAddress = coin.contractAddress;
    final coinAddress = _walletRepository.walletGetAddressForCoin(coinType);

    final privateKeyEth = _walletRepository.getKeyForCoin(coinType).toList();

    try {
      // Receive nonce
      final nonceResponse = await _http.post(
        Uri.parse(_testUrl),
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
          Uri.parse(_testUrl),
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
          var gasPriceBigInt = BigInt.parse(gasPriceResult);
          final gasPrice = _bigIntToUint8List(gasPriceBigInt);

          // Получаем keccak хэш для метода `transfer(address,uint256)`
          final Uint8List list = keccakUtf8('transfer(address,uint256)');
          final hexString = hex.encode(list);
          final methodHex = hexString.substring(0, 8); // Первые 4 байта сигнатуры

          // Формируем данные транзакции (вызов метода `transfer`)
          final data = '0x$methodHex'
              '000000000000000000000000${toAddress.substring(2)}' // Адрес получателя
              '${amountInMinUnits.toRadixString(16).padLeft(64, '0')}'; // Сумма перевода

          final fromAddress = getAddress(coinType);

          final estimatedGasResponse = await _http.post(
            Uri.parse(_testUrl),
            headers: {
              HttpHeaders.contentTypeHeader: ContentType.json.toString(),
            },
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_estimateGas',
              'params': [
                {
                  'from': fromAddress,
                  'to': contractAddress,
                  'value': '0x0',
                  'data': data,
                },
              ],
              'id': 1,
            }),
          );

          if (estimatedGasResponse.statusCode != 200) {
            throw Exception('Failed to send transaction ${estimatedGasResponse.reasonPhrase}');
          }

          var f = jsonDecode(estimatedGasResponse.body);

          final estimatedGas = Result.fromJson(jsonDecode(estimatedGasResponse.body)).result;

          final gasLimit = _bigIntToUint8List(BigInt.parse(estimatedGas));

          final erc20Transfer = ethereum.Transaction_ERC20Transfer(
            to: toAddress,
            amount: _bigIntToUint8List(amountInMinUnits), // Закодированное количество токенов
          );

          final transaction = ethereum.Transaction(
            erc20Transfer: erc20Transfer, // Указываем поле erc20Transfer
          );

          final chainId = _bigIntToUint8List(BigInt.from(56)); // MainNet

          final signedTransaction = ethereum.SigningInput(
            chainId: chainId,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            toAddress: contractAddress,
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

  Future<String> _sendRawTransaction(String rawTx, [bool test = false]) async {
    final response = await _http.post(
      Uri.parse(test ? _testUrl : _testUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_sendRawTransaction',
        'params': ['0x$rawTx'],
        'id': 1,
      }),
    );

    var f = jsonDecode(response.body);

    return Result.fromJson(jsonDecode(response.body)).result;
  }

  @override
  Future<void> getTransactions() async {
    final addressEth = getAddress(CoinUtils.getCoinTypeFromBlockchain('Ethereum'));

    const String url =
        'https://rpc.ankr.com/multichain/21fd90cf03434b65e8c3d165e00193674368c97f925167da8502b59cac084a74';

    final payload = {
      'jsonrpc': '2.0',
      'method': 'ankr_getTransactionsByAddress',
      'params': {'address': addressEth, 'fromBlock': '0x0', 'toBlock': 'latest', 'sort': 'desc'},
      'id': 1,
    };

    final payloadToken = {
      'jsonrpc': '2.0',
      'method': 'ankr_getTokenTransfers',
      'params': {'address': addressEth, 'fromBlock': '0x0', 'toBlock': 'latest', 'sort': 'desc'},
      'id': 1,
    };

    try {
      // Отправляем POST запрос на Ankr API
      final response = await _http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payload),
      );

      final responseToken = await _http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.toString(),
        },
        body: jsonEncode(payloadToken),
      );

      if (response.statusCode == 200) {
        // Парсим результат ответа
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Transactions: ${responseData['result']}');
      } else {
        throw Exception('Failed to load transactions: ${response.reasonPhrase}');
      }

      if (responseToken.statusCode == 200) {
        // Парсим результат ответа
        final Map<String, dynamic> responseData = jsonDecode(responseToken.body);
        print('Transactions: ${responseData['result']}');
      } else {
        throw Exception('Failed to load transactions: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Future<String> sendTransaction({
    required Coin coin,
    required String toAddress,
    required String amount,
  }) =>
      switch (coin.type) {
        CoinType.coin => _sendTransaction(
            coin,
            toAddress,
            amount,
          ),
        CoinType.token => _sendTokenTransaction(
            coin,
            toAddress,
            amount,
          ),
      };

  @override
  Future<void> loadCoinInfo(List<Coin> coin) async {
    // TODO: implement loadCoinInfo
  }
}
